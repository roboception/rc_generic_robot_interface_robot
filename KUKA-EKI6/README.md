# GRI Client for KUKA KRL — Reference Manual

A high-performance, EthernetKRL (EKI) binary implementation of the Generic Robot Interface (GRI) protocol for KUKA KRL. 

## Module Overview

The library is comprised of three main files and an example application module:

*   [GRI_CLIENT.dat](GRI_CLIENT.dat) — Holds global constants (action codes, error codes, pose formats), state variables, configuration options, raw wire buffers, and output result variables.
*   [GRI_CLIENT.src](GRI_CLIENT.src) — Implements all API logic, serialization, deserialization, EKI communications, and SmartPAD console logging.
*   [GRI_CLIENT.xml](GRI_CLIENT.xml) — Defines the EthernetKRL EKI TCP client configuration using structured raw binary blobs (`TxBlob` and `RxBlob`) to interface with the sensor server.
*   [GRI_APP_EXAMPLE.src](GRI_APP_EXAMPLE.src) — Demonstrates a complete workflow for synchronous detection and asynchronous polling.
*   [GRI_HEC_EXAMPLE.src](GRI_HEC_EXAMPLE.src) — Demonstrates a complete workflow for Hand-Eye Calibration.

***
## Architecture & Implementation Overview

### Design Pattern
This client library is implemented as a non-blocking, motion-free communication wrapper. It is designed to expose a simple, standard KRL programming interface:
*   **Boolean Function Returns**: All public API functions (such as `GRI_TriggerJobSync`, `GRI_GetNextPose`, etc.) return a `BOOL` indicating whether the communication roundtrip completed successfully without any protocol errors.
*   **Public Global Output Variables**: When a function succeeds, it decodes the on-wire response and writes the output values directly to public global variables defined in [GRI_CLIENT.dat](GRI_CLIENT.dat) (e.g., `GRI_LastPose`, `GRI_LastError`, `GRI_LastData1..10`). These can be read by the calling program immediately after the function returns.

### Binary Communications via EthernetKRL (EKI)
Unlike standard text-based EKI channels, this client interfaces with the sensor using raw binary serialization:
*   **Requests (54 bytes)**: KRL data is rounded, scaled by `1,000,000` (converting real numbers to 32-bit signed integers), and packed using the KRL instruction `CAST_TO` into the raw buffer `GRI_ReqBuf[]`. The bytes are sent via EKI using the string parameter `TxBlob`.
*   **Responses (80 bytes)**: The client polls EKI via `EKI_ReadNext()` and retrieves the string parameter `RxBlob`. The raw byte buffer `GRI_RspBuf[]` is then unpacked into individual variables using `CAST_FROM`. Floating point numbers are scaled back (`/ 1,000,000.0`) to retrieve their original precision.

**Response Header Validation**  
To ensure protocol alignment and robust error handling, the client automatically validates the 8-byte response header structure before unpacking the payload:
*   **Magic Number**: The first 4 bytes must match the global constant `GRI_MAGIC` ("GRI\0"). Mismatches return `ERR_WRONG_PROTO` (`-11`).
*   **Protocol Version**: The 5th byte must match the expected version (`GRI_PROTO_VER` = `1`). Mismatches return `ERR_PROTO_VER` (`-10`).
*   **Message Length**: The 6th byte must match the response length (`GRI_RSP_LEN` = `80`). Mismatches return `ERR_INV_REQ_LEN` (`-7`).

If any of these validation checks fail, the client logs the failure, sets the corresponding `GRI_LastError`, and aborts parsing.

### Global Scope Call Pattern
*   All public API functions are declared using the `GLOBAL` keyword in [GRI_CLIENT.src](GRI_CLIENT.src). This makes them instantly accessible in any other KRL module on the controller without requiring external forward declarations (`EXT` / `EXTFCT`).
*   The data module [GRI_CLIENT.dat](GRI_CLIENT.dat) is marked `PUBLIC`, exporting all configuration and decoded response variables globally.

---

## Practical Programming Guide
For a step-by-step walkthrough of how to structure your robot program and implement synchronous or asynchronous pick cycles using these actions, refer to the [GRI Application Example Walkthrough](GRI_APP_EXAMPLE.md). The corresponding runnable example is provided in [GRI_APP_EXAMPLE.src](GRI_APP_EXAMPLE.src).

***

## Installation & Deployment

To deploy the EthernetKRL (EKI) configuration and KRL source files to a physical KUKA controller running iiQKA.OS2, use KUKA's engineering tools (**iiQWorks.Sim** or **iiQWorks.App Builder**).

### Step 1: Import the EKI XML Configuration
In iiQKA.OS2, EthernetKRL configurations are managed via the engineering tools, not via direct file system access.
1. Open **iiQWorks.Sim** and connect to your robot instance.
2. In the *Devices* window, expand your robot controller node and navigate to **Option packages > iiQKA.EthernetKRL > Ethernet configuration**.
3. Click the **Import** button in the Properties window and select [GRI_CLIENT.xml](GRI_CLIENT.xml).
4. Verify the IP Address (`PeerIp`) and Port (`PeerPort`) directly in the iiQWorks Properties panel.

### Step 2: Import the KRL Source Files
1. Switch to the **PROGRAM** ribbon in iiQWorks.Sim.
2. Right-click the *Program* folder in the editor window and select **Import > Import KRL files**.
3. Select and import both [GRI_CLIENT.src](GRI_CLIENT.src) and [GRI_CLIENT.dat](GRI_CLIENT.dat).

### Step 3: Deploy to the Physical Controller
1. Switch to the **CONFIGURATION** ribbon.
2. Click **Deploy Configuration onto Controller**. This securely packages your EKI configuration and KRL files and transfers them to the real iiQKA.OS2 robot.


***

## Global Variable Reference

All configuration parameters and outcome results are stored in public global variables within [GRI_CLIENT.dat](GRI_CLIENT.dat). Read response globals immediately after a function call, as the next API call will clear and overwrite them.

### Configuration Variables
*   `GRI_CfgPoseFormat` (`INT`): Active pose representation format (e.g., `GRI_PF_KUKA` = `24`, matching KUKA `FRAME`).
*   `GRI_CfgTimeout` (`REAL`): Communication timeout in seconds for receiving responses (defaults to `GRI_TIMEOUT_DEFAULT` = `71.0` seconds).
*   `GRI_CfgLogLevel` (`INT`): Log verbosity. `0` = Off, `1` = Errors Only, `2` = Verbose (Default).

### Connection State Variables
*   `GRI_Connected` (`BOOL`): `TRUE` if the EthernetKRL socket is open and active.

### Output Result Variables
*   `GRI_LastPose` (`FRAME`): The parsed and decoded target coordinates returned by the sensor.
*   `GRI_LastError` (`INT`): Decoded outcome code of the last request (`0` on success, positive for warnings, negative for errors).
*   `GRI_LastAction` (`INT`): Action code echoed by the sensor response.
*   `GRI_LastJobId` (`INT`): Job ID associated with the response.
*   `GRI_LastData1..10` (`INT`): Protocol-defined auxiliary data fields (such as remaining counts or return codes).

***

## Usage in your application

For complete runnable example programs demonstrating how to use this library, refer to:
* [GRI_APP_EXAMPLE.src](GRI_APP_EXAMPLE.src) — Pick-and-place examples (synchronous & asynchronous).
* [GRI_HEC_EXAMPLE.src](GRI_HEC_EXAMPLE.src) — Hand-Eye Calibration example.

***

## API Function Reference

### Lifecycle & Connection

#### `GRI_Init()`
Initializes the configuration parameters.
*   **Parameters**: None (automatically configures the default timeout and pose format using the `.dat` constants).
*   **Returns**: `VOID`.

#### `GRI_Connect()`
Loads and opens the EKI channel.
*   **Returns**: `BOOL` — `TRUE` if the channel opened successfully, `FALSE` otherwise.
*   **Side Effects**: Sets `GRI_Connected = TRUE` on success.

#### `GRI_Disconnect()`
Closes and unloads the active EKI channel.
*   **Returns**: `VOID`.
*   **Side Effects**: Sets `GRI_Connected = FALSE`.

---

### Pose Detection

#### `GRI_Status()`
Checks sensor reachability and ready status.
*   **Returns**: `BOOL` — `TRUE` if the server responded successfully and reported ready (`GRI_LastData2 == 1`).

#### `GRI_TriggerJobSync(JobId :IN, Pose :IN, RemPrimary :OUT, RemRelated :OUT)`
Triggers a detection run synchronously and blocks until completion.
*   **Parameters**:
    *   `JobId` (`INT`): ID of the job to run.
    *   `Pose` (`FRAME`): Current robot flange pose.
    *   `RemPrimary` (`INT`): Output parameter indicating number of remaining primary poses.
    *   `RemRelated` (`INT`): Output parameter indicating number of remaining related poses for the first primary pose.
*   **Returns**: `BOOL` — `TRUE` if the action succeeded.
*   **Side Effects**: Populates `GRI_LastPose` with the first primary pose.

#### `GRI_TriggerJobAsync(JobId :IN, Pose :IN)`
Triggers a detection run asynchronously. Does not wait for completion.
*   **Parameters**:
    *   `JobId` (`INT`): ID of the job.
    *   `Pose` (`FRAME`): Current robot flange pose.
*   **Returns**: `BOOL` — `TRUE` if request was successfully acknowledged.

#### `GRI_GetJobStatus(JobId :IN)`
Polls the execution state of an asynchronous job.
*   **Parameters**: `JobId` (`INT`).
*   **Returns**: `INT` — Status code: `1` (Inactive), `2` (Running), `3` (Done), `4` (Failed).

#### `GRI_WaitForJob(JobId :IN, MaxPolls :IN, DelayMs :IN)`
Blocks and polls job status until execution completes or max polls is exceeded.
*   **Parameters**:
    *   `JobId` (`INT`).
    *   `MaxPolls` (`INT`): Maximum poll iterations.
    *   `DelayMs` (`INT`): Sleep time between loops in milliseconds.
*   **Returns**: `BOOL` — `TRUE` if the job completed successfully (`GRI_JOB_DONE`).

#### `GRI_GetNextPose(JobId :IN, RemPrimary :OUT, RemRelated :OUT)`
Fetches the next primary pose from the list.
*   **Parameters**:
    *   `JobId` (`INT`).
    *   `RemPrimary` (`INT`): Output parameter for remaining primary poses.
    *   `RemRelated` (`INT`): Output parameter for remaining related poses.
*   **Returns**: `BOOL` — `TRUE` if a pose was retrieved successfully.
*   **Side Effects**: Populates `GRI_LastPose` with the retrieved pose.

#### `GRI_GetRelatedPose(JobId :IN, RemRelated :OUT)`
Fetches the next related pose associated with the current primary pose.
*   **Parameters**:
    *   `JobId` (`INT`).
    *   `RemRelated` (`INT`): Output parameter for remaining related poses.
*   **Returns**: `BOOL` — `TRUE` if a related pose was retrieved.
*   **Side Effects**: Populates `GRI_LastPose` with the retrieved pose.

---

### Hand-Eye Calibration (HEC)

#### `GRI_HecInit(PipelineId :IN)`
Initializes HEC sequence.
*   **Parameters**: `PipelineId` (`INT`).
*   **Returns**: `BOOL` — `TRUE` on success.

#### `GRI_HecSetPose(PipelineId :IN, SlotId :IN, Pose :IN)`
Stores one calibration pose.
*   **Parameters**:
    *   `PipelineId` (`INT`).
    *   `SlotId` (`INT`): Slot index (`1` to `8`).
    *   `Pose` (`FRAME`): Robot flange pose at calibration point.
*   **Returns**: `BOOL` — `TRUE` on success.

#### `GRI_HecCalibrate(PipelineId :IN)`
Requests calculation of HEC transformation matrices from stored points.
*   **Parameters**: `PipelineId` (`INT`).
*   **Returns**: `BOOL` — `TRUE` on success.

***

## Protocol Constant Tables

### Action Codes (`GRI_LastAction`)
*   `1` — `ACT_STATUS`
*   `2` — `ACT_TRIGSYNC`
*   `3` — `ACT_TRIGASYNC`
*   `4` — `ACT_GETJOBSTAT`
*   `5` — `ACT_GETNEXTPOSE`
*   `6` — `ACT_GETRELPOSE`
*   `7` — `ACT_HECINIT`
*   `8` — `ACT_HECSETPOSE`
*   `9` — `ACT_HECCALIB`

### Warning & Error Codes (`GRI_LastError`)
*   `0` — `OK`
*   `1` — `WARN_NOPOSES` (No primary poses found)
*   `2` — `WARN_NORELATED` (No related poses left)
*   `3` — `WARN_NORETURN` (Job status returns nothing)
*   `4` — `WARN_JOB_RUNNING` (Job is still in progress)
*   `-1` — `ERR_UNKNOWN` (General server error)
*   `-2` — `ERR_INTERNAL` (Internal server error)
*   `-3` — `ERR_API_UNREACH` (TCP/EKI write or send failure)
*   `-4` — `ERR_API_RESPONSE` (EKI receive / parsing failure)
*   `-5` — `ERR_NO_PIPELINE` (Invalid HEC pipeline)
*   `-6` — `ERR_INV_REQUEST` (Malformed request structure)
*   `-7` — `ERR_INV_REQ_LEN` (Wrong request size)
*   `-8` — `ERR_INV_ACTION` (Unknown action ID sent)
*   `-9` — `ERR_PROC_TIMEOUT` (KRL wait timer expired)
*   `-10` — `ERR_UNK_PROTO_VER` (Protocol version mismatch)
*   `-11` — `ERR_WRONG_PROTO` (Header prefix was not `GRI\0`)
*   `-12` — `ERR_NO_JOB` (Invalid job ID)
*   `-13` — `ERR_MISCONF_JOB` (Job configuration error)
*   `-14` — `ERR_HEC_CONFIG` (HEC configuration error)
*   `-15` — `ERR_HEC_INIT` (HEC initialization error)
*   `-16` — `ERR_HEC_SETPOSE` (HEC set pose error)
*   `-17` — `ERR_HEC_CALIB` (HEC calculation error)
*   `-18` — `ERR_HEC_NO_DETECT` (HEC target detection error)

***

## Console Notifications
When `GRI_CfgLogLevel` is set to `2` (Verbose), the library sends formatted outcomes directly to the SmartPAD message console. Messages are structured cleanly:
*   **Sender Column**: Shows the active command and Job ID (e.g. `GRI_TRIGSYNC(1)`).
*   **Message Column**: Shows the status, remaining pose counters, and rounded coordinates for success, or the warning/error code name on failure.
    *   *Success Pose Example*: `OK [P:2, R:0] Pose: X=630.0, Y=0.0, Z=1285.0, A=-90, B=0, C=-90`
    *   *Job Status Example*: `OK [Stat: DONE (3)]`
    *   *Warning/Error Example*: `Error 1: WARN_NOPOSES` or `Error -9: ERR_TIMEOUT`