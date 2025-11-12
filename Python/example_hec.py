# example_hec.py
"""
Example usage of the Hand-Eye Calibration functions from the Robot Client Interface.
"""

import time
import logging

# High-level GRI client facade and pose helper
import gri_client as client
import gri_actions as actions
from gri_comms import RobotPose  # For creating pose objects

PIPELINE_ID = 0

# Setup logger for this example
logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def log_action_summary(name: str, report: client.ActionReport) -> None:
    """Helper to log a concise summary of an action result."""

    if report.response:
        logger.info(
            "%s -> error_code=%s (%s), node_return=%s, data2=%s, data3=%s",
            name,
            report.response.error_code,
            actions.describe_error(report.response.error_code),
            report.response.node_return_code,
            report.response.data_fields[1],
            report.response.data_fields[2],
        )
    else:
        logger.error("%s -> %s", name, report.error or "No response received")


def perform_example_hand_eye_calibration(pipeline_id: int = PIPELINE_ID):
    """Demonstrates the hand-eye calibration sequence using the interface."""
    logger.info(
        f"--- Starting Hand-Eye Calibration Demo for pipeline {pipeline_id} ---"
    )

    status_result = client.get_status(debug=True)
    log_action_summary("STATUS", status_result)

    hec_init_result = client.hec_init(pipeline_id, debug=True)
    log_action_summary("HEC_INIT", hec_init_result)
    if not hec_init_result.acknowledged:
        logger.error("HEC Init failed. Aborting calibration demo.")
        return False  # Indicate failure

    # Simulate moving to poses and setting them
    # In a real robot, these poses would be acquired from the robot controller's
    # current flange pose when a calibration grid is visible.
    calib_poses = [
        # Example poses (mm, quaternion) - Replace with actual robot poses
        RobotPose(x=100, y=0, z=300, q1=0, q2=0, q3=0, q4=1),
        RobotPose(
            x=150, y=50, z=310, q1=0.1, q2=0, q3=0, q4=0.9949
        ),  # Approx 11.5 deg rot Y
        RobotPose(
            x=100, y=100, z=300, q1=0, q2=0.1, q3=0, q4=0.9949
        ),  # Approx 11.5 deg rot X
        RobotPose(
            x=50, y=50, z=290, q1=0, q2=0, q3=0.1, q4=0.9949
        ),  # Approx 11.5 deg rot Z
        RobotPose(x=120, y=20, z=320, q1=-0.1, q2=0, q3=0, q4=0.9949),
        RobotPose(x=120, y=80, z=280, q1=0, q2=-0.1, q3=0, q4=0.9949),
        RobotPose(x=80, y=20, z=310, q1=0, q2=0, q3=-0.1, q4=0.9949),
        RobotPose(
            x=80, y=80, z=305, q1=0.071, q2=0.071, q3=0.071, q4=0.992
        ),  # Combined rotation
    ]  # Exactly eight distinct poses recommended by Roboception

    logger.info("GRI HEC sequence: INIT -> 8x SET_POSE -> CALIBRATE")
    for slot_id, pose in enumerate(calib_poses, start=1):
        logger.info(
            "Simulating move and setting HEC pose for slot %s: %s", slot_id, pose
        )
        time.sleep(0.5)  # Placeholder for robot movement/settling
        set_result = client.hec_set_pose(pipeline_id, slot_id, pose, debug=True)
        log_action_summary(f"HEC_SET_POSE slot {slot_id}", set_result)
        if not set_result.acknowledged:
            logger.error(
                "HEC Set Pose for slot %s failed. Aborting calibration.", slot_id
            )
            return False  # Indicate failure
        time.sleep(0.2)  # Small delay between setting poses

    # Trigger the calibration calculation
    hec_calibrate_result = client.hec_calibrate(pipeline_id, debug=True)
    log_action_summary("HEC_CALIBRATE", hec_calibrate_result)
    if not hec_calibrate_result.acknowledged:
        logger.error("HEC Calibrate command failed.")
        return False

    logger.info(
        "HEC Calibrate command acknowledged successfully. Check server for results."
    )
    logger.info("--- Hand-Eye Calibration Demo Finished ---")
    return True  # Return whether calibration was successfully initiated


def main():
    """Main example demonstrating the hand-eye calibration sequence."""
    logger.info("--- Hand-Eye Calibration Example Program Starting ---")

    # Attempt to connect to the server using details from gri_config.py
    if not client.connect():
        logger.error(
            "Failed to connect to the server. Please check configuration and server status. Exiting."
        )
        return

    # --- Run the HEC Demo ---
    calibration_successful = perform_example_hand_eye_calibration(
        pipeline_id=PIPELINE_ID
    )
    if calibration_successful:
        logger.info("HEC process initiated.")
        # Note: This script only initiates calibration. Result checking is done on the server side.
    else:
        logger.warning("HEC process failed or could not be initiated.")

    # Disconnect from the server at the end of operations
    logger.info("--- HEC Example Program Finished. Disconnecting. ---")
    client.disconnect()


if __name__ == "__main__":
    # Graceful exit on Ctrl+C
    try:
        main()
    except KeyboardInterrupt:
        logger.info(
            "HEC example program interrupted by user. Ensuring disconnection..."
        )
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
