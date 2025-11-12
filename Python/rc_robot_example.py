# rc_robot_example.py
"""
Example usage of the Robot Client Interface functions.
This script demonstrates how a generic robot controller program might use the interface.
"""

import logging

# High-level GRI client facade and pose helper
import gri_client as client
import gri_actions as actions
from gri_comms import RobotPose  # Reuse pose structure for overrides

# Setup logger for this example
logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def log_action_summary(name: str, report: client.ActionReport) -> None:
    """
    Helper to print a concise summary of an action report, including error codes
    and the first two data fields (matching remaining counts for pose retrieval).
    """
    if report.response:
        error_desc = actions.describe_error(report.response.error_code)
        data2 = report.response.data_fields[1]
        data3 = report.response.data_fields[2]
        logger.info(
            "%s -> error_code=%s (%s), node_return=%s, data2=%s, data3=%s",
            name,
            report.response.error_code,
            error_desc,
            report.response.node_return_code,
            data2,
            data3,
        )
    else:
        logger.error("%s -> %s", name, report.error or "No response received")


def main():
    """Main example demonstrating the high-level GRI helper functions."""
    logger.info("--- Generic Robot Client Example Program Starting ---")

    if not client.connect():
        logger.error(
            "Failed to connect to the server. Please check configuration and server status. Exiting."
        )
        return

    job_id_sync = 0
    job_id_async = 1
    try:
        logger.info("\n1. Checking overall system STATUS...")
        status_result = client.get_status(debug=True)
        log_action_summary("STATUS", status_result)
        logger.info("  -> Ready flag: %s", status_result.ready)

        logger.info(
            "\n2. Triggering synchronous vision job (job_id=%s)...", job_id_sync
        )
        sync_pose = RobotPose(x=500, y=100, z=400, q1=0, q2=0, q3=0, q4=1)
        sync_result = client.trigger_job_sync(job_id_sync, pose=sync_pose, debug=True)
        log_action_summary("TRIGGER_JOB_SYNC", sync_result)
        if sync_result.pose:
            logger.info("  -> Primary pose: %s", sync_result.pose)
            logger.info(
                "  -> Remaining primary=%s, related=%s",
                sync_result.remaining_primary,
                sync_result.remaining_related,
            )

        logger.info(
            "\n3. Attempting to retrieve a related pose for the synchronous job..."
        )
        related_sync_result = client.get_related_pose(job_id_sync, debug=True)
        log_action_summary("GET_RELATED_POSE (sync)", related_sync_result)
        if related_sync_result.pose:
            logger.info("  -> Related pose: %s", related_sync_result.pose)

        logger.info("\n4. Fetching additional poses for the synchronous job...")
        for attempt in range(3):
            next_result = client.get_next_pose(job_id_sync, debug=True)
            log_action_summary(f"GET_NEXT_POSE (sync #{attempt + 1})", next_result)
            if not next_result.response:
                break
            if next_result.success and next_result.pose:
                logger.info("  -> Retrieved Pose: %s", next_result.pose)
                logger.info(
                    "     Remaining primary=%s, related=%s",
                    next_result.remaining_primary,
                    next_result.remaining_related,
                )
                if next_result.remaining_related and next_result.remaining_related > 0:
                    follow_up_related = client.get_related_pose(job_id_sync, debug=True)
                    log_action_summary(
                        "GET_RELATED_POSE (sync follow-up)", follow_up_related
                    )
                    if follow_up_related.pose:
                        logger.info("     -> Related pose: %s", follow_up_related.pose)
                if (
                    next_result.remaining_primary is not None
                    and next_result.remaining_primary <= 0
                ):
                    break
            elif next_result.exhausted:
                logger.info(
                    "  -> No more primary poses reported for job %s.", job_id_sync
                )
                break
            else:
                logger.info("  -> Stopping additional pose retrieval for sync job.")
                break

        logger.info(
            "\n5. Triggering asynchronous vision job (job_id=%s)...", job_id_async
        )
        async_pose = RobotPose(x=550, y=150, z=410, q1=0, q2=0.707, q3=0, q4=0.707)
        async_trigger = client.trigger_job_async(
            job_id_async, pose=async_pose, debug=True
        )
        log_action_summary("TRIGGER_JOB_ASYNC", async_trigger)

        logger.info("\n6. Polling job status once before waiting...")
        status_result_async = client.get_job_status(job_id_async, debug=True)
        log_action_summary("GET_JOB_STATUS (pre-wait)", status_result_async)
        logger.info("  -> Status label: %s", status_result_async.status_label)

        logger.info("\n7. Waiting for asynchronous job to complete...")
        job_completed = client.wait_for_job(
            job_id_async, delay_s=0.5, timeout_s=10.0, debug=False
        )
        logger.info("  -> wait_for_job result: %s", job_completed)

        logger.info("\n8. Retrieving poses produced by the asynchronous job...")
        for attempt in range(5):
            next_result_async = client.get_next_pose(job_id_async, debug=True)
            log_action_summary(
                f"GET_NEXT_POSE (async #{attempt + 1})", next_result_async
            )
            if not next_result_async.response:
                break
            if next_result_async.success and next_result_async.pose:
                logger.info("  -> Async Pose: %s", next_result_async.pose)
                logger.info(
                    "     Remaining primary=%s, related=%s",
                    next_result_async.remaining_primary,
                    next_result_async.remaining_related,
                )
                related_async = client.get_related_pose(job_id_async, debug=True)
                log_action_summary("GET_RELATED_POSE (async)", related_async)
                if related_async.pose:
                    logger.info("     -> Related pose: %s", related_async.pose)
                if (
                    next_result_async.remaining_primary is not None
                    and next_result_async.remaining_primary <= 0
                ):
                    break
            elif next_result_async.exhausted:
                logger.info(
                    "  -> No more primary poses reported for job %s.", job_id_async
                )
                break
            else:
                logger.info("  -> Stopping additional pose retrieval for async job.")
                break

    finally:
        logger.info("\n--- Example Program Finished. Disconnecting. ---")
        client.disconnect()


if __name__ == "__main__":
    # Graceful exit on Ctrl+C
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Example program interrupted by user. Ensuring disconnection...")
        # Attempt disconnect even if already disconnected or failed to connect
        try:
            client.disconnect()
        except Exception as e_disconnect:
            logger.error(f"Error during disconnect on interrupt: {e_disconnect}")
    except Exception as e:
        logger.exception(f"An unexpected error occurred in main: {e}")  # Log traceback
        # Attempt disconnect even if already disconnected or failed to connect
        try:
            client.disconnect()
        except Exception as e_disconnect:
            logger.error(f"Error during disconnect on exception: {e_disconnect}")
