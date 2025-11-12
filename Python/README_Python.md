# Python Robot Client Implementation Example

This directory contains a **reference implementation** of a Roboception Generic Robot Interface (GRI) client written in Python. This implementation serves as a **reference example** that can be used when implementing the same functionality on a new robot controller.

The Python implementation demonstrates all aspects of the GRI protocol and mirrors the same concepts used by the robot-side integrations (e.g., FANUC, ABB). It runs on a standard PC and can be used to:
- Explore the binary protocol structure and message formats
- Prototype new behaviors and test vision server responses
- Validate communication patterns before porting to a robot controller
- Understand the complete workflow for all GRI actions
- Serve as a reference when implementing GRI support for new robot platforms

## Architecture Overview

The implementation is organized into modular layers:

1. **Protocol Layer** (`gri_actions.py`, `gri_protocol.py`): Core protocol definitions, enumerations, and binary message packing/unpacking
2. **Communication Layer** (`gri_comms.py`): TCP socket handling and low-level request/response management
3. **Client Facade** (`gri_client.py`): High-level API returning structured results for application use
4. **Configuration** (`gri_config.py`): Connection settings shared across modules
5. **Examples** (`example_main_program.py`, `example_hec.py`): Complete demonstration programs

## File Structure

| File | Description |
| ---- | ----------- |
| `gri_actions.py` | Enumerations for all GRI actions, job status codes, pose formats, and error codes with human-readable description helpers. |
| `gri_protocol.py` | Low-level binary packing/unpacking helpers implementing the fixed-length GRI wire format (54-byte requests, 80-byte responses). Handles pose scaling, endianness, and message validation. |
| `gri_comms.py` | TCP socket client, request/response handling, and typed wrappers for each protocol action. Provides both low-level and mid-level APIs. |
| `gri_client.py` | High-level facade returning structured dataclasses (`ActionReport`) for application use. Simplifies error handling and result extraction. |
| `example_main_program.py` | Complete example script exercising all vision job actions: STATUS, TRIGGER_JOB_SYNC, TRIGGER_JOB_ASYNC, GET_JOB_STATUS, GET_NEXT_POSE, GET_RELATED_POSE. Demonstrates both synchronous and asynchronous workflows with job IDs 0 and 1. |
| `example_hec.py` | Standalone hand-eye calibration example demonstrating the complete HEC workflow: HEC_INIT, eight HEC_SET_POSE calls, and HEC_CALIBRATE. |
| `gri_config.py` | Connection settings (server IP, port, timeout) shared across all modules. Update this file to match your environment. |

## Requirements

- **Python 3.8 or newer** (uses dataclasses and type hints)
- **Network access** to an rc_cube/rc_visard running the GRI server (default port 7100)
- **No external dependencies** - uses only Python standard library (socket, struct, logging, dataclasses, enum)
- Optional: virtual environment for dependency isolation

## Quick Start

### Running the Main Example

The main example program demonstrates all vision job actions:

```bash
python3 example_main_program.py
```

The script will:

1. **Connect** to the server using settings from `gri_config.py`
2. **Check STATUS** to confirm system readiness
3. **Trigger job 0 synchronously** - execute and immediately receive the first pose result
4. **Retrieve related poses** for the synchronous job
5. **Fetch additional primary poses** using `GET_NEXT_POSE` until exhausted
6. **Trigger job 1 asynchronously** - start the job and return immediately
7. **Poll job status** to monitor progress
8. **Wait for completion** using the built-in polling helper
9. **Retrieve all results** from the asynchronous job, including related poses

Each step prints detailed protocol metadata including error codes, remaining pose counts, and node return codes.

### Running the Hand-Eye Calibration Example

The HEC example demonstrates the complete calibration workflow:

```bash
python3 example_hec.py
```

The script will:

1. **Initialize calibration** with `HEC_INIT(pipeline_id)`
2. **Set eight calibration poses** using `HEC_SET_POSE(pipeline_id, slot_id, pose)` for slots 1-8
3. **Execute calibration** with `HEC_CALIBRATE(pipeline_id)`

**Note**: In a real robot application, you would move the robot to different poses where the calibration pattern is visible before calling `HEC_SET_POSE`. The example uses simulated poses for demonstration.

## Using as a Reference Implementation

When implementing GRI support for a new robot controller, use this Python implementation as a reference:

### Protocol Implementation Steps

1. **Study the Protocol Layer**
   - Review `gri_actions.py` for all action codes, status values, and error semantics
   - Examine `gri_protocol.py` to understand message packing/unpacking, pose scaling (1e6), and endianness (little-endian)

2. **Understand Communication Patterns**
   - See `gri_comms.py` for TCP socket connection management
   - Note the fixed message sizes: 54 bytes (request) and 80 bytes (response)
   - Observe error handling patterns and timeout management

3. **Follow the Action Workflows**
   - `example_main_program.py` shows complete vision job workflows
   - `example_hec.py` demonstrates the hand-eye calibration sequence
   - Study how remaining pose counts are tracked and used

4. **Adapt to Your Platform**
   - Replace Python socket calls with your robot's TCP/IP API
   - Use your platform's binary packing functions (equivalent to Python's `struct`)
   - Map GRI pose formats to your robot's coordinate system
   - Implement equivalent error handling and logging

### Key Implementation Points

- **Message Header**: 8 bytes (magic "GRI\0", version, length, pose_format, action)
- **Pose Scaling**: All pose components (position and rotation) are scaled by 1,000,000 before transmission
- **Error Semantics**: Negative = error, zero = success, positive = warning
- **Job Status**: Retrieved from `data_2` field in `GET_JOB_STATUS` response
- **Remaining Counts**: `data_2` = remaining primary poses, `data_3` = remaining related poses
- **Pose Formats**: Server determines format per robot type (see main README.md)

## Custom Integration Tips

### Using the High-Level Facade

For most applications, use `gri_client.py` which provides:
- Structured return values with success flags
- Automatic error code interpretation
- Convenient access to poses and metadata
- Consistent API across all actions

```python
import gri_client as client

client.connect()
result = client.trigger_job_sync(job_id=0, pose=current_pose)
if result.success and result.pose:
    print(f"Pose: {result.pose}")
    print(f"Remaining: {result.remaining_primary} primary, {result.remaining_related} related")
```

### Low-Level Access

When you need more control (e.g., custom pose formats, direct protocol access), use `gri_comms.py`:

```python
import gri_comms as comms

success, pose, rem_primary, rem_related, response = comms.trigger_job_sync(job_id=0)
# Access full response object with all data fields
```

### Configuration

Update `gri_config.py` to match your environment:
- `SERVER_IP`: IP address of the rc_cube/rc_visard
- `SERVER_PORT`: TCP port (default 7100)
- `SERVER_TIMEOUT`: Socket operation timeout in seconds

## Hand-Eye Calibration Workflow

The hand-eye calibration process follows a strict sequence:

1. **Initialize**: Call `HEC_INIT(pipeline_id)` to reset and prepare the pipeline
2. **Capture Poses**: Call `HEC_SET_POSE(pipeline_id, slot_id, pose)` **eight times** with different robot poses (slots 1-8)
   - Each pose should show the calibration pattern from a different viewpoint
   - The robot must be stationary when capturing each pose
   - Ensure good pattern visibility and detection quality
3. **Calibrate**: Call `HEC_CALIBRATE(pipeline_id)` to compute and save the transformation

See `example_hec.py` for a complete implementation example.

## Protocol Reference

For complete protocol specifications, refer to:
- **Main Repository README**: `../README.md` - Overview and architecture
- **Official Documentation**: https://doc.rc-cube.com/latest/en/gri.html - Complete protocol specification
- **FANUC Implementation**: `../FANUC/README_FANUC.md` - Robot-specific integration example
- **ABB Implementation**: `../ABB_RAPID/README_ABB.md` - Another robot platform reference

## Testing and Validation

This Python implementation can be used to:
- Test GRI server responses before deploying to a robot
- Validate protocol compliance
- Debug communication issues
- Benchmark performance
- Develop and test new workflows

The examples include comprehensive logging that shows all protocol details, making it easy to understand what's happening at the wire level.

