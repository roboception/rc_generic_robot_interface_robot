# FANUC Karel Implementation for Generic Robot Interface (Protocols V2 & V3)

This directory contains a FANUC Karel implementation for Roboception's Generic Robot Interface. It allows FANUC robots equipped with the KAREL option to communicate with Roboception's rc_visard sensors or other systems running the corresponding server-side interface via TCP/IP sockets.

**Protocol Support:** This implementation supports both **Protocol Version 2** and **Protocol Version 3**. The active protocol is selected via the `PROTOCOL_TO_USE` constant in the `RC_CONFIG.KL` file.

*   **Protocol V2:** Returns pose data (XYZ + Quaternion).
*   **Protocol V3:** Returns measurement data (min/mean/max points).

Ensure the configured protocol matches the protocol supported and expected by the server.

## Quick Start

1.  **Prerequisites:** KAREL option installed and enabled.
2.  **Copy Files:** Copy all `.kl` files from this `FANUC` directory to the robot controller (e.g., `MD:`).
3.  **Configure:**
    *   Edit `RC_CONFIG.KL`:
        *   Set `SERVER_IP`, `SERVER_PORT`, `SERVER_TIMEOUT`.
        *   Set `PROTOCOL_TO_USE` to `2` or `3` based on your server configuration.
4.  **Translate & Load:** Use standard FANUC procedures (ROBOGUIDE or pendant) to translate `.kl` files to `.pc` and load them onto the controller.
5.  **Run Example:** Load and run `RC_EXAMPLE` to verify setup for the configured protocol.

## Module Structure

*   `RC_CONFIG.KL`: Server settings and **protocol selection (`PROTOCOL_TO_USE`)**.
*   `RC_PROTO.KL`: Protocol constants, codes, and **data structures for both V2 (`RC_V2_RESP_PAYLOAD`) and V3 (`RC_V3_RESP_PAYLOAD`)**.
*   `RC_SOCKET.KL`: Low-level TCP socket communication, V2/V3-aware request packing, and separate V2/V3 response unpacking routines. (Includes `REAL` conversion placeholders).
*   `RC_DEBUG.KL`: Optional debug logging routines (prints V2 or V3 data based on internal checks or function called).
*   `RC_IFACE.KL`: High-level API routines. **Handles protocol switching internally** and provides separate functions for V2/V3 data retrieval.
*   `RC_EXAMPLE.KL`: Example program demonstrating usage, including **conditional logic based on configured protocol**.

## Main API Functions (`RC_IFACE.KL`)

**Common Functions:**

*   `RC_CONNECT`: Connect to the server.
*   `RC_DISCONNECT`: Disconnect from the server.
*   `RC_GET_STATUS(debug : BOOLEAN) : INTEGER`: Check server status (works for V2/V3).
*   `RC_TRIG_JOB_ASYNC(job_id : INTEGER; debug : BOOLEAN) : INTEGER`: Start a job asynchronously (works for V2/V3).
*   `RC_GET_JOB_STAT(job_id : INTEGER; VAR error_code : INTEGER; debug : BOOLEAN) : INTEGER`: Get job status (works for V2/V3).
*   `RC_TRIG_JOB_SYNC(...)`: Trigger a job and wait for completion (works for V2/V3).

**Protocol-Specific Data Retrieval:**

*   `RC_GET_NEXT_POSE(job_id : INTEGER; VAR pose_data : POSITION; VAR last_pose : BOOLEAN; VAR error_code : INTEGER; debug : BOOLEAN) : BOOLEAN`: **(V2 Only)** Retrieves the next pose result. Fills `pose_data`, checks `last_pose`. Returns `FALSE` if configured for V3 or on error.
*   `RC_GET_MEASUREMENTS(job_id : INTEGER; VAR measurement_data : RC_V3_RESP_PAYLOAD; VAR error_code : INTEGER; debug : BOOLEAN) : BOOLEAN`: **(V3 Only)** Retrieves measurement results. Fills `measurement_data`. Returns `FALSE` if configured for V2 or on error.

See comments within `RC_IFACE.KL` for details.

## Data Structures

*   **`RC_V2_RESP_PAYLOAD` (in `RC_PROTO.KL`)**: Holds V2 response data (job ID, error code, pose as XYZ+Quaternion, additional data).
*   **`RC_V3_RESP_PAYLOAD` (in `RC_PROTO.KL`)**: Holds V3 response data (job ID, error code, min/mean/max points, additional data).

## Important Implementation Notes

*   **KAREL Option:** Required.
*   **Protocol Configuration:** Ensure `PROTOCOL_TO_USE` in `RC_CONFIG.KL` matches the server.
*   **Float Conversion (`PACK_FLOAT`/`UNPACK_FLOAT`):** **Placeholders only!** Real-to-byte conversion needs implementation (see previous notes).
*   **Quaternion Conversion (`QUAT_TO_POS`):** **Placeholder only!** Quaternion-to-POSITION conversion (for V2 poses) needs implementation in `RC_IFACE.KL`.
*   **Error Handling:** Check return codes. Use `GET_ERR_STR`.
*   **Debugging:** Use `debug` argument for logging.

## Basic Example (`RC_EXAMPLE.KL`)

```karel
PROGRAM RC_EXAMPLE
-- Example program demonstrating usage for V2 and V3
%NOLOCKGROUP
%NOPAUSE = ERROR + COMMAND + TPENABLE
%INCLUDE RC_IFACE
%INCLUDE RC_PROTO
%INCLUDE RC_CONFIG
VAR
 job_id : INTEGER = 1
 status_code : INTEGER
 error_code : INTEGER
 job_status : INTEGER
 -- V2 specific
 pose_data : POSITION
 last_pose : BOOLEAN
 -- V3 specific
 measurement_data : RC_V3_RESP_PAYLOAD
 -- Common
 err_str : STRING[80]
 debug_mode : BOOLEAN = TRUE
 get_ok : BOOLEAN
BEGIN
 INIT_RC_IFACE
 WRITE TPDISPLAY ('--- Starting RC Interface Example (Proto: ', PROTOCOL_TO_USE, ') ---', CR)
 RC_CONNECT
 status_code = RC_GET_STATUS(debug_mode)
 IF status_code <> ERR_NO_ERROR THEN
  GET_ERR_STR(status_code, err_str)
  WRITE TPDISPLAY ('Connection/Status Error: ', status_code, ' (', err_str, ')', CR)
  GOTO cleanup
 ELSE
  WRITE TPDISPLAY ('Connection successful, Status OK.', CR)
 ENDIF
 WRITE TPDISPLAY ('Triggering Job ', job_id, ' synchronously...', CR)
 RC_TRIG_JOB_SYNC(job_id, job_status, error_code, 500, 10000, debug_mode)
 GET_ERR_STR(error_code, err_str)
 WRITE TPDISPLAY ('Sync Job Result -> Status: ', job_status, ', Error: ', error_code, ' (', err_str, ')', CR)
 IF job_status = JOB_STATUS_DONE AND error_code = ERR_NO_ERROR THEN
  WRITE TPDISPLAY ('Job completed, getting results...', CR)
  IF PROTOCOL_TO_USE = 2 THEN
   WRITE TPDISPLAY ('Using Protocol V2: Getting pose... ', CR)
   REPEAT
    get_ok = RC_GET_NEXT_POSE(job_id, pose_data, last_pose, error_code, debug_mode)
    IF get_ok THEN
     WRITE TPDISPLAY ('Pose Received: XYZ: ', pose_data.x::3, ', ', pose_data.y::3, ', ', pose_data.z::3, CR)
     WRITE TPDISPLAY ('             WPR: ', pose_data.w::3, ', ', pose_data.p::3, ', ', pose_data.r::3, CR)
     WRITE TPDISPLAY ('             Last: ', last_pose, CR)
     DELAY 500
    ELSE
     GET_ERR_STR(error_code, err_str)
     WRITE TPDISPLAY ('Error getting pose: ', error_code, ' (', err_str, ')', CR)
     last_pose = TRUE
    ENDIF
   UNTIL last_pose
  ELSIF PROTOCOL_TO_USE = 3 THEN
   WRITE TPDISPLAY ('Using Protocol V3: Getting measurements...', CR)
   get_ok = RC_GET_MEASUREMENTS(job_id, measurement_data, error_code, debug_mode)
   IF get_ok THEN
    WRITE TPDISPLAY ('Measurements Received: Mean Z: ', measurement_data.mean_z::4, CR)
    WRITE TPDISPLAY ('                     Data 1: ', measurement_data.data_1, CR)
   ELSE
    GET_ERR_STR(error_code, err_str)
    WRITE TPDISPLAY ('Error getting measurements: ', error_code, ' (', err_str, ')', CR)
   ENDIF
  ELSE
   WRITE TPDISPLAY ('Error: Invalid PROTOCOL_TO_USE defined.', CR)
  ENDIF
 ELSIF job_status = JOB_STATUS_FAILED THEN
  WRITE TPDISPLAY ('Job ', job_id, ' failed.', CR)
 ENDIF
cleanup:
 WRITE TPDISPLAY ('--- Example Finished ---', CR)
 RC_DISCONNECT
END RC_EXAMPLE
``` 