# Techman Generic Robot Interface for Roboception Vision Systems

## Introduction
This guide explains how to install and use the **Roboception GRI Component** for Techman Robot TMflow. This component simplifies communication with the Roboception GRI Server, handling all TCP/IP socket communication, binary protocol parsing, and error handling automatically.

For detailed definitions of GRI concepts, please refer to the [Official Roboception GRI Documentation](https://doc.rc-cube.com/latest/en/gri.html).

---

## Installation (One-Time Setup)

### Step A: Import the Component
1. Create an NTFS-formatted USB stick and label it **TMROBOT**.
2. Download the `TM_Export.zip` and extract it to the root of the USB stick, creating the folder `TM_Export` in the root of the USB stick.
3. Ensure `E:\TM_Export\Roboception\ComponentObject\GRI_01_RC_GRI_Node.zip` is present on the USB stick.
4. Plug the USB stick into the robot controller.
5. In TMflow settings, navigate to **System > Import/Export**.
6. Click **Import** at the top-left, select **Roboception** from the Robot list.
7. In the left sidebar, extend **Configuration** and select **Component**.
8. Select the file `GRI_01_RC_GRI_node.zip` and click **Import**.

### Step B: Enable the Component
1. In TMflow settings, navigate to **Configuration > Component**.
2. Find **GRI_01_RC_GRI_Node.component** in the list and toggle the status switch to **ON**.

---

## Configuration (First Use in Project)

### Step A: Configure the Network Device
When you drag the component into your flow for the first time, it automatically creates a Network Device. You must configure the IP address once.

1. Drag the **Roboception GRI node** into your flow.
2. Navigate to **Project Function > Network Device**.
3. Find the device named `GRI_01_RC_GRI_Node1.ntd_rc_gri_server` (or similar).
4. Click **Edit**.
5. Change the **IP Address** to the IP of your Roboception device.
6. Ensure **Port** is `7100` and **Timeout** is `75000ms`.
7. Click **OK** to save.

---

## Usage in Flow

You can reuse the component multiple times in your flow.

### A. Drag & Drop
Drag the **Roboception GRI node** from the Component list into your flow.

### B. Reuse Strategy (Crucial)
* **First Instance:** Drag it in as usual.
* **Second/Subsequent Instances:** When dragging the component in again, a popup will ask how to create it.
  * **Select the Existing Component**.
  * *Why?* This ensures all nodes share the **same TCP connection** you configured in Step 3. Selecting **New Component** will create duplicate network devices and cause connection errors.

### C. Configure Node Parameters
Click the **Edit** button on the `RC_GRI_Node1` node and go to **Initialization Setup**. 
For **Variables** press the **Select** button.
Assign variables to your needs:

| Variable | Type | Description |
| :--- | :--- | :--- |
| `var_action` | `int` | **Required.** Action ID (1-9). See Table below. |
| `var_job_id` | `int` | **Required.** Job ID to trigger (e.g., `1`). See [Job Definition](https://doc.rc-cube.com/latest/en/gri.html#job-definition). |
| `var_data_1_in` | `int` | Optional input data (default 0). <br>For HEC actions (7, 8, 9): **Pipeline ID**. |
| `var_data_2_in` | `int` | Optional input data (default 0). <br>For `HEC_SET_POSE` (8): **Slot ID (0–7)**. |
| `var_data_3_in` | `int` | Optional input data (default 0). |
| `var_data_4_in` | `int` | Optional input data (default 0). |

#### Supported Actions (`var_action`)
For full details, see [GRI Actions Documentation](https://doc.rc-cube.com/latest/en/gri.html#actions).

| ID | Action Name | Description |
| :--- | :--- | :--- |
| **1** | `STATUS` | Check system readiness. |
| **2** | `TRIGGER_JOB_SYNC` | Trigger a job and wait for the result (Blocking). |
| **3** | `TRIGGER_JOB_ASYNC` | Trigger a job immediately and continue (Non-blocking). |
| **4** | `GET_JOB_STATUS` | Check the status of a running async job. See [Job Status Values](https://doc.rc-cube.com/latest/en/gri.html#job-status). |
| **5** | `GET_NEXT_POSE` | Retrieve the next available part pose. |
| **6** | `GET_RELATED_POSE` | Retrieve a related pose (e.g., approach point). |
| **7** | `HEC_INIT` | Initialize [Hand-Eye Calibration](https://doc.rc-cube.com/latest/en/gri.html#hand-eye-calibration). Set `var_data_1_in` to the pipeline ID. |
| **8** | `HEC_SET_POSE` | Send current pose for calibration. Set `var_data_1_in` to the pipeline ID and `var_data_2_in` to the slot ID (0–7). |
| **9** | `HEC_CALIBRATE` | Calculate calibration result. Set `var_data_1_in` to the pipeline ID. |

---

## Outputs & Logic Flow

The component provides global variables that update after every run. You can use these in **Gateway nodes** or **If/Else** logic immediately after the component.

### Global Return Variables
* `g_gri_error_code`: `0` = Success, `< 0` = Error. See [Error Codes](https://doc.rc-cube.com/latest/en/gri.html#error-codes-and-semantics).
* `g_gri_error_code_string`: Human-readable error message (e.g., `JOB_DOES_NOT_EXIST`).
* `g_gri_node_return_code`: RC node specific return code.
* `g_gri_remaining_primary`: Number of primary objects remaining (returned by Actions 2, 5, 6).
* `g_gri_remaining_secondary`: Number of secondary objects remaining (returned by Actions 2, 5, 6).
* `g_gri_job_status`: Job status (for async actions). See [Job Status](https://doc.rc-cube.com/latest/en/gri.html#job-status).
* `g_system_ready`: Readiness flag from `STATUS` (1 = ready, 0 = not ready).
* `g_gri_pose_result`: Pose array `[x, y, z, rx, ry, rz]` returned by pose-producing actions. Use it in the main flow to write to a robot point.

### How to Use the Result Pose
The component **does not** write directly to a robot Point variable (due to TMflow component limitations). You must assign the result to your point manually in your main flow.

> **Technical Note:** The component automatically requests and parses **Pose Format 26** (`EULER_ZYX_B_DEG`) from the GRI server to match the Techman Robot native coordinate system. For details, see [GRI Pose Formats](https://doc.rc-cube.com/latest/en/gri.html#pose-formats).

**Important:** When you update a Point via script, the value in the **Point Manager (UI)** will **NOT** change. This is normal TMflow behavior (Runtime Data vs. Project Data). The robot uses the updated value in RAM correctly, but the UI shows the static initial value.

1. **Create Point:** Manually create a Point in the TMflow Point Manager (e.g., named `PGRI`).
2. **Assign Value:** Add a **Script Node** immediately after the GRI component node:
   ```c
   Point["PGRI"].Value = g_gri_pose_result
   ```
   *Note: The Point Manager UI will NOT show this new value, but the robot will use it.*
3. **Verify (Optional):** Use `Display()` to verify the updated value on screen.
   ```c
   Display(Point["PGRI"].Value)
   ```
-----

## Advanced: Source Code

The file `GRI_Main_Node.scpt` (included in this repository) contains the actual source code for this interface. It implements the complete GRI protocol handling and can be integrated directly into **TMScript Projects** for advanced customization or if you prefer not to use the Flow Component.


## Troubleshooting & Logging

If the component fails (Red banner on dashboard), detailed logs are automatically generated.

### Accessing Logs

**Detailed logs are only written when a USB stick is inserted.** We recommend leaving a USB stick plugged into the robot controller during operation.

1.  Ensure a USB stick labeled **TMROBOT** is plugged into the robot controller.
2.  Run the project. The component writes detailed logs to:
    `USB:\TMROBOT\Export\GRI_01_RC_GRI_Node-[Date].txt`
3.  **For Support:** If you encounter issues, please attach this log file when contacting Roboception support.

### Common Errors

  * **0x00048B31 (Network Device Invalid):** You likely imported the component as a **New Component** instead of **Existing Component**, creating a duplicate unconfigured network device. Delete the node and drag it in again, selecting **Select Existing Component**.
  * **Please check parametrized value is valid:** If you are trying to assign `g_gri_pose_result` to a point (e.g. `PGRI`) in your main flow, ensure `PGRI` actually exists in the Robot Point Manager.

