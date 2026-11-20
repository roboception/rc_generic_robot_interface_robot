# ABB RAPID Implementation for Generic Robot Interface

This is the ABB RAPID implementation of Roboception's Generic Robot Interface. It provides a simple way to integrate Roboception's vision modules with ABB robots using standard TCP socket communication.

## Quick Start

1. Copy the RcGenericRobotInterface folder to your robot
2. Configure the server IP and port in `RcConfig.modx` to match your Roboception sensor's settings
3. Load all modules into your RobotStudio project
4. Use the provided functions in your RAPID program


## Enabling PC Interface for Socket Communication

To use socket communication in ABB RAPID on an IRC5 controller, the PC Interface option must be enabled.

On OmniCore controllers (RobotWare 7), socket messaging is included in RobotWare Base; no additional option is needed and the steps below can be skipped. The implementation has been tested on IRC5 only so far.

**Steps (IRC5):**

1. In RobotStudio, open the **Controller** tab and right-click the **controller** (e.g. "Herbert") under Current Station
2. Select **Change Options**
3. Go to **Communication**
4. Activate **616-1 PC Interface**
5. Click **OK**

**Note:** After enabling PC Interface, you may need to perform an **I-Start** (Initialize) to activate the changes on your controller. This will reset the controller—ensure you have a backup of your programs first.


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

### Tests (Optional)
- `tests/GriEdgeCases.modx`: Edge-case tests against a running sensor (error codes, async failures, disconnects). Not part of the program file; see `tests/README.md`.

## Main Functions

All functions return `bool` indicating success/failure (except `get_job_status` which returns a status code) and have an optional `\debug` switch for additional logging.

### Core Functions

* `get_status(\VAR bool ready \debug)`
  - Checks the overall system status
  - Returns `TRUE` if the system is ready, `FALSE` otherwise
  - Optional `ready` parameter receives the readiness flag (TRUE = ready, FALSE = not ready)
  - Example: `IF get_status(\ready:=system_ready \debug:=FALSE) THEN ...`

* `trigger_job_sync(job_id, output_point \VAR num remaining_primary \VAR num remaining_related \VAR num node_return_code \num data1 \num data2 \num data3 \num data4 \debug)`
  - Triggers a job and waits for the first result
  - Returns the first target position immediately
  - Optional `remaining_primary` returns the number of remaining primary poses
  - Optional `remaining_related` returns the number of remaining related poses
  - Optional `node_return_code` returns the node return code from the server
  - Optional `data1`..`data4` are sent to the job as dynamic arguments (see below); the job's additional return values are available in `gri_last`
  - Example: `trigger_job_sync(1, target1 \remaining_primary:=remaining \remaining_related:=related \node_return_code:=ret_code \debug:=FALSE)`

* `trigger_job_async(job_id \num data1 \num data2 \num data3 \num data4 \debug)`
  - Starts a job without waiting for completion
  - Optional `data1`..`data4` are sent to the job as dynamic arguments (see below)
  - Example: `trigger_job_async(1 \debug:=FALSE)`

* `get_next_pose(job_id, output_point \VAR num remaining_primary \VAR num remaining_related \VAR num node_return_code \debug)`
  - Gets the next available target position
  - Optional `remaining_primary` returns the number of remaining primary poses
  - Optional `remaining_related` returns the number of remaining related poses
  - Optional `node_return_code` returns the node return code from the server
  - Example: `get_next_pose(1, target2 \remaining_primary:=remaining \remaining_related:=related \node_return_code:=ret_code \debug:=FALSE)`

* `get_related_pose(job_id, output_point \VAR num remaining_related \VAR num node_return_code \debug)`
  - Gets a related pose associated with the last retrieved primary pose
  - Optional `remaining_related` returns the number of remaining related poses
  - Optional `node_return_code` returns the node return code from the server
  - Example: `get_related_pose(1, related_target \remaining_related:=remaining \node_return_code:=ret_code \debug:=FALSE)`

* `get_job_status(job_id \VAR num error_code_out \VAR num node_return_code \debug)`
  - Checks current job status
  - Returns status code (DONE = 3, RUNNING = 2, FAILED = 4, etc.)
  - A failed async job (e.g. a bad dynamic argument) returns FAILED; the error code is in `gri_last.error_code`
  - Optional `error_code_out` receives the error code from the server
  - Optional `node_return_code` returns the node return code from the server
  - Example: `status := get_job_status(1 \error_code_out:=err_code \node_return_code:=ret_code \debug:=FALSE)`

* `wait_for_job(job_id \delay \timeout \debug)`
  - Waits for job completion
  - Returns `FALSE` at once if the job failed or any error occurred (reason in the event log and in `gri_last.error_code`)
  - Optional delay between checks (default 1000ms)
  - Optional timeout in ms; without it, waits until the job is done or has failed
  - Example: `wait_for_job(1 \delay:=1000 \timeout:=5000)`

### Working with Multiple Poses

The interface supports retrieving multiple poses from a single job. Each primary pose may have associated related poses:

- **Primary poses**: Main target positions returned by `trigger_job_sync` and `get_next_pose`
- **Related poses**: Additional poses associated with the last retrieved primary pose, retrieved using `get_related_pose`

The optional `remaining_primary` and `remaining_related` parameters allow you to track how many poses are still available:

```rapid
VAR num remaining_primary;
VAR num remaining_related;
VAR robtarget primary_pose;
VAR robtarget related_pose;

! Get first primary pose
IF trigger_job_sync(1, primary_pose \remaining_primary:=remaining_primary \remaining_related:=remaining_related) THEN
    ! Process primary pose...
    
    ! Get related pose if available
    IF remaining_related > 0 THEN
        IF get_related_pose(1, related_pose \remaining_related:=remaining_related) THEN
            ! Process related pose...
        ENDIF
    ENDIF
    
    ! Get additional primary poses
    WHILE remaining_primary > 0 DO
        IF get_next_pose(1, primary_pose \remaining_primary:=remaining_primary \remaining_related:=remaining_related) THEN
            ! Process primary pose...
            
            ! Get related pose if available
            IF remaining_related > 0 THEN
                IF get_related_pose(1, related_pose \remaining_related:=remaining_related) THEN
                    ! Process related pose...
                ENDIF
            ENDIF
        ELSE
            EXIT;
        ENDIF
    ENDWHILE
ENDIF
```

### Dynamic arguments and additional return

Requires rc_cube firmware 26.07 or newer.

A GRI job can take values from the robot (`dynamic_args`) and return extra values next to the pose (`additional_return`).

- **Dynamic arguments:** `trigger_job_sync` and `trigger_job_async` accept the optional `\data1`..`\data4`. They are sent as request fields `data_1`..`data_4` and are inserted into the job's service arguments as configured in `dynamic_args`.
- **Additional return:** After every request (`trigger_job_sync`, `trigger_job_async`, `get_next_pose`, `get_related_pose`, `get_status`, `get_job_status`, ...) the global variable `gri_last` (record `gri_result`) holds the last response:
  `error_code`, `node_return_code`, `remaining_primary`, `remaining_related` and `data4`..`data10` (the job's `additional_return` values, as configured by `target_field`). The async trigger response carries no additional return, `data6`..`data10` are 0 there.
  `gri_last` is cleared at the start of each request. If no valid response arrives (not connected, socket error or timeout), `gri_last.error_code` is `ERR_COMMUNICATION` (-100, client-side only) and all other fields are 0.
- **Conversion helpers:** float values are scaled by 1e6 on the wire, map values are plain integers from the job's `maps`.
  - `gri_float(value)`: float to GRI integer (use for `\data1`..`\data4`)
  - `gri_to_float(raw)`: GRI integer to float
  - `gri_to_bool(raw)`: GRI integer to bool (`raw <> 0`)
- **Warning 5 (MISSING_ADDITIONAL_DATA):** one mapped field was missing in the node response. The pose and the other fields are valid, so the functions return `TRUE` and write a warning to the event log.
  The missing field reads 0, which cannot be told apart from a real 0. Do not use 0 as a key in a job's `maps`.
- New error codes: -19 TYPE_CONVERSION_ERROR, -20 UNMAPPED_VALUE_ERROR, +5 MISSING_ADDITIONAL_DATA.
- **-19/-20 on a primary pose** (`trigger_job_sync`, `get_next_pose`): the server has already taken that pose from the queue. It is lost; the next call returns the next pose.
- **Async jobs:** a bad dynamic argument for `trigger_job_async` is only found when the job runs, so the trigger itself succeeds. The error arrives via `get_job_status` (returns FAILED) or `wait_for_job` (returns `FALSE`), in `gri_last.error_code`.
- **Precision:** a RAPID `num` holds integers exactly only up to +-8388608. Float values are therefore exact to 1e-6 up to +-8.38; larger integer values lose exactness.

Example (sync job with dynamic args, additional return for the primary and the related pose):

```rapid
! data_3 selects the frame via the job's "frames" map (1 = camera, 2 = external)
IF trigger_job_sync(2, target \remaining_primary:=remaining_primary \remaining_related:=remaining_related \data1:=gri_float(0.03) \data2:=gri_float(0.03) \data3:=2) THEN
    ErrWrite \I, "Info", "Quality=" + NumToStr(gri_to_float(gri_last.data4), 3);
    IF get_related_pose(2, related_target \remaining_related:=remaining_related) THEN
        ErrWrite \I, "Info", "Bounding box x=" + NumToStr(gri_to_float(gri_last.data7) * 1000, 1) + " mm";
    ENDIF
ELSE
    ErrWrite \W, "Error", "Job failed: " + get_error_string(gri_last.error_code);
ENDIF
```

Job 2 as used by `ExampleMainModule` (ItemPick AI, `compute_grasps`):

```json
{
  "name": "ABB test data fields (ItemPick AI)",
  "job_type": "CALL_PIPELINE_SERVICE", "pipeline": "0",
  "node": "rc_itempick", "service": "compute_grasps", "selected_return": "grasps",
  "args": {"pose_frame": "external", "item_models": [{"type": "BAG"}],
           "suction_surface_length": 0.02, "suction_surface_width": 0.02},
  "dynamic_args": [
    {"source_field": "data_1", "json_path": "suction_surface_length", "type": "float"},
    {"source_field": "data_2", "json_path": "suction_surface_width", "type": "float"},
    {"source_field": "data_3", "json_path": "pose_frame", "type": "map", "map": "frames"}
  ],
  "additional_return": {
    "primary": [
      {"json_path": "quality", "target_field": "data_4", "type": "float"},
      {"json_path": "type", "target_field": "data_5", "type": "map", "map": "grasp_types"},
      {"json_path": "timestamp.sec", "target_field": "data_6", "type": "int"}
    ],
    "related": [
      {"json_path": "bounding_box.x", "target_field": "data_7", "type": "float"},
      {"json_path": "bounding_box.y", "target_field": "data_8", "type": "float"},
      {"json_path": "bounding_box.z", "target_field": "data_9", "type": "float"},
      {"json_path": "type", "target_field": "data_10", "type": "map", "map": "item_types"}
    ]
  },
  "maps": {"frames": {"1": "camera", "2": "external"},
           "grasp_types": {"1": "SUCTION"}, "item_types": {"1": "BAG"}}
}
```

Note: `data_3` must always be sent for this job (0 is not in `frames` and gives -20). Details: https://doc.rc-cube.com/latest/en/gri.html

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

## Protocol Notes (Fixed by Server)

- Protocol: Version 1 (V1)
- Header: 8 bytes (`"GRI\0"`, version, length, pose_format, action)
- Lengths: request 54 bytes, response 80 bytes
- Job ID: uint16 (LE); Error code: int16 with sign semantics
- Pose format: QUAT_WXYZ (1) fixed; quaternions are packed W,X,Y,Z on the wire and mapped to `robtarget.rot.q1..q4` accordingly
- Scaling: All pose components are int32 scaled by 1e6
- Error codes: Signed int16 with sign semantics
  - Negative values (< 0): Errors (e.g., -1 = Unknown Error, -2 = Internal Error)
  - Zero (0): Success
  - Positive values (> 0): Warnings (e.g., 1 = No Poses Found, 2 = No Related Poses)

See `RcProtocolDefs.modx` and `RcSocketCommunication.modx` for exact packing/unpacking.

## Important Notes

- Define `VAR robtarget output_point;` before using position functions
- Always call `socket_connect;` before first use
- Call `socket_disconnect;` when finished

## Basic Example

```rapid
PROC main()
    VAR robtarget target1;
    VAR robtarget related_target;
    VAR num job_id := 1;
    VAR num remaining_primary;
    VAR num remaining_related;
    VAR num node_return_code;
    VAR bool system_ready;

    ! Connect to server
    socket_connect;

    ! Check system status
    IF get_status(\ready:=system_ready \debug:=FALSE) THEN
        IF system_ready THEN
            ErrWrite \I, "Status", "System is ready";
        ELSE
            ErrWrite \W, "Status", "System not ready";
        ENDIF
    ENDIF

    ! Get first target with remaining counts
    IF trigger_job_sync(job_id, target1 \remaining_primary:=remaining_primary \remaining_related:=remaining_related \node_return_code:=node_return_code \debug:=FALSE) THEN
        print_robtarget "Target1", target1;
        ErrWrite \I, "Info", "Remaining primary: " + NumToStr(remaining_primary, 0) + ", related: " + NumToStr(remaining_related, 0);
        
        ! Try to get a related pose if available
        IF remaining_related > 0 THEN
            IF get_related_pose(job_id, related_target \remaining_related:=remaining_related \node_return_code:=node_return_code \debug:=FALSE) THEN
                print_robtarget "RelatedTarget", related_target;
            ENDIF
        ENDIF
    ELSE
        ErrWrite \W, "Error", "Failed to get target";
    ENDIF

    ! Clean up
    socket_disconnect;

ERROR
    socket_disconnect;
ENDPROC
```
