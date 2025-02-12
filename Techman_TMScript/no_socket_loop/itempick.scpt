//Socket ntd_d1 = "10.0.1.108", 10000
Socket ntd_d1 = "10.0.1.32", 10000
socket_open("ntd_d1")

float[] current_pos = Robot[0].CoordRobot
byte[] data = {}

// build request
data = Array_Append(data, GetBytes(3, 0)) // magic number
data = Array_Append(data, GetBytes(1, 0)) // protocol version
data = Array_Append(data, GetBytes(0, 0)) // data length
data = Array_Append(data, GetBytes(2, 0))  // pose format
data = Array_Append(data, GetBytes(9, 0)) // action
data = Array_Append(data, GetBytes(1, 0)) // job
data = Array_Append(data, GetBytes(current_pos[0])) // pos x
data = Array_Append(data, GetBytes(current_pos[1])) // pos y
data = Array_Append(data, GetBytes(current_pos[2])) // pos z
data = Array_Append(data, GetBytes(current_pos[3])) // rot rx
data = Array_Append(data, GetBytes(current_pos[4])) // rot ry
data = Array_Append(data, GetBytes(current_pos[5])) // rot rz
data = Array_Append(data, GetBytes(0, 0, 0)) // rot rw (only for quaternions)
data = Array_Append(data, GetBytes(0, 0, 0)) // data 1
data = Array_Append(data, GetBytes(0, 0, 0)) // data 2
data = Array_Append(data, GetBytes(0, 0, 0)) // data 3
data = Array_Append(data, GetBytes(0, 0, 0)) // data 4
data[2] = Length(data)

// send request to sensor
socket_send("ntd_d1", data)

// wait for response
byte[] response = socket_read("ntd_d1", 0, 30000) // read all bytes; timeout 30 sec (30000 ms)
// unpack response
if (Length(response) == 0) {
    Display("No response received.")
}

// unpack response
int magic_number = response[0]
int version = response[1]
int length = response[2]
int pose_format = response[3]
int action = response[4]
int job_id = response[5]
int error_code = response[6]
float pose_x = Byte_ToFloat(Array_SubElements(response, 7, 4), 0)
float pose_y = Byte_ToFloat(Array_SubElements(response, 11, 4), 0)
float pose_z = Byte_ToFloat(Array_SubElements(response, 15, 4), 0)
float rot_rx = Byte_ToFloat(Array_SubElements(response, 19, 4), 0)
float rot_ry = Byte_ToFloat(Array_SubElements(response, 23, 4), 0)
float rot_rz = Byte_ToFloat(Array_SubElements(response, 27, 4), 0)
float data_1 = Byte_ToInt32(Array_SubElements(response, 35, 4), 0)
float data_2 = Byte_ToInt32(Array_SubElements(response, 39, 4), 0)
float data_3 = Byte_ToInt32(Array_SubElements(response, 43, 4), 0)
float data_4 = Byte_ToInt32(Array_SubElements(response, 47, 4), 0)
float data_5 = Byte_ToInt32(Array_SubElements(response, 51, 4), 0)

if (error_code == 0)
{
    // on success
    float[] pose = {}
    pose = Array_Append(pose, pose_x)
    pose = Array_Append(pose, pose_y)
    pose = Array_Append(pose, pose_z)
    pose = Array_Append(pose, rot_rx)
    pose = Array_Append(pose, rot_ry)
    pose = Array_Append(pose, rot_rz)
    //Display("Pose var: ", pose)
    //Pause()
    Point["P1"].Value = pose
    Display("Grasp found: ", Point["P1"].Value)
} else {
    // on failure
    Display("No Grasp found. Error", error_code)
}
socket_close("ntd_d1")
Pause()
