# FANUC Robot Interface for Roboception Vision Systems

This document describes the FANUC client implementation for Roboception's Generic Robot Interface (GRI). The GRI enables FANUC robots to communicate with Roboception 3D vision systems through a simple, streamlined interface.

## Overview

The FANUC GRI client provides a straightforward way to integrate Roboception vision capabilities into your FANUC robot programs. Instead of complex register manipulation, you can access vision functions through simple CALL statements and status checks.

### Key Features

- **Vision Job Execution**: Trigger synchronous and asynchronous vision jobs
- **Pose Retrieval**: Get object poses directly into robot position registers
- **Related Poses**: Retrieve associated poses for the current primary object
- **Hand-Eye Calibration**: Perform camera-robot calibration procedures
- **Error Handling**: Consistent status reporting across all functions
- **Background Processing**: Non-blocking operation for complex workflows

### Interface Design

The interface uses familiar FANUC programming patterns:

```fanuc
! Trigger a vision job
CALL GRI_TRIGGER_JOB_SYNC(1) ;

! Check result status
IF R[150:gri obj status]=20,JMP LBL[object_found] ;
```

All communication complexity is handled internally, exposing only the essential functions needed for robot programming.

## Installation

### Required Files

Load the following files onto your FANUC robot controller:

**Compiled background module** (load .pc file):
- `gri_comm_background.pc` - Background communication handler (contains all protocol logic and routines)

**TP Programs** (load .ls files):
- `GRI_OPEN_COMMUNICATION.LS` - System initialization
- `GRI_TRIGGER_JOB_SYNC.LS` - Execute vision job (blocking)
- `GRI_TRIGGER_JOB_ASYNC.LS` - Execute vision job (non-blocking)
- `GRI_GET_JOB_STATUS.LS` - Check async job status
- `GRI_GET_NEXT_GRASP.LS` - Retrieve additional poses
- `GRI_GET_RELATED_GRASP.LS` - Retrieve related poses
- `GRI_HEC_INIT.LS` - Initialize hand-eye calibration
- `GRI_HEC_SET_POSE.LS` - Set calibration pose
- `GRI_HEC_CALIBRATE.LS` - Execute calibration
- `GRI_QUIT.LS` - System shutdown and log file generation

Optional example programs (load .ls files):
- `GRI_EXAMPLE_PICK_AND_PLACE.LS` - Example pick-and-place application
- `GRI_EXAMPLE_HEC.LS` - Example hand–eye calibration flow

### Build from Source (recommended)

- It is recommended to compile the background module from source on your own setup for maximum compatibility.
- Only the background KAREL program `gri_comm_background.kl` needs to be compiled. It `%INCLUDE`s the other `.kl` files during compilation, so you do not compile them separately.
- Steps (requires FANUC KAREL tools):
  1. Open a shell in `FANUC/karel/`.
  2. Run `setrobot` to generate/update `robot.ini` for your controller.
  3. Run `ktrans gri_comm_background.kl` to produce `gri_comm_background.pc`.
  4. Load the generated `gri_comm_background.pc` and the TP programs (`.ls`) onto the controller.

- Precompiled binary: A precompiled `gri_comm_background.pc` is included in this repository. It may work, but due to controller software/version differences, compiling locally is recommended to avoid compatibility issues.

### Robot Controller Configuration

1. **Enable KAREL Processing**
   - Navigate to: MENU → NEXT → SYSTEM → Variables
   - Set `KAREL_ENB = 1`

2. **Network Configuration**
   - Ensure robot controller can reach the vision system
   - Default connection: IP of vision system, Port 10000
   - Configure socket C3 for TCP communication
   - You must configure socket `C3:` host IP to your GRI server (e.g., `192.168.56.2`)
   - Note: the background task sets `$HOSTC_CFG[3].$SERVER_PORT` to `10000` automatically (socket `C3:`)

3. **Example Programs**
   - `GRI_EXAMPLE_PICK_AND_PLACE.LS`: Open and run to see a complete cycle. It starts communication, triggers a sync job, checks `R[150]`, uses `PR[53]` as the grasp pose, computes a simple pre‑grasp (`PR[54]` = `PR[53]` with Z offset), moves, and shuts down communication.
   - `GRI_EXAMPLE_HEC.LS`: Open and teach P[1]…P[8] with TOUCHUP, then run. It opens communication, calls `GRI_HEC_INIT(0)`, steps through `GRI_HEC_SET_POSE(0,slot)` for the 8 taught poses (automatically captures current robot position), and calls `GRI_HEC_CALIBRATE(0)`.

## Usage

### Register Usage

**IMPORTANT**: The GRI system requires the following integer registers to be kept free and undisturbed for proper operation. If these registers are already in use by your application, contact Roboception for a custom version using different registers.

**Reserved Registers (R[140-153]):**

**Configuration / Debug Registers:**
- `R[140]` `debug`: optional log detail flag (0=normal summaries, 1=enable detailed DEBUG)

**Command Registers (TP → KAREL):**
- `R[141]` `gri command`: TP→KAREL command (-1 idle)
- `R[142]` `gri param 0`: job/pipeline id
- `R[143]` `gri param 1`: slot id (HEC_SET_POSE)
- `R[144]` `gri param 2`: reserved

**Status Registers (KAREL → TP):**
- `R[149]` `gri comm status`: handshake; 0 ready, -1 error/not running
- `R[150]` `gri obj status`: function result for TP use (see notes below)
- `R[151]` `gri status`: completion/error; 99 while processing, 0 on success, otherwise GRI error code
- `R[152]` `gri data 1`: remaining primary items (e.g., for next/related)
- `R[153]` `gri data 2`: remaining related items

- Position registers
  - `PR[53]` `gri pose`: returned pose for job/next/related

- Notes on `R[150]/R[151]`
  - Pose-returning calls (`GRI_TRIGGER_JOB_SYNC`, `GRI_GET_NEXT_GRASP`, `GRI_GET_RELATED_GRASP`):
    - `R[150] = 20` → pose found; pose in `PR[53]`; remaining counts in `R[152]/R[153]`
    - If no pose or other error: `R[150] = 23`, and `R[151]` holds the specific error code (e.g., `13` = no poses)
  - Confirmation calls (`GRI_TRIGGER_JOB_ASYNC`, `GRI_HEC_*`): `R[150] = 1` on success; otherwise `23` with `R[151]` error code
  - Status call (`GRI_GET_JOB_STATUS`): `R[150] = 1|2|3|4` → INACTIVE|RUNNING|DONE|FAILED



### Simple Vision-Guided Picking

```fanuc
/PROG VISION_PICK_EXAMPLE
/MN
  ! Start vision system
  CALL GRI_OPEN_COMMUNICATION ;
  
  ! Execute vision job
  CALL GRI_TRIGGER_JOB_SYNC(1) ;
  
  ! Check if object was detected
  IF R[150:gri obj status]=20,JMP LBL[pick_object] ;
  MESSAGE[No parts detected] ;
  JMP LBL[cleanup] ;
  
  LBL[pick_object] ;
  ! Move to detected pose (in PR[53])
  L PR[53:gri pose] 200mm/sec FINE ;
  ! Execute gripper close
  DO[1:Gripper]=ON ;
  
  LBL[cleanup] ;
  CALL GRI_QUIT ;
/END
```

### Multiple Object Processing

```fanuc
/PROG PROCESS_MULTIPLE_OBJECTS
/MN
  CALL GRI_OPEN_COMMUNICATION ;
  
  ! Process objects until none remain
  LBL[next_object] ;
  CALL GRI_GET_NEXT_GRASP(1) ;
  
  ! Exit if no more objects
  IF R[150:gri obj status]<>20,JMP LBL[finished] ;
  
  ! Process detected object
  J P[1:approach] 100% FINE ;
  L PR[53:gri pose] 100mm/sec FINE ;
  DO[1:Gripper]=ON ;
  L P[1:approach] 100mm/sec FINE ;
  J P[2:dropoff] 100% FINE ;
  DO[1:Gripper]=OFF ;
  
  ! Continue to next object
  JMP LBL[next_object] ;
  
  LBL[finished] ;
  MESSAGE[Processing complete] ;
  CALL GRI_QUIT ;
/END
```

### Asynchronous Processing

```fanuc
! Start vision job in background
CALL GRI_TRIGGER_JOB_ASYNC(1) ;
IF R[150:gri obj status]<>1, JMP LBL[async_failed] ;

! Continue with other tasks
CALL OTHER_ROBOT_OPERATIONS ;

! Poll job status until done
LBL[poll] ;
CALL GRI_GET_JOB_STATUS(1) ;
IF R[150:gri obj status]=2, JMP LBL[poll] ;      -- RUNNING
IF R[150:gri obj status]<>3, JMP LBL[async_failed] ; -- not DONE

! Job is DONE → fetch results
LBL[next] ;
CALL GRI_GET_NEXT_GRASP(1) ;
IF R[150:gri obj status]<>20, JMP LBL[finished] ;
L PR[53:gri pose] 150mm/sec FINE ;
IF R[152:gri data 1]>0, JMP LBL[next] ;
LBL[finished] ;
JMP LBL[after] ;

LBL[async_failed] ;
MESSAGE[Async job failed - see R151] ;
LBL[after] ;
```

## Status Codes

The system uses register R[150] for all status reporting:

| Status | Description |
|--------|-------------|
| 20 | Object detected, pose available in PR[53] |
| 23 | Error occurred (check `R[151]` for specific code, e.g., 13 = no poses) |
| 1 | Success (for confirmation functions like HEC, async trigger) |

For job status (`GRI_GET_JOB_STATUS`): `R[150] = 1|2|3|4` → INACTIVE|RUNNING|DONE|FAILED.

## Hand-Eye Calibration

Perform camera-robot calibration using the built-in calibration functions.

Quick start using the example program:
- Open `GRI_EXAMPLE_HEC.LS` on the teach pendant
- Teach P[1]–P[8] using TOUCHUP at the desired calibration views
- Run the program; it will initialize HEC, record each taught pose, and execute calibration

```fanuc
! Initialize calibration
CALL GRI_OPEN_COMMUNICATION ;
CALL GRI_HEC_INIT(0) ;
IF R[150:gri obj status]<>1,JMP LBL[error] ;

! Capture calibration poses
J P[10:cal_pos_1] 100% FINE ;
CALL GRI_HEC_SET_POSE(0,1) ;

J P[11:cal_pos_2] 100% FINE ;
CALL GRI_HEC_SET_POSE(0,2) ;

...

J P[12:cal_pos_8] 100% FINE ;
CALL GRI_HEC_SET_POSE(0,8) ;

! Execute calibration
CALL GRI_HEC_CALIBRATE(0) ;
IF R[150:gri obj status]=1,MESSAGE[Calibration complete] ;

CALL GRI_QUIT ;
```

## Function Reference

### Vision Functions

| Function | Description |
|----------|-------------|
| `GRI_TRIGGER_JOB_SYNC(job_id)` | Execute vision job, wait for completion |
| `GRI_TRIGGER_JOB_ASYNC(job_id)` | Start vision job, return immediately |
| `GRI_GET_JOB_STATUS(job_id)` | Check status of asynchronous job |
| `GRI_GET_NEXT_GRASP(job_id)` | Retrieve next pose from job results |
| `GRI_GET_RELATED_GRASP(job_id)` | Retrieve related pose(s) for current primary result |

### Calibration Functions

| Function | Description |
|----------|-------------|
| `GRI_HEC_INIT(pipeline)` | Initialize hand-eye calibration |
| `GRI_HEC_SET_POSE(pipeline,slot)` | Record calibration pose (automatically captures current robot position) |
| `GRI_HEC_CALIBRATE(pipeline)` | Execute calibration calculation |

### System Control

| Function | Description |
|----------|-------------|
| `GRI_OPEN_COMMUNICATION` | Initialize vision system connection |
| `GRI_QUIT` | Shutdown vision system connection |

## Troubleshooting

### Communication Issues

**Problem**: `GRI_OPEN_COMMUNICATION` fails to start
- Verify `KAREL_ENB = 1` in system variables
- Check network connectivity to vision system
- Ensure socket C3 is properly configured

### Collecting Logs for Support
- Log file: `UD1:gri_comm_background.txt` (front USB port = UD1)
- Important: The log is finalized when the background program stops. If an issue occurs, run `GRI_QUIT.LS` to stop the background program, then collect the log.
- How to copy from UD1:
  - Use a USB stick formatted FAT/FAT32 (≤32GB recommended), single primary partition
  - Insert into the controller’s front USB port
  - On the pendant: MENU → FILE → UTIL → Set Device → select `UD1:`
  - Navigate to `UD1:` and copy `gri_comm_background.txt`
  - Safely remove the USB stick and attach the log to your support request

### No Objects Detected

- If the pose-returning call does not find a pose, `R[150]` will be `23` and `R[151] = 13` (no poses found). Check scene and job configuration.
- Check scene lighting and part visibility
- Verify vision job configuration on vision system
- Confirm camera positioning and focus


## System Architecture

The FANUC GRI client uses a layered architecture:

- **TP Programs**: Simple interface functions callable from user programs
- **Background Module**: Compiled KAREL `.pc` (`gri_comm_background.pc`) handling socket/protocol and register bridging
- **TCP Socket**: Binary protocol communication with vision system

## Deployment Checklist

- [ ] `gri_comm_background.pc` loaded
- [ ] All TP programs (.ls files) loaded
- [ ] KAREL_ENB = 1 configured
- [ ] Network connectivity verified
- [ ] System executes without errors
- [ ] Hand-eye calibration completed (if required)
- [ ] Production program integration completed

## Integration Notes

### Existing Program Integration

The GRI client integrates with existing FANUC programs by adding vision calls at appropriate points:

```fanuc
! Your existing program structure
CALL INITIALIZE_SYSTEM ;
CALL SETUP_GRIPPER ;

! Add vision capability
CALL GRI_OPEN_COMMUNICATION ;
CALL GRI_TRIGGER_JOB_SYNC(1) ;
IF R[150:gri obj status]=20,CALL PROCESS_VISION_RESULT ;
CALL GRI_QUIT ;

! Continue with existing logic
CALL CLEANUP_SYSTEM ;
```

### Error Handling Integration

Integrate GRI error handling with your existing error management:

```fanuc
CALL GRI_TRIGGER_JOB_SYNC(1) ;
SELECT R[150:gri obj status] OF
  CASE(20):
    CALL PROCESS_OBJECT ;
  CASE(23):
    CALL HANDLE_VISION_ERROR ;
ENDSELECT ;
```

Note: In this implementation, a "no object" situation is signaled as `R[150]=23` with `R[151]=13` (no poses found). Consider branching on `R[151]` to distinguish causes of errors if needed.

The system provides consistent, reliable communication with Roboception vision systems while maintaining the familiar FANUC programming environment.
