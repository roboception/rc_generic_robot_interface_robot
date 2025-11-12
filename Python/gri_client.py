"""
gri_client.py
~~~~~~~~~~~~~

High-level facade wrapping the low-level communication helpers in
`gri_comms`.  This module exposes small dataclasses with rich metadata
so application code can access poses, remaining counts, and verbose error
information without manually inspecting protocol responses.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

import gri_actions as actions
import gri_protocol as protocol
import gri_comms as comms


@dataclass
class ActionReport:
    """Common metadata returned by helper functions."""

    response: Optional[protocol.ResponseMessage]
    error: Optional[str] = None

    @property
    def success(self) -> bool:
        return (
            self.response is not None
            and self.response.error_code == actions.ErrorCode.NO_ERROR
        )

    @property
    def error_code(self) -> Optional[int]:
        return None if self.response is None else self.response.error_code


@dataclass
class StatusResult(ActionReport):
    ready: bool = False


@dataclass
class SyncJobResult(ActionReport):
    pose: Optional[comms.RobotPose] = None
    remaining_primary: Optional[int] = None
    remaining_related: Optional[int] = None


@dataclass
class AsyncTriggerResult(ActionReport):
    acknowledged: bool = False


@dataclass
class JobStatusResult(ActionReport):
    status: int = actions.JobStatus.UNKNOWN

    @property
    def status_label(self) -> str:
        return actions.describe_status(self.status)


@dataclass
class PoseRetrievalResult(ActionReport):
    pose: Optional[comms.RobotPose] = None
    remaining_primary: Optional[int] = None
    remaining_related: Optional[int] = None

    @property
    def exhausted(self) -> bool:
        """Return True if no pose was retrieved and the server reported exhaustion."""

        return (
            self.response is not None
            and self.response.error_code == actions.ErrorCode.NO_POSES_FOUND
        )


@dataclass
class RelatedPoseResult(ActionReport):
    pose: Optional[comms.RobotPose] = None
    remaining_related: Optional[int] = None

    @property
    def exhausted(self) -> bool:
        return (
            self.response is not None
            and self.response.error_code == actions.ErrorCode.NO_RELATED_POSES
        )


@dataclass
class HECResult(ActionReport):
    acknowledged: bool = False


def connect() -> bool:
    """Establish the TCP connection via the low-level communications module."""

    return comms.socket_connect()


def disconnect() -> None:
    """Close the TCP connection."""

    comms.socket_disconnect()


def get_status(debug: bool = False) -> StatusResult:
    """Query system readiness (STATUS action)."""

    ready, response = comms.get_system_status(debug=debug)
    error = _error_from_response(response)
    return StatusResult(
        response=response, error=error, ready=ready if response else False
    )


def trigger_job_sync(
    job_id: int, pose: Optional[comms.RobotPose] = None, debug: bool = False
) -> SyncJobResult:
    """Trigger a job synchronously and retrieve the first pose."""

    success, pose_result, rem_primary, rem_related, response = comms.trigger_job_sync(
        job_id,
        current_pos_override=pose,
        debug=debug,
    )
    error = _error_from_response(response)
    return SyncJobResult(
        response=response,
        error=error,
        pose=pose_result,
        remaining_primary=rem_primary,
        remaining_related=rem_related,
    )


def trigger_job_async(
    job_id: int, pose: Optional[comms.RobotPose] = None, debug: bool = False
) -> AsyncTriggerResult:
    """Trigger a job asynchronously (fire-and-forget)."""

    success, response = comms.trigger_job_async(
        job_id,
        current_pos_override=pose,
        debug=debug,
    )
    error = _error_from_response(response)
    return AsyncTriggerResult(
        response=response,
        error=error,
        acknowledged=success,
    )


def get_job_status(job_id: int, debug: bool = False) -> JobStatusResult:
    """Retrieve the status of an asynchronous job."""

    status_code, response = comms.get_job_status(job_id, debug=debug)
    error = (
        _error_from_response(response)
        if response and response.error_code != actions.ErrorCode.NO_ERROR
        else None
    )
    return JobStatusResult(
        response=response,
        error=error,
        status=status_code,
    )


def wait_for_job(
    job_id: int, delay_s: float = 1.0, timeout_s: float = 10.0, debug: bool = False
) -> bool:
    """Block until a job finishes or fails."""

    return comms.wait_for_job(job_id, delay_s=delay_s, timeout_s=timeout_s, debug=debug)


def get_next_pose(job_id: int, debug: bool = False) -> PoseRetrievalResult:
    """Fetch the next primary pose from the result queue."""

    success, pose, rem_primary, rem_related, response = comms.get_next_pose(
        job_id, debug=debug
    )
    error = _error_from_response(response) if not success else None
    return PoseRetrievalResult(
        response=response,
        error=error,
        pose=pose,
        remaining_primary=rem_primary,
        remaining_related=rem_related,
    )


def get_related_pose(job_id: int, debug: bool = False) -> RelatedPoseResult:
    """Fetch a related pose for the current primary result."""

    success, pose, rem_related, response = comms.get_related_pose(job_id, debug=debug)
    error = _error_from_response(response) if not success else None
    return RelatedPoseResult(
        response=response,
        error=error,
        pose=pose,
        remaining_related=rem_related,
    )


def hec_init(pipeline_id: int, debug: bool = False) -> HECResult:
    """Initialize the hand-eye calibration pipeline."""

    success, response = comms.hec_init(pipeline_id, debug=debug)
    error = _error_from_response(response)
    return HECResult(response=response, error=error, acknowledged=success)


def hec_set_pose(
    pipeline_id: int, slot_id: int, pose: comms.RobotPose, debug: bool = False
) -> HECResult:
    """Send a calibration pose."""

    success, response = comms.hec_set_pose(pipeline_id, slot_id, pose, debug=debug)
    error = _error_from_response(response)
    return HECResult(response=response, error=error, acknowledged=success)


def hec_calibrate(pipeline_id: int, debug: bool = False) -> HECResult:
    """Execute the calibration calculation."""

    success, response = comms.hec_calibrate(pipeline_id, debug=debug)
    error = _error_from_response(response)
    return HECResult(response=response, error=error, acknowledged=success)


def _error_from_response(response: Optional[protocol.ResponseMessage]) -> Optional[str]:
    """Derive a human-readable error string from a response."""

    if response is None:
        return "No response received"
    if response.error_code == actions.ErrorCode.NO_ERROR:
        return None
    return actions.describe_error(response.error_code)
