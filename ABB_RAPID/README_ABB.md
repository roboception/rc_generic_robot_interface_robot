# ABB RAPID Implementation for Generic Robot Interface

This is the ABB RAPID implementation of Roboception's Generic Robot Interface. It provides a simple way to integrate Roboception's vision modules with ABB robots using standard TCP socket communication.

## Quick Start

1. Copy the RcGenericRobotInterface folder to your robot
2. Configure the server IP and port in `RcConfig.modx`
3. Load all modules into your RobotStudio project
4. Use the provided functions in your RAPID program

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

### Important Notes

- Define `VAR robtarget output_point;` before using position functions
- Always call `socket_connect;` before first use
- Call `socket_disconnect;` when finished
- Use error handling for robust operation

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

## Module Structure

- `RcConfig`: Server configuration (IP, port)
- `RcInterfaceFunctions`: Main function implementations
- `RcSocketCommunication`: TCP socket handling
- `RcProtocolDefs`: Protocol constants and error codes
- `RcDebug`: Debug utilities

For detailed protocol specifications or advanced usage, please refer to the main documentation.