# ABB RAPID Implementation for Generic Robot Interface

This is the ABB RAPID implementation of Roboception's Generic Robot Interface. It provides a simple way to integrate Roboception's vision modules with ABB robots using standard TCP socket communication.

## Quick Start

1. Copy the RcGenericRobotInterface folder to your robot
2. Configure the server IP and port in `RcConfig.modx` to match your Roboception sensor's settings
3. Load all modules into your RobotStudio project
4. Use the provided functions in your RAPID program

## Module Structure

The implementation consists of two types of modules:

### Roboception Core Modules (Required)
- `RcConfig`: Server configuration (IP, port, timeout)
- `RcInterfaceFunctions`: Main function implementations
- `RcSocketCommunication`: TCP socket handling
- `RcProtocolDefs`: Protocol constants and error codes
- `RcDebug`: Debug utilities

### Example Modules (Optional)
- `ExampleMainModule`: Demonstrates basic usage of the interface
- `HandEyeCalibrationExample`: Shows how to perform hand-eye calibration

## Main Functions

All functions return `bool` indicating success/failure and have an optional `\debug` switch for additional logging.

### Core Functions

* `trigger_job_sync(job_id, output_point \debug)`
  - Triggers a job and waits for the first result
  - Returns the first target position immediately
  - Example: `trigger_job_sync(1, target1 \debug:=FALSE)`

* `trigger_job_async(job_id \debug)`
  - Starts a job without waiting for completion
  - Example: `trigger_job_async(1 \debug:=FALSE)`

* `get_next_pose(job_id, output_point \debug)`
  - Gets the next available target position
  - Example: `get_next_pose(1, target2 \debug:=FALSE)`

* `get_job_status(job_id \debug)`
  - Checks current job status
  - Returns status code (DONE = 3, RUNNING = 2, etc.)
  - Example: `status := get_job_status(1 \debug:=FALSE)`

* `wait_for_job(job_id \delay \timeout \debug)`
  - Waits for job completion
  - Optional delay between checks (default 1000ms)
  - Optional timeout
  - Example: `wait_for_job(1 \delay:=1000 \timeout:=5000)`

### Hand-Eye Calibration Functions

The hand-eye calibration determines the transformation between the robot's flange and the camera system. The interface provides three functions for this purpose:

* `hec_init(pipeline_id \debug)`
  - Initializes the calibration process
  - Example: `hec_init(1 \debug:=TRUE)`

* `hec_set_pose(pipeline_id, slot, pose \debug)`
  - Records a robot pose for calibration
  - Example: `hec_set_pose(1, 1, current_pose \debug:=TRUE)`

* `hec_calibrate(pipeline_id \debug)`
  - Computes the final calibration
  - Example: `hec_calibrate(1 \debug:=TRUE)`

#### Calibration Procedure

1. Define at least 8 distinct robot poses where the calibration pattern is fully visible to the camera
2. Initialize the calibration with `hec_init`
3. For each calibration pose:
   - Move the robot to the pose using fine positioning (`MoveJ pose, v50, fine, tool0`)
   - Allow the robot to settle (e.g., `WaitTime 1`)
   - Record the pose with `hec_set_pose`
4. Compute the final calibration with `hec_calibrate`

#### Calibration Best Practices

- Use poses with good distribution across the workspace
- Include different orientations at each pose
- Ensure the calibration pattern is fully visible in all poses
- Use fine positioning for accurate pose recording
- A minimum of 8 poses is recommended for reliable results
- The eight poses must be taught in a way that the calibration grid has eight distinct views in the camera
- For detailed guidance on optimal calibration poses, refer to the Roboception documentation: https://doc.rc-cube.com/latest/en/handeye_calibration.html#step-3-record-poses

See `HandEyeCalibrationExample.modx` for a complete implementation example.

## Important Notes

- Define `VAR robtarget output_point;` before using position functions
- Always call `socket_connect;` before first use
- Call `socket_disconnect;` when finished

## Basic Example

```rapid
PROC main()
    VAR robtarget target1;
    VAR num job_id := 1;

    ! Connect to server
    socket_connect;

    ! Get first target
    IF trigger_job_sync(job_id, target1) THEN
        ! Use target1 for movement
        print_robtarget "Target1", target1;
    ELSE
        ErrWrite \W, "Error", "Failed to get target";
    ENDIF

    ! Clean up
    socket_disconnect;

ERROR
    socket_disconnect;
ENDPROC
```
