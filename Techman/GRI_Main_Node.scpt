// GRI_Main_Node.scpt
// Dynamic GRI request/response for TMscript Script Project
// Inputs (set before run):
//   var_action          (int 1..9) action selector:
//                       1 STATUS            Get system readiness; readiness in data_2 (1/0)
//                       2 TRIGGER_JOB_SYNC  Execute job synchronously
//                       3 TRIGGER_JOB_ASYNC Start job asynchronously
//                       4 GET_JOB_STATUS    Query async job status (see Job status)
//                       5 GET_NEXT_POSE     Retrieve next available result (pose + counts)
//                       6 GET_RELATED_POSE  Retrieve next related pose (pose + counts)
//                       7 HEC_INIT          Initialize hand-eye calibration
//                       8 HEC_SET_POSE      Provide/store calibration pose
//                       9 HEC_CALIBRATE     Run calibration and save results
//   var_job_id          (int) job identifier
//   var_data_1_in..4_in (int, optional) action-specific payload
//   Uses current robot pose: Robot[0].CoordRobot = [x,y,z,rx,ry,rz]
// Outputs:
//   g_gri_error_code
//   g_gri_error_code_string 
//   g_gri_remaining_primary 
//   g_gri_remaining_secondary 
//   g_gri_job_status 
//   g_gri_node_return_code 
//   g_gri_system_ready 
//   g_gri_pose_result (float[6])
// Logging:
//   File_LogWrite to \USB\TMROBOT\Export, minimal Display strings

// --- Local constants ---
int  _magic          = 0x00495247      // "GRI\0" little-endian
byte _protocol       = 1               // protocol version
byte _pose_format    = 26              // EULER_ZYX_B_DEG
byte _request_length = 54
int  _response_len   = 80
int  _scale          = 1000000

// Action constants
byte CONST_ACTION_STATUS            = 1
byte CONST_ACTION_TRIGGER_SYNC      = 2
byte CONST_ACTION_TRIGGER_ASYNC     = 3
byte CONST_ACTION_GET_JOB_STATUS    = 4
byte CONST_ACTION_GET_NEXT_POSE     = 5
byte CONST_ACTION_GET_RELATED_POSE  = 6
byte CONST_ACTION_HEC_INIT          = 7
byte CONST_ACTION_HEC_SET_POSE      = 8
byte CONST_ACTION_HEC_CALIBRATE     = 9

// Job status constants (server-defined)
int CONST_JOB_STATUS_INACTIVE = 1
int CONST_JOB_STATUS_RUNNING  = 2
int CONST_JOB_STATUS_DONE     = 3
int CONST_JOB_STATUS_FAILED   = 4

// --- Inputs with defaults ---
int _action     = var_action
int  _job_id    = var_job_id
int  _data_1_in = var_data_1_in
int  _data_2_in = var_data_2_in
int  _data_3_in = var_data_3_in
int  _data_4_in = var_data_4_in

// Zero all user-facing outputs
g_gri_error_code = 0
g_gri_error_code_string = ""
g_gri_node_return_code = 0
g_gri_remaining_primary = 0
g_gri_remaining_secondary = 0
g_gri_job_status = 0
g_gri_system_ready = 0
g_gri_pose_result = {}

// Action banner
string _action_name = "UNKNOWN"
switch (_action)
{
    case CONST_ACTION_STATUS
        _action_name = "STATUS"
        break
    case CONST_ACTION_TRIGGER_SYNC
        _action_name = "TRIGGER_JOB_SYNC"
        break
    case CONST_ACTION_TRIGGER_ASYNC
        _action_name = "TRIGGER_JOB_ASYNC"
        break
    case CONST_ACTION_GET_JOB_STATUS
        _action_name = "GET_JOB_STATUS"
        break
    case CONST_ACTION_GET_NEXT_POSE
        _action_name = "GET_NEXT_POSE"
        break
    case CONST_ACTION_GET_RELATED_POSE
        _action_name = "GET_RELATED_POSE"
        break
    case CONST_ACTION_HEC_INIT
        _action_name = "HEC_INIT"
        break
    case CONST_ACTION_HEC_SET_POSE
        _action_name = "HEC_SET_POSE"
        break
    case CONST_ACTION_HEC_CALIBRATE
        _action_name = "HEC_CALIBRATE"
        break
    default
        _action_name = "UNKNOWN"
        break
}

Display("GRI ACTION", "Action " + (string)_action + ": " + _action_name)
File_LogWrite("\USB\TMROBOT", "Export", "=========== ACTION " + (string)_action + ": " + _action_name + " ===========")

// Pose input from robot
float[] _curr = Robot[0].CoordRobot
File_LogWrite("current robot pose = [" + (string)_curr[0] + "," + (string)_curr[1] + "," + (string)_curr[2] + "," + (string)_curr[3] + "," + (string)_curr[4] + "," + (string)_curr[5] + "]")
float _px = _curr[0]
float _py = _curr[1]
float _pz = _curr[2]
float _r1f = _curr[3]
float _r2f = _curr[4]
float _r3f = _curr[5]

int _pos_x = (int)(_px * _scale)
int _pos_y = (int)(_py * _scale)
int _pos_z = (int)(_pz * _scale)
int _rot_1 = (int)(_r1f * _scale)
int _rot_2 = (int)(_r2f * _scale)
int _rot_3 = (int)(_r3f * _scale)
int _rot_4 = 0

byte[] _req = {}

// Header
_req = Array_Append(_req, GetBytes(_magic))
_req = Array_Append(_req, GetBytes(_protocol))
_req = Array_Append(_req, GetBytes(_request_length))
_req = Array_Append(_req, GetBytes(_pose_format))
_req = Array_Append(_req, GetBytes((byte)_action))

// Job id (uint16 -> first 2 bytes)
byte[] _job_bytes = GetBytes(_job_id)
_req = Array_Append(_req, Array_SubElements(_job_bytes, 0, 2))

// Pose
_req = Array_Append(_req, GetBytes(_pos_x))
_req = Array_Append(_req, GetBytes(_pos_y))
_req = Array_Append(_req, GetBytes(_pos_z))
_req = Array_Append(_req, GetBytes(_rot_1))
_req = Array_Append(_req, GetBytes(_rot_2))
_req = Array_Append(_req, GetBytes(_rot_3))
_req = Array_Append(_req, GetBytes(_rot_4))

// Data fields
_req = Array_Append(_req, GetBytes(_data_1_in))
_req = Array_Append(_req, GetBytes(_data_2_in))
_req = Array_Append(_req, GetBytes(_data_3_in))
_req = Array_Append(_req, GetBytes(_data_4_in))

File_LogWrite("request hdr magic=" + (string)_magic + " proto=" + (string)_req[4] + " len=" + (string)_req[5] + " pose_fmt=" + (string)_req[6] + " action=" + (string)_req[7] + " job_id=" + (string)_job_id)
File_LogWrite("request pose int = [" + (string)_pos_x + "," + (string)_pos_y + "," + (string)_pos_z + "," + (string)_rot_1 + "," + (string)_rot_2 + "," + (string)_rot_3 + "]")
File_LogWrite("request data = [" + (string)_data_1_in + "," + (string)_data_2_in + "," + (string)_data_3_in + "," + (string)_data_4_in + "] len=" + (string)Length(_req))

// Validate assembled request length to avoid hiding issues
if (Length(_req) != _request_length)
{
    string err_msg = "Invalid length len=" + (string)Length(_req) + " expected=" + (string)_request_length + " (client-side)"
    File_LogWrite("request length mismatch: " + err_msg)
    Display("Black", "Red", "GRI SYSTEM ERROR", err_msg)
    Exit(-1)
}

Display("GRI REQUEST", "Sending request len=" + (string)Length(_req))
File_LogWrite("sending request (len=" + (string)Length(_req) + ")")
// socket_send("ntd_rc_gri_server", _req) // works when network device is set up
// socket_send("var_local_gri_server", _req) // fails, also when before mapping string var_local_gri_server = "ntd_rc_gri_server"
socket_send("ntd_rc_gri_server", _req) // fails


// Receive response
byte[] _resp = socket_read("ntd_rc_gri_server", _response_len, 31000)
Display("GRI RESPONSE", "Received bytes len=" + (string)Length(_resp))
File_LogWrite("received bytes len=" + (string)Length(_resp))

// Length check
if (Length(_resp) < _response_len)
{
    string err_msg_resp = "Response too short len=" + (string)Length(_resp) + " expected=" + (string)_response_len
    File_LogWrite("response too short: " + err_msg_resp)
    Display("Black", "Red", "GRI RESPONSE ERROR", err_msg_resp)
    Exit(-1)
}

// Parse response
int _resp_error   = Byte_ToInt16(Array_SubElements(_resp, 10, 2), 0)
int _rx           = Byte_ToInt32(Array_SubElements(_resp, 12, 4), 0)
int _ry           = Byte_ToInt32(Array_SubElements(_resp, 16, 4), 0)
int _rz           = Byte_ToInt32(Array_SubElements(_resp, 20, 4), 0)
int _r1           = Byte_ToInt32(Array_SubElements(_resp, 24, 4), 0)
int _r2           = Byte_ToInt32(Array_SubElements(_resp, 28, 4), 0)
int _r3           = Byte_ToInt32(Array_SubElements(_resp, 32, 4), 0)
int _r4           = Byte_ToInt32(Array_SubElements(_resp, 36, 4), 0)
int data_1_out    = Byte_ToInt32(Array_SubElements(_resp, 40, 4), 0)
int data_2_out    = Byte_ToInt32(Array_SubElements(_resp, 44, 4), 0)
int data_3_out    = Byte_ToInt32(Array_SubElements(_resp, 48, 4), 0)
int data_4_out    = Byte_ToInt32(Array_SubElements(_resp, 52, 4), 0)
int data_5_out    = Byte_ToInt32(Array_SubElements(_resp, 56, 4), 0)
int data_6_out    = Byte_ToInt32(Array_SubElements(_resp, 60, 4), 0)
int data_7_out    = Byte_ToInt32(Array_SubElements(_resp, 64, 4), 0)
int data_8_out    = Byte_ToInt32(Array_SubElements(_resp, 68, 4), 0)
int data_9_out    = Byte_ToInt32(Array_SubElements(_resp, 72, 4), 0)
int data_10_out   = Byte_ToInt32(Array_SubElements(_resp, 76, 4), 0)


Display("GRI RESPONSE", "Parsed resp err=" + (string)_resp_error + " d1=" + (string)data_1_out + " d2=" + (string)data_2_out + " d3=" + (string)data_3_out)
File_LogWrite("parsed resp err=" + (string)_resp_error + " d1=" + (string)data_1_out + " d2=" + (string)data_2_out + " d3=" + (string)data_3_out)

// Expose outputs per action
g_gri_error_code = _resp_error
g_gri_node_return_code = data_1_out
bool _has_pose = false

// Parse error code
switch (g_gri_error_code)
{
    case 0
        g_gri_error_code_string = ""
        break
    case -1
        g_gri_error_code_string = "UNKNOWN_ERROR"
        break
    case -2
        g_gri_error_code_string = "INTERNAL_ERROR"
        break
    case -3
        g_gri_error_code_string = "API_NOT_REACHABLE"
        break
    case -4
        g_gri_error_code_string = "API_RESPONSE_ERROR"
        break
    case -5
        g_gri_error_code_string = "PIPELINE_NOT_AVAILABLE"
        break
    case -6
        g_gri_error_code_string = "INVALID_REQUEST_ERROR"
        break
    case -7
        g_gri_error_code_string = "INVALID_REQUEST_LENGTH"
        break
    case -8
        g_gri_error_code_string = "INVALID_ACTION"
        break
    case -9
        g_gri_error_code_string = "PROCESSING_TIMEOUT"
        break
    case -10
        g_gri_error_code_string = "UNKNOWN_PROTOCOL_VERSION"
        break
    case -11
        g_gri_error_code_string = "WRONG_PROTOCOL_FOR_JOB"
        break
    case -12
        g_gri_error_code_string = "JOB_DOES_NOT_EXIST"
        break
    case -13
        g_gri_error_code_string = "MISCONFIGURED_JOB"
        break
    case -14
        g_gri_error_code_string = "HEC_CONFIG_ERROR"
        break
    case -15
        g_gri_error_code_string = "HEC_INIT_ERROR"
        break
    case -16
        g_gri_error_code_string = "HEC_SET_POSE_ERROR"
        break
    case -17
        g_gri_error_code_string = "HEC_CALIBRATE_ERROR"
        break
    case -18
        g_gri_error_code_string = "HEC_INSUFFICIENT_DETECTION"
        break
    case 1
        g_gri_error_code_string = "NO_POSES_FOUND"
        break
    case 2
        g_gri_error_code_string = "NO_RELATED_POSES"
        break
    case 3
        g_gri_error_code_string = "NO_RETURN_SPECIFIED"
        break
    case 4
        g_gri_error_code_string = "JOB_STILL_RUNNING"
        break
    default
        g_gri_error_code_string = "UNKNOWN_CODE_" + (string)g_gri_error_code
        break
}


switch (_action)
{
    case CONST_ACTION_STATUS
        g_gri_node_return_code = data_1_out
        g_gri_system_ready = data_2_out     // readiness (1/0)
        g_gri_job_status = 0            // not applicable here
        break

    case CONST_ACTION_TRIGGER_SYNC
        g_gri_node_return_code = data_1_out
        g_gri_remaining_primary = data_2_out
        g_gri_remaining_secondary = data_3_out
        _has_pose = true
        break

    case CONST_ACTION_TRIGGER_ASYNC
        g_gri_node_return_code = data_1_out
        // no pose, no counts
        break

    case CONST_ACTION_GET_JOB_STATUS
        g_gri_node_return_code = data_1_out
        g_gri_job_status = data_2_out
        string _job_status_msg = ""
        switch (g_gri_job_status)
        {
            case CONST_JOB_STATUS_INACTIVE
                _job_status_msg = "INACTIVE"
                break
            case CONST_JOB_STATUS_RUNNING
                _job_status_msg = "RUNNING"
                break
            case CONST_JOB_STATUS_DONE
                _job_status_msg = "DONE"
                break
            case CONST_JOB_STATUS_FAILED
                _job_status_msg = "FAILED"
                break
            default
                _job_status_msg = "UNKNOWN_STATUS_" + (string)g_gri_job_status
                break
        }

        // Report job status immediately for GET_JOB_STATUS
        Display("GRI JOB STATUS", "Status=" + (string)g_gri_job_status + " (" + _job_status_msg + ")")
        File_LogWrite("job status=" + (string)g_gri_job_status + " (" + _job_status_msg + ")")
        break

    case CONST_ACTION_GET_NEXT_POSE
        g_gri_node_return_code = data_1_out
        g_gri_remaining_primary = data_2_out
        g_gri_remaining_secondary = data_3_out
        _has_pose = true
        break

    case CONST_ACTION_GET_RELATED_POSE
        g_gri_node_return_code = data_1_out
        g_gri_remaining_primary = data_2_out
        g_gri_remaining_secondary = data_3_out
        _has_pose = true
        break

    case CONST_ACTION_HEC_INIT
    case CONST_ACTION_HEC_SET_POSE
    case CONST_ACTION_HEC_CALIBRATE
        g_gri_node_return_code = data_1_out
        // no pose
        break

    default
        g_gri_node_return_code = data_1_out
        break
}

if (_has_pose == true)
{
    float _out_x = (float)_rx / _scale
    float _out_y = (float)_ry / _scale
    float _out_z = (float)_rz / _scale
    float _out_r1 = (float)_r1 / _scale
    float _out_r2 = (float)_r2 / _scale
    float _out_r3 = (float)_r3 / _scale

    float[] PoseArray = {}
    PoseArray = Array_Append(PoseArray, _out_x)
    PoseArray = Array_Append(PoseArray, _out_y)
    PoseArray = Array_Append(PoseArray, _out_z)
    PoseArray = Array_Append(PoseArray, _out_r1)
    PoseArray = Array_Append(PoseArray, _out_r2)
    PoseArray = Array_Append(PoseArray, _out_r3)

    // Export pose to global array; main flow writes it to robot point
    g_gri_pose_result = PoseArray
    Display("GRI POSE ARRAY", "[" + (string)PoseArray[0] + "," + (string)PoseArray[1] + "," + (string)PoseArray[2] + "," + (string)PoseArray[3] + "," + (string)PoseArray[4] + "," + (string)PoseArray[5] + "]")
    File_LogWrite("GRI Pose saved to global array: [" + (string)PoseArray[0] + "," + (string)PoseArray[1] + "," + (string)PoseArray[2] + "," + (string)PoseArray[3] + "," + (string)PoseArray[4] + "," + (string)PoseArray[5] + "]")
}

// Final summary: red on error, green on success
if (g_gri_error_code < 0)
{
    string _err_line = "GRI ERROR " + (string)g_gri_error_code + ": " + g_gri_error_code_string
    Display("Black", "Red", _err_line)
    File_LogWrite(_err_line)
}
else
{
    string _ok_line = "Err=" + (string)_resp_error + " node_rc=" + (string)g_gri_node_return_code + " rem=" + (string)g_gri_remaining_primary + "/" + (string)g_gri_remaining_secondary + " job_id=" + (string)_job_id + " action=" + (string)_action + " job_status=" + (string)g_gri_job_status
    Display("Black", "Green", _action_name + " GRI DONE", _ok_line)
    File_LogWrite(_ok_line)
}
