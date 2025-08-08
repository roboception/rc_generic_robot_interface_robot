# Roboception Generic Robot Interface
## Robot Side Implementations

This repository contains the official robot-side implementations that demonstrate how to integrate various industrial robot platforms with Roboception's Generic Robot Interface (GRI). The GRI bridges the advanced computer vision capabilities—exposed via Roboception sensors' powerful REST-API—with industrial robot controllers through a simple and efficient TCP socket communication interface.

**Why is this important?**  
Integrating a REST-API directly into robot controllers poses significant challenges due to diverse programming environments and limited REST support on many platforms. To address this, the GRI consolidates all REST interactions within a Docker container running in UserSpace on Roboception sensors. It employs a fixed-length binary protocol over TCP socket communication, ensuring that interfacing with the vision modules is both standardized and straightforward on any robot supporting TCP/IP.

## Available Implementations

### ABB Robots
Complete RAPID implementation for ABB robot controllers.  
[View ABB Documentation](ABB_RAPID/README_ABB.md)  
- Supports IRC5 controllers  
- Tested with RobotWare 6.0 and higher  
- All Interface Actions are implemented callable with simple function calls

### FANUC Robots
Complete KAREL/TP implementation for FANUC robot controllers.  
[View FANUC Documentation](FANUC/README_FANUC.md)  
- Supports R-30iA/R-30iB controllers
- Simple CALL interface for all vision functions
- Background processing with KAREL programs

### Techman Robots
TMScript implementation for Techman robot controllers.

## System Architecture Overview

1. **TCP Socket Server**  
   - Deployed as a Docker container on Roboception sensors within UserSpace.  
   - Uses a fixed-size binary protocol for efficient message exchanges.  
   - Internally handles REST-API interactions and serves information one at a time to the robot controller.

2. **Robot-Side Implementations**  
   - Consist of platform-specific code that connects to the TCP socket server.  
   - Focus on sending standardized fixed-length binary messages and parsing responses to control robot behavior.

## Adding New Robot Support

Developers can extend support for new robot platforms by:
- Implementing a TCP socket client following the GRI binary protocol.
- Using the provided code examples as a reference.

## Requirements

- A Roboception rc_visard or rc_cube running the Generic Robot Interface via Docker.
- A robot controller with TCP/IP support and the ability to pack robot poses into a binary message and to parse binary messages into robot poses.
- The appropriate development environment for your robot’s programming language.

---

## Protocol System

### Architecture Overview
The protocol system uses a hierarchical design with extensible base classes:

1. **Base Protocol Layer**
   - Defines core abstractions and common functionality
   - Provides base message structures and constants
   - Implements protocol versioning support
   - Handles basic message validation

2. **Protocol Version Implementation**
   - Extends base classes for specific protocol versions
   - Adds version-specific actions and error codes
   - Implements concrete message handling
   - Registered via ProtocolRegistry for dynamic dispatch

### Base Protocol Components

##### Protocol Header (5 bytes)
| Field            | Type | Size | Description                    |
|------------------|------|------|--------------------------------|
| magic_number     | int8 | 1    | Protocol identifier           |
| protocol_version | int8 | 1    | Protocol version number       |
| message_length   | int8 | 1    | Total message length in bytes |
| pose_format      | int8 | 1    | Format of pose data           |
| action           | int8 | 1    | Command to execute            |

#### Base Constants

##### Base Pose Formats
| Name             | Value | Description                      |
|------------------|-------|----------------------------------|
| UNKNOWN          | 0     | Invalid/unknown format           |
| M_QUATERNION     | 1     | Meters, quaternion rotation      |
| MM_QUATERNION    | 2     | Millimeters, quaternion rotation |
| M_EULER_DEGREE   | 3     | Meters, Euler angles (degrees)   |
| M_EULER_RADIANS  | 4     | Meters, Euler angles (radians)   |
| MM_EULER_DEGREE  | 5     | MM, Euler angles (degrees)       |
| MM_EULER_RADIANS | 6     | MM, Euler angles (radians)       |
| MM_ABC_KUKA      | 7     | MM, KUKA ABC rotation            |
| M_AXIS_ANGLE     | 8     | Meters, axis-angle rotation      |
| MM_AXIS_ANGLE    | 9     | MM, axis-angle rotation          |
| MM_WPR_FANUC     | 10    | XYZ(mm) WPR(deg) rotation        |

##### Base Error Codes
| Name                    | Value | Description                     |
|------------------------|-------|---------------------------------|
| NO_ERROR               | 0     | Operation successful            |
| UNKNOWN_ERROR          | 1     | Unspecified error              |
| INTERNAL_ERROR         | 2     | Internal system error           |
| API_NOT_REACHABLE      | 3     | Cannot reach vision API         |
| PIPELINE_NOT_AVAILABLE | 4     | Processing pipeline unavailable |
| INVALID_REQUEST_ERROR  | 5     | Malformed request              |
| INVALID_REQUEST_LENGTH | 6     | Wrong message length           |
| INVALID_ACTION         | 7     | Unsupported action             |
| PROCESSING_TIMEOUT     | 8     | Operation timed out            |
| UNKNOWN_PROTOCOL_VERSION| 9     | Protocol version not supported |
| NOT_IMPLEMENTED        | 100   | Feature not implemented        |
| API_ERROR              | 101   | Vision API error               |
| API_RESPONSE_ERROR     | 102   | Invalid API response           |

##### Base Actions
| Name    | Value | Description              |
|---------|-------|--------------------------|
| UNKNOWN | 0     | Invalid/unknown action   |
| STATUS  | 1     | Basic protocol status    |

### Protocol Version 2

#### Protocol Constants
- VERSION: 2
- REQUEST_MAGIC: 2
- RESPONSE_MAGIC: 2
- REQUEST_LENGTH: 50 bytes
- RESPONSE_LENGTH: 55 bytes


#### Protocol V2 Job Status
| Name     | Value | Description              |
|----------|-------|--------------------------|
| INACTIVE | 1     | Job not running or completed |
| RUNNING  | 2     | Job in progress              |
| DONE     | 3     | Job completed with results available |
| FAILED   | 4     | Job did not complete         |

#### Protocol V2 Error Codes
| Name                      | Value | Description                      |
|--------------------------|-------|----------------------------------|
| JOB_DOES_NOT_EXIST       | 10    | Invalid job ID                   |
| JOB_CHANGED              | 11    | Job configuration modified       |
| MISCONFIGURED_JOB        | 12    | Invalid job configuration        |
| NO_POSES_FOUND           | 13    | No results available             |
| NO_ASSOCIATED_OBJECTS    | 14    | No related data found            |
| NO_RETURN_SPECIFIED      | 15    | Job configured with no return type |
| JOB_STILL_RUNNING        | 16    | Async job not complete           |
| HEC_CONFIG_ERROR         | 17    | Calibration configuration error  |
| HEC_INIT_ERROR          | 18    | Calibration init failed          |
| HEC_SET_POSE_ERROR      | 19    | Invalid calibration pose         |
| HEC_CALIBRATE_ERROR     | 20    | Calibration computation failed   |
| HEC_INSUFFICIENT_DETECTION| 21    | Not enough calibration data     |

#### Protocol V2 Actions
| Name              | Value | Description                        |
|-------------------|-------|------------------------------------|
| STATUS            | 1     | Get status of the GRI server      |
| TRIGGER_JOB_SYNC  | 2     | Execute job synchronously          |
| TRIGGER_JOB_ASYNC | 3     | Start job asynchronously          |
| GET_JOB_STATUS    | 4     | Check async job status            |
| GET_NEXT_POSE     | 5     | Get next available result         |
| GET_RELATED_POSE  | 6     | Get associated pose data          |
| HEC_INIT          | 7     | Initialize hand-eye calibration   |
| HEC_SET_POSE      | 8     | Set calibration pose             |
| HEC_CALIBRATE     | 9     | Execute calibration              |

##### Action Details
**Trigger Job Sync (Action 2)**
- Executes a job synchronously and waits for completion.
- Sends the robot pose to the vision module.
- Processes detection and returns the first result immediately.
- Stores additional results for later retrieval.
- Returns an error if no results are found.

**Trigger Job Async (Action 3)**
- Starts job execution without waiting for completion.
- Immediately returns an acknowledgment.
- The job continues processing in the background.
- The client must poll the status using `GET_JOB_STATUS`.
- Results are retrieved via `GET_NEXT_POSE` when the job is done.

**Get Job Status (Action 4)**
- Checks the current state of an asynchronous job.
- Returns job status (`INACTIVE`, `RUNNING`, `DONE`).
- Indicates if an error occurred during processing.
- Used to monitor the completion of asynchronous jobs.

**Get Next Pose (Action 5)**
- Retrieves the next available result.
- Returns the next grasp/pose from the result queue.
- Indicates the number of remaining results.
- Returns an error if no more results are available.
- Automatically resets the job when all results are retrieved.

**Get Related Pose (Action 6)**
- Retrieves the next associated object pose for the current primary object.
- Returns the next associated pose or an error if none are available.
- Used to handle 1:many relationships in pose data.

**HEC_INIT (Action 7)**
- Initializes the hand-eye calibration for a specified pipeline.
- Validates the configuration, including camera mounting and grid dimensions.
- Resets any existing calibration settings.
- Sets grid dimensions for the calibration process.
- Returns success if initialization is successful, otherwise returns an error.

**HEC_SET_POSE (Action 8)**
- Sets a calibration pose for the hand-eye calibration process.
- Requires a valid slot number to be specified in the request.
- Converts the request data into a pose and sends it to the calibration service.
- Returns success if the pose is set correctly, otherwise returns an error.

**HEC_CALIBRATE (Action 9)**
- Executes the calibration process and saves the results.
- Performs the calibration using the configured settings.
- Saves the calibration data if the process is successful.
- Returns success if calibration and saving are successful, otherwise returns an error.


#### Message Structures
##### Request Message (50 bytes)
| Field         | Type  | Size | Description                      |
|---------------|-------|------|----------------------------------|
| header        | struct| 5    | Protocol header                  |
| job_id        | int8  | 1    | Target job number               |
| pos_x         | float | 4    | Position X                      |
| pos_y         | float | 4    | Position Y                      |
| pos_z         | float | 4    | Position Z                      |
| rot_1         | float | 4    | Rotation component 1            |
| rot_2         | float | 4    | Rotation component 2            |
| rot_3         | float | 4    | Rotation component 3            |
| rot_4         | float | 4    | Rotation component 4            |
| data_1        | int32 | 4    | Additional parameter 1          |
| data_2        | int32 | 4    | Additional parameter 2          |
| data_3        | int32 | 4    | Additional parameter 3          |
| data_4        | int32 | 4    | Additional parameter 4          |

##### Response Message (55 bytes)
| Field         | Type  | Size | Description                      |
|---------------|-------|------|----------------------------------|
| header        | struct| 5    | Protocol header                  |
| job_id        | int8  | 1    | Processed job number            |
| error_code    | int8  | 1    | Result status                   |
| pos_x         | float | 4    | Position X                      |
| pos_y         | float | 4    | Position Y                      |
| pos_z         | float | 4    | Position Z                      |
| rot_1         | float | 4    | Rotation component 1            |
| rot_2         | float | 4    | Rotation component 2            |
| rot_3         | float | 4    | Rotation component 3            |
| rot_4         | float | 4    | Rotation component 4            |
| data_1        | int32 | 4    | Additional result 1             |
| data_2        | int32 | 4    | Additional result 2             |
| data_3        | int32 | 4    | Additional result 3             |
| data_4        | int32 | 4    | Additional result 4             |
| data_5        | int32 | 4    | Additional result 5             |


## Implementing Robot-Side Communication

### Technical Requirements
1. TCP Socket Communication
   - Client implementation required
   - Connect to socket server port (10000 by default)
   - Binary protocol with fixed message sizes
   - Little-endian byte order for all values

2. Message Format Details
   - Request messages: Fixed 50 bytes
   - Response messages: Fixed 55 bytes
   - All floating-point values: 32-bit IEEE 754
   - All integer values: Signed, little-endian
   - All position values in meters or millimeters (configurable)
   - All rotation values depend on selected format (quaternion, Euler, axis-angle)

3. Basic Communication Flow
   ```
   Robot                    Interface
     |                         |
     |------- Request -------->|
     |                         |
     |<------ Response --------|
   ```

4. Implementation Steps
   a. Create TCP socket connection
   b. Compose request message:
      - Set protocol header (5 bytes)
      - Set job ID (1 byte)
      - Pack position (12 bytes, 3x float32)
      - Pack rotation (16 bytes, 4x float32)
      - Pack additional data (16 bytes, 4x int32)
   c. Send request (50 bytes total)
   d. Receive response (55 bytes total)
   e. Parse response:
      - Protocol header (5 bytes)
      - Job ID (1 byte)
      - Error code (1 byte)
      - Position (12 bytes, 3x float32)
      - Rotation (16 bytes, 4x float32)
      - Additional data (20 bytes, 5x int32)

### Example Pseudo-Code
```python
# Protocol Header structure (5 bytes)
struct Header {
    int8    magic_number;     # Protocol identifier (2 for requests, 3 for responses)
    int8    protocol_version; # Protocol version (currently 2)
    int8    message_length;   # Total message length (50 for requests, 55 for responses)
    int8    pose_format;      # Format of pose data (see Base Pose Formats table)
    int8    action;          # Command to execute (see Protocol V2 Actions table)
}

# Complete Request Message structure (50 bytes)
struct Request {
    # Header (5 bytes)
    Header   header;      # Protocol header with:
                         #   magic_number = 2 (request)
                         #   protocol_version = 2
                         #   message_length = 50
                         #   pose_format = <selected format>
                         #   action = <command to execute>
    
    # Payload (45 bytes)
    int8      job_id;      # Job identifier
    float32   pos_x;       # Position X
    float32   pos_y;       # Position Y
    float32   pos_z;       # Position Z
    float32   rot_1;       # Rotation component 1
    float32   rot_2;       # Rotation component 2
    float32   rot_3;       # Rotation component 3
    float32   rot_4;       # Rotation component 4
    int32     data_1;      # Additional parameter 1
    int32     data_2;      # Additional parameter 2
    int32     data_3;      # Additional parameter 3
    int32     data_4;      # Additional parameter 4
}

# Complete Response Message structure (55 bytes)
struct Response {
    # Header (5 bytes)
    Header   header;      # Protocol header with:
                         #   magic_number = 3 (response)
                         #   protocol_version = 2
                         #   message_length = 55
                         #   pose_format = <matches request>
                         #   action = <matches request>
    
    # Payload (50 bytes)
    int8      job_id;      # Job identifier
    int8      error_code;  # Result status
    float32   pos_x;       # Position X
    float32   pos_y;       # Position Y
    float32   pos_z;       # Position Z
    float32   rot_1;       # Rotation component 1
    float32   rot_2;       # Rotation component 2
    float32   rot_3;       # Rotation component 3
    float32   rot_4;       # Rotation component 4
    int32     data_1;      # Additional result 1
    int32     data_2;      # Additional result 2
    int32     data_3;      # Additional result 3
    int32     data_4;      # Additional result 4
    int32     data_5;      # Additional result 5
}
```

### Common Implementation Pitfalls
1. Byte Order
   - All multi-byte values must be little-endian
   - Use appropriate conversion functions for your platform

2. Data Types
   - float32: IEEE 754 single-precision floating-point
   - int8: Signed 8-bit integer
   - int32: Signed 32-bit integer

3. Message Validation
   - Always verify received message length
   - Check error codes in responses
   - Validate pose format matches expectations

4. Error Handling
   - Implement timeout handling
   - Handle connection errors gracefully
   - Process protocol error codes appropriately

