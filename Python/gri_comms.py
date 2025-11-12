# gri_comms.py
"""
Handles TCP socket communication, binary protocol packing/unpacking,
and provides high-level interface functions for a generic robot client
to interact with a Roboception Generic Robot Interface (GRI) server.

This module implements the client-side logic based on the GRI V1 specification.
"""

import socket
import time
import logging
from typing import Optional, Sequence, Tuple

# Import connection configuration settings
import gri_config as cfg
import gri_actions as actions
import gri_protocol as protocol

# Setup logger for this module
logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class RobotPose(protocol.Pose):
    """
    Represents a robot pose using millimeters for position (x, y, z)
    and quaternion for rotation (q1, q2, q3, q4).
    """

    def __str__(self):
        """Provides a string representation of the pose."""
        return (
            f"Pose(x={self.x:.2f}, y={self.y:.2f}, z={self.z:.2f}, "
            f"q1={self.q1:.4f}, q2={self.q2:.4f}, q3={self.q3:.4f}, q4={self.q4:.4f})"
        )

    def normalize_quaternion(self):
        """Normalizes the quaternion components to unit length."""
        self.normalize()


def _copy_pose(pose: protocol.Pose) -> protocol.Pose:
    """Create a defensive copy of a pose to avoid in-place normalization side-effects."""

    return protocol.Pose(pose.x, pose.y, pose.z, pose.q1, pose.q2, pose.q3, pose.q4)


def _as_robot_pose(pose: protocol.Pose) -> RobotPose:
    """Convert a protocol pose into a RobotPose instance."""

    return RobotPose(pose.x, pose.y, pose.z, pose.q1, pose.q2, pose.q3, pose.q4)


# --- Global State ---
_client_socket: Optional[socket.socket] = None
_is_connected: bool = False

# --- Low-Level Socket Communication & Protocol Handling ---


def socket_connect() -> bool:
    """
    Establishes a TCP socket connection to the server defined in gri_config.

    Uses SERVER_IP, SERVER_PORT, and SERVER_TIMEOUT from the config.

    Returns:
        True if connection is successful, False otherwise.
    """
    global _client_socket, _is_connected
    if _is_connected:
        logger.info("Already connected.")
        return True

    logger.info(f"Attempting to connect to {cfg.SERVER_IP}:{cfg.SERVER_PORT}...")
    try:
        _client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # TCP Keepalive settings (optional, but good practice for robustness)
        _client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        if hasattr(socket, "TCP_KEEPIDLE"):  # Linux/macOS
            _client_socket.setsockopt(
                socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 5
            )  # Idle time
            _client_socket.setsockopt(
                socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 5
            )  # Interval
            _client_socket.setsockopt(
                socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 3
            )  # Probes
        # Note: Windows uses SIO_KEEPALIVE_VALS, which is more complex via ioctl

        _client_socket.settimeout(cfg.SERVER_TIMEOUT)
        _client_socket.connect((cfg.SERVER_IP, cfg.SERVER_PORT))
        _is_connected = True
        logger.info("Successfully connected to server.")
        return True
    except socket.timeout:
        logger.error("Connection timed out.")
        _client_socket = None
        _is_connected = False
        return False
    except socket.error as e:
        logger.error(f"Socket connection error: {e}")
        _client_socket = None
        _is_connected = False
        return False
    except Exception as e:
        logger.error(f"Unexpected error during connection: {e}")
        _client_socket = None
        _is_connected = False
        return False


def socket_disconnect():
    """Closes the active TCP socket connection."""
    global _client_socket, _is_connected
    if _is_connected and _client_socket:
        logger.info("Disconnecting from server...")
        try:
            _client_socket.shutdown(socket.SHUT_RDWR)
        except socket.error as e:
            logger.debug(
                f"Socket shutdown error (ignoring, might be already closed): {e}"
            )
        try:
            _client_socket.close()
        except socket.error as e:
            logger.warning(f"Error closing socket: {e}")
        finally:
            _client_socket = None
            _is_connected = False
            logger.info("Socket closed.")
    elif not _is_connected:
        logger.info("Already disconnected.")


def _send_action(
    action: actions.Action,
    job_id: int,
    pose: Optional[protocol.Pose] = None,
    data_fields: Sequence[int] = (0, 0, 0, 0),
    debug: bool = False,
) -> Optional[protocol.ResponseMessage]:
    """
    Pack, send, and decode a protocol action.

    Returns the parsed ResponseMessage or None if a communication or decoding
    error occurs.
    """

    if len(data_fields) != 4:
        raise ValueError("data_fields must contain exactly four integers.")

    pose_for_request = _copy_pose(pose) if pose else protocol.Pose()
    request = protocol.RequestMessage(
        action=action,
        job_id=job_id,
        pose=pose_for_request,
        data_fields=data_fields,
    )
    request_bytes = request.to_bytes()
    response_bytes, comm_error = socket_send_receive(request_bytes, debug=debug)

    if comm_error or not response_bytes:
        logger.error(
            "%s(job=%s): Communication failed: %s", action.name, job_id, comm_error
        )
        return None

    try:
        response = protocol.ResponseMessage.from_bytes(response_bytes)
    except ValueError as exc:
        logger.error(
            "%s(job=%s): Failed to decode response: %s", action.name, job_id, exc
        )
        return None

    return response


def socket_send_receive(
    request: bytes, debug: bool = False
) -> Tuple[Optional[bytes], Optional[str]]:
    """
    Sends a request and attempts to receive a complete response.

    Handles basic socket communication errors and timeouts. Validates
    the received response length against the internal RESPONSE_MESSAGE_LENGTH constant.

    Args:
        request: The packed binary request bytes (should be REQUEST_MESSAGE_LENGTH).
        debug: If True, logs the hex representation of sent/received bytes.

    Returns:
        A tuple containing:
            - bytes or None: The raw response bytes if successful and length is correct.
            - str or None: An error message string if an error occurred.
    """
    global _client_socket, _is_connected
    if not _is_connected or not _client_socket:
        err_msg = "Communication error: Not connected."
        logger.error(err_msg)
        return None, err_msg

    try:
        if len(request) != protocol.REQUEST_LENGTH:
            logger.warning(
                "Sending request with unexpected length: %s bytes. Expected %s.",
                len(request),
                protocol.REQUEST_LENGTH,
            )

        bytes_sent = _client_socket.sendall(request)
        if bytes_sent is not None:
            err_msg = (
                f"Communication error: Socket sendall failed (returned {bytes_sent})."
            )
            logger.error(err_msg)
            socket_disconnect()
            return None, err_msg

        if debug:
            logger.debug(f"Sent {len(request)} bytes: {request.hex()}")

        # Receive response - attempt to receive exactly the expected number of bytes
        response_bytes = b""
        bytes_to_receive = protocol.RESPONSE_LENGTH
        _client_socket.settimeout(cfg.SERVER_TIMEOUT)  # Ensure timeout is set for recv
        start_recv_time = time.monotonic()
        while len(response_bytes) < bytes_to_receive:
            # Check timeout manually for recv loop
            if time.monotonic() - start_recv_time > cfg.SERVER_TIMEOUT:
                raise socket.timeout("Receive loop timed out")

            remaining_bytes = bytes_to_receive - len(response_bytes)
            chunk = _client_socket.recv(remaining_bytes)
            if not chunk:
                err_msg = (
                    "Communication error: Connection closed by server during receive."
                )
                logger.error(err_msg)
                socket_disconnect()
                return None, err_msg
            response_bytes += chunk

        if debug:
            logger.debug(
                f"Received {len(response_bytes)} bytes: {response_bytes.hex()}"
            )

        # Length check (should be guaranteed by loop unless recv error)
        if len(response_bytes) != protocol.RESPONSE_LENGTH:
            # This case should ideally not be reached due to the loop structure
            err_msg = (
                f"Communication error: Received incomplete/wrong response length. "
                f"Got {len(response_bytes)}, expected {protocol.RESPONSE_LENGTH}."
            )
            logger.error(err_msg)
            return None, err_msg

        return response_bytes, None  # Success

    except socket.timeout:
        err_msg = "Communication error: Socket operation timed out."
        logger.error(err_msg)
        # Consider forcing disconnect on timeout
        # socket_disconnect()
        return None, err_msg
    except socket.error as e:
        err_msg = f"Communication error: Socket send/receive error: {e}."
        logger.error(err_msg)
        socket_disconnect()  # Assume connection is lost
        return None, err_msg
    except Exception as e:
        err_msg = f"Communication error: Unexpected error during send/receive: {e}."
        logger.error(err_msg)
        socket_disconnect()  # Assume connection is lost
        return None, err_msg


# --- High-Level Interface Functions ---


def get_current_robot_pose() -> RobotPose:
    """
    Placeholder for retrieving the robot's actual current pose.

    In a real controller integration, this function would query the robot's
    system for its current TCP coordinates and orientation (in mm and quaternion).
    For this generic Python example, it returns a hardcoded default pose.

    Returns:
        A RobotPose object representing the current pose.
    """
    logger.debug("Using placeholder for get_current_robot_pose()")
    # Returns identity quaternion
    return RobotPose(x=100.0, y=50.0, z=200.0, q1=0.0, q2=0.0, q3=0.0, q4=1.0)


def get_system_status(
    debug: bool = False,
) -> Tuple[bool, Optional[protocol.ResponseMessage]]:
    """
    Query the server for system readiness information (STATUS action).

    Returns:
        Tuple[bool, Optional[protocol.ResponseMessage]] where the boolean indicates
        whether the system reports readiness (data_2 == 1).
    """
    response = _send_action(actions.Action.STATUS, job_id=0, debug=debug)

    if response is None:
        return False, None

    ready_flag = bool(response.data_fields[1])

    if response.error_code == actions.ErrorCode.NO_ERROR:
        logger.info(
            "get_system_status(): Ready=%s (node_return_code=%s).",
            ready_flag,
            response.node_return_code,
        )
        return ready_flag, response

    logger.error(
        "get_system_status(): Server returned error: %s (Code: %s)",
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, response


def trigger_job_sync(
    job_id: int, current_pos_override: Optional[RobotPose] = None, debug: bool = False
) -> Tuple[
    bool,
    Optional[RobotPose],
    Optional[int],
    Optional[int],
    Optional[protocol.ResponseMessage],
]:
    """
    Triggers a vision job synchronously and waits for the result.

    Sends the robot's current pose (or an override) to the server. If successful,
    returns the first pose result and the counts of remaining primary (Data 1)
    and related (Data 2) results.

    Args:
        job_id: The identifier of the job to trigger.
        current_pos_override: If provided, this pose is sent instead of querying the robot.
        debug: Enable detailed logging for this call.

    Returns:
        A tuple (success_flag, output_pose_or_None, remaining_primary_or_None,
        remaining_related_or_None, response_or_None) where response_or_None is the
        parsed protocol response for further inspection.
    """
    pose = current_pos_override if current_pos_override else get_current_robot_pose()
    response = _send_action(
        actions.Action.TRIGGER_JOB_SYNC, job_id, pose=pose, debug=debug
    )

    if response is None:
        return False, None, None, None, None

    remaining_primary = response.remaining_primary
    remaining_related = response.remaining_related

    if response.error_code == actions.ErrorCode.NO_ERROR:
        result_pose = _as_robot_pose(response.pose)
        logger.info(
            "trigger_job_sync(job=%s): Success. Remaining Primary=%s, Related=%s",
            job_id,
            remaining_primary,
            remaining_related,
        )
        return True, result_pose, remaining_primary, remaining_related, response

    logger.error(
        "trigger_job_sync(job=%s): Server returned error: %s (Code: %s)",
        job_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, None, remaining_primary, remaining_related, response


def trigger_job_async(
    job_id: int, current_pos_override: Optional[RobotPose] = None, debug: bool = False
) -> Tuple[bool, Optional[protocol.ResponseMessage]]:
    """
    Triggers a vision job asynchronously.

    Sends the robot's current pose (or an override) and the job ID. Returns
    True if the server acknowledges the request without error, False otherwise.
    This function does not wait for the job to complete processing.

    Args:
        job_id: The identifier of the job to trigger.
        current_pos_override: If provided, this pose is sent instead of querying the robot.
        debug: Enable detailed logging for this call.

    Returns:
        Tuple[bool, Optional[protocol.ResponseMessage]]: Success flag and the parsed response.
    """
    current_pos = (
        current_pos_override if current_pos_override else get_current_robot_pose()
    )
    response = _send_action(
        actions.Action.TRIGGER_JOB_ASYNC, job_id, pose=current_pos, debug=debug
    )

    if response is None:
        return False, None

    if response.error_code == actions.ErrorCode.NO_ERROR:
        logger.info(
            "trigger_job_async(job=%s): Successfully acknowledged by server.", job_id
        )
        return True, response

    logger.error(
        "trigger_job_async(job=%s): Server returned error on ack: %s (Code: %s)",
        job_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, response


def get_job_status(
    job_id: int, debug: bool = False
) -> Tuple[int, Optional[protocol.ResponseMessage]]:
    """
    Queries the status of a previously triggered asynchronous job.

    Args:
        job_id: The identifier of the job to query.
        debug: Enable detailed logging for this call.

    Returns:
        Tuple[int, Optional[protocol.ResponseMessage]]: The job status code
        (e.g., RUNNING, DONE) and the parsed response object (or None on error).
    """
    response = _send_action(actions.Action.GET_JOB_STATUS, job_id, debug=debug)

    if response is None:
        return actions.JobStatus.UNKNOWN, None

    if response.error_code == actions.ErrorCode.NO_ERROR:
        status_code = response.data_fields[1]
        logger.info(
            "get_job_status(job=%s): Status %s (%s).",
            job_id,
            status_code,
            actions.describe_status(status_code),
        )
        return status_code, response

    logger.error(
        "get_job_status(job=%s): Server returned error: %s (Code: %s)",
        job_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return actions.JobStatus.UNKNOWN, response


def get_next_pose(
    job_id: int, debug: bool = False
) -> Tuple[
    bool,
    Optional[RobotPose],
    Optional[int],
    Optional[int],
    Optional[protocol.ResponseMessage],
]:
    """
    Retrieves the next available primary pose result from a completed asynchronous job.

    Args:
        job_id: The identifier of the job whose results are requested.
        debug: Enable detailed logging for this call.

    Returns:
        A tuple (success_flag, output_pose_or_None, remaining_primary_or_None,
        remaining_related_or_None, response_or_None) with the parsed response.
    """
    response = _send_action(actions.Action.GET_NEXT_POSE, job_id, debug=debug)

    if response is None:
        return False, None, None, None, None

    remaining_primary = response.remaining_primary
    remaining_related = response.remaining_related

    if response.error_code == actions.ErrorCode.NO_ERROR:
        pose = _as_robot_pose(response.pose)
        logger.info(
            "get_next_pose(job=%s): Success. Remaining Primary=%s, Related=%s.",
            job_id,
            remaining_primary,
            remaining_related,
        )
        return True, pose, remaining_primary, remaining_related, response

    if response.error_code == actions.ErrorCode.NO_POSES_FOUND:
        logger.info(
            "get_next_pose(job=%s): No more primary poses (NO_POSES_FOUND). Remaining Primary=%s, Related=%s.",
            job_id,
            remaining_primary,
            remaining_related,
        )
        return False, None, remaining_primary, remaining_related, response

    logger.error(
        "get_next_pose(job=%s): Server returned error: %s (Code: %s)",
        job_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, None, remaining_primary, remaining_related, response


def get_related_pose(
    job_id: int, debug: bool = False
) -> Tuple[
    bool, Optional[RobotPose], Optional[int], Optional[protocol.ResponseMessage]
]:
    """
    Retrieves an associated pose for the current primary object result (if applicable).

    Args:
        job_id: The identifier of the job context.
        debug: Enable detailed logging for this call.

    Returns:
        A tuple (success_flag, output_pose_or_None, remaining_related_or_None,
        response_or_None) including the parsed protocol response.
    """
    response = _send_action(actions.Action.GET_RELATED_POSE, job_id, debug=debug)

    if response is None:
        return False, None, None, None

    remaining_related = response.remaining_related

    if response.error_code == actions.ErrorCode.NO_ERROR:
        pose = _as_robot_pose(response.pose)
        logger.info(
            "get_related_pose(job=%s): Success. Remaining Related=%s.",
            job_id,
            remaining_related,
        )
        return True, pose, remaining_related, response

    if response.error_code == actions.ErrorCode.NO_RELATED_POSES:
        logger.info(
            "get_related_pose(job=%s): No related poses available (NO_RELATED_POSES). Remaining Related=%s.",
            job_id,
            remaining_related,
        )
        return False, None, remaining_related, response

    logger.error(
        "get_related_pose(job=%s): Server returned error: %s (Code: %s)",
        job_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, None, remaining_related, response


def wait_for_job(
    job_id: int, delay_s: float = 1.0, timeout_s: float = 10.0, debug: bool = False
) -> bool:
    """
    Waits for an asynchronous job to reach a terminal state (DONE or FAILED).

    Polls the job status using `get_job_status` at intervals defined by `delay_s`,
    until the status is DONE or FAILED, or until `timeout_s` is exceeded.

    Args:
        job_id: The identifier of the asynchronous job to wait for.
        delay_s: The time interval (in seconds) between status checks.
        timeout_s: The maximum time (in seconds) to wait before failing.
        debug: Enable detailed logging for status checks within the loop.

    Returns:
        bool: True if the job status becomes DONE within the timeout,
              False if the job status becomes FAILED/UNKNOWN or if the timeout is reached.
    """
    start_time = time.monotonic()
    logger.info(
        f"wait_for_job(job={job_id}): Waiting up to {timeout_s:.1f}s (polling every {delay_s:.1f}s)..."
    )

    while True:
        current_time = time.monotonic()
        elapsed_time = current_time - start_time

        if elapsed_time > timeout_s:
            logger.error(
                f"wait_for_job(job={job_id}): Timeout after {elapsed_time:.1f}s."
            )
            return False

        # Add a small delay *before* polling to avoid hammering the server immediately
        # Adjust wait_time calculation slightly.
        wait_time = min(
            delay_s, max(0, timeout_s - elapsed_time)
        )  # Ensure wait_time is non-negative
        if wait_time > 0:
            # Only sleep if not the very first check and there's time left
            if elapsed_time > 0:
                time.sleep(min(delay_s, wait_time))
            # Recalculate elapsed time after sleep
            elapsed_time = time.monotonic() - start_time
            if elapsed_time >= timeout_s:  # Check timeout again after sleep
                logger.error(
                    f"wait_for_job(job={job_id}): Timeout immediately after sleep ({elapsed_time:.1f}s)."
                )
                return False
        elif elapsed_time == 0:
            pass  # First check, don't sleep yet
        else:  # No time left to wait
            logger.error(
                f"wait_for_job(job={job_id}): Timeout condition met before next poll ({elapsed_time:.1f}s)."
            )
            return False

        status, _ = get_job_status(job_id, debug=debug)

        if status == actions.JobStatus.DONE:
            logger.info(
                f"wait_for_job(job={job_id}): Job completed successfully (Status: DONE)."
            )
            return True
        elif status == actions.JobStatus.FAILED:
            logger.error(f"wait_for_job(job={job_id}): Job failed (Status: FAILED).")
            return False
        elif status == actions.JobStatus.UNKNOWN:
            logger.error(
                f"wait_for_job(job={job_id}): Job status unknown (communication error?). Aborting wait."
            )
            return False
        elif status in [actions.JobStatus.INACTIVE, actions.JobStatus.RUNNING]:
            logger.debug(
                f"wait_for_job(job={job_id}): Status={status}. Elapsed={elapsed_time:.1f}s. Continuing wait..."
            )
        else:
            logger.warning(
                f"wait_for_job(job={job_id}): Received unexpected status code {status}. Continuing wait."
            )

        # Safety check in case sleep logic fails
        if time.monotonic() - start_time >= timeout_s:
            logger.error(
                f"wait_for_job(job={job_id}): Timeout detected at loop end ({time.monotonic() - start_time:.1f}s)."
            )
            return False


# --- Hand-Eye Calibration (HEC) Functions ---


def hec_init(
    pipeline_id: int, debug: bool = False
) -> Tuple[bool, Optional[protocol.ResponseMessage]]:
    """
    Initializes the hand-eye calibration process on the server.

    Args:
        pipeline_id: Identifier for the calibration pipeline (sent in data1).
        debug: Enable detailed logging for this call.

    Returns:
        Tuple[bool, Optional[protocol.ResponseMessage]] describing whether the call succeeded.
    """
    response = _send_action(
        actions.Action.HEC_INIT,
        job_id=0,
        data_fields=(pipeline_id, 0, 0, 0),
        debug=debug,
    )

    if response is None:
        return False, None

    if response.error_code == actions.ErrorCode.NO_ERROR:
        logger.info("hec_init(pipeline=%s): Initialization successful.", pipeline_id)
        return True, response

    logger.error(
        "hec_init(pipeline=%s): Server returned error: %s (Code: %s)",
        pipeline_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, response


def hec_set_pose(
    pipeline_id: int, slot_id: int, pose_to_set: RobotPose, debug: bool = False
) -> Tuple[bool, Optional[protocol.ResponseMessage]]:
    """
    Sends a robot pose to the server for use in hand-eye calibration.

    Args:
        pipeline_id: Identifier for the calibration pipeline (sent in data1).
        slot_id: The index (usually 1-based) for this calibration pose (sent in data2).
        pose_to_set: The RobotPose object representing the robot's pose.
        debug: Enable detailed logging for this call.

    Returns:
        Tuple[bool, Optional[protocol.ResponseMessage]] indicating success and parsed response.
    """
    response = _send_action(
        actions.Action.HEC_SET_POSE,
        job_id=0,
        pose=pose_to_set,
        data_fields=(pipeline_id, slot_id, 0, 0),
        debug=debug,
    )

    if response is None:
        return False, None

    if response.error_code == actions.ErrorCode.NO_ERROR:
        logger.info(
            "hec_set_pose(pipeline=%s, slot=%s): Pose set successfully.",
            pipeline_id,
            slot_id,
        )
        return True, response

    logger.error(
        "hec_set_pose(pipeline=%s, slot=%s): Server returned error: %s (Code: %s)",
        pipeline_id,
        slot_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, response


def hec_calibrate(
    pipeline_id: int, debug: bool = False
) -> Tuple[bool, Optional[protocol.ResponseMessage]]:
    """
    Commands the server to perform the hand-eye calibration calculation.

    Args:
        pipeline_id: Identifier for the calibration pipeline (sent in data1).
        debug: Enable detailed logging for this call.

    Returns:
        Tuple[bool, Optional[protocol.ResponseMessage]] indicating success acknowledgement.
    """
    response = _send_action(
        actions.Action.HEC_CALIBRATE,
        job_id=0,
        data_fields=(pipeline_id, 0, 0, 0),
        debug=debug,
    )

    if response is None:
        return False, None

    if response.error_code == actions.ErrorCode.NO_ERROR:
        logger.info(
            "hec_calibrate(pipeline=%s): Calibration command acknowledged.", pipeline_id
        )
        if any(
            abs(value) > 1e-9
            for value in (response.pose.x, response.pose.y, response.pose.z)
        ):
            logger.info(
                "  -> Calibration pose returned: %s", _as_robot_pose(response.pose)
            )
        return True, response

    logger.error(
        "hec_calibrate(pipeline=%s): Server returned error: %s (Code: %s)",
        pipeline_id,
        actions.describe_error(response.error_code),
        response.error_code,
    )
    return False, response
