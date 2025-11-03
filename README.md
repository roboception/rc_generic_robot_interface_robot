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
The Generic Robot Interface uses a sophisticated binary protocol designed for industrial robot environments. 

**Message Structure**
- All messages use an 8-byte header containing magic number, protocol version, message length, pose format, and action
- Request messages are 54 bytes total, response messages are 80 bytes total
- All multi-byte integers are transmitted in little-endian byte order
- Pose data uses 32-bit signed integers scaled by 1,000,000 for precision

**Pose Formats**
The protocol supports multiple pose representation formats to accommodate different robot platforms:
- Quaternions (WXYZ and XYZW order)
- Euler angles in various sequences and units
- Axis-angle representations
- Each robot integration uses a fixed format defined by the server

**Error Handling**
The protocol uses signed 16-bit error codes with semantic meaning:
- Negative values (< 0) indicate errors
- Zero (0) indicates success
- Positive values (> 0) indicate warnings

**Actions**
The protocol supports comprehensive robot-vision interaction:
- Synchronous and asynchronous job execution
- Status monitoring and result retrieval
- Hand-eye calibration workflows
- Related pose handling for complex object relationships

### Detailed Protocol Documentation

For complete technical specifications, field layouts, and implementation details, refer to the official documentation:

- **Main GRI Documentation**: https://doc.rc-cube.com/latest/en/gri.html
- **Protocol Specification**: https://doc.rc-cube.com/latest/en/gri.html#gri-binary-protocol-specification
- **Message Header Details**: https://doc.rc-cube.com/latest/en/gri.html#message-header-8-bytes
- **Pose Format Reference**: https://doc.rc-cube.com/latest/en/gri.html#pose-formats
- **Action Definitions**: https://doc.rc-cube.com/latest/en/gri.html#actions
- **Job Status Codes**: https://doc.rc-cube.com/latest/en/gri.html#job-status
- **Message Body Layouts**: https://doc.rc-cube.com/latest/en/gri.html#body-definitions
- **Error Code Semantics**: https://doc.rc-cube.com/latest/en/gri.html#error-codes-and-semantics
- **Integration Guide**: https://doc.rc-cube.com/latest/en/gri.html#integration-with-a-robot

### Robot-Specific Implementation Notes

**ABB RAPID Integration**
- Uses QUAT_WXYZ pose format (format code 1)
- All pose components packed as [w, x, y, z] quaternion
- See `ABB_RAPID/README_ABB.md` for detailed usage instructions

**FANUC KAREL/TP Integration**
- Uses EULER_ZYX_B_DEG pose format (format code 26)
- Rotation components packed as [R, P, W] in degrees
- Job status retrieved from data_2 field
- See `FANUC/README_FANUC.md` for detailed usage instructions

### Implementation Guidelines

When implementing robot-side communication:

1. **TCP Socket Communication**
   - Connect to port 7100 (default GRI port)
   - Use binary protocol with fixed message sizes
   - Implement proper timeout and error handling

2. **Message Construction**
   - Build 8-byte header with correct magic number and version
   - Pack pose data using the robot's assigned format
   - Scale all pose components by 1,000,000 before transmission
   - Use little-endian byte order for all multi-byte values

3. **Response Processing**
   - Validate message length and header consistency
   - Check error codes using signed semantics
   - Convert scaled pose data back to floating-point values
   - Handle both errors and warnings appropriately

4. **Best Practices**
   - Implement connection retry logic
   - Use appropriate timeouts for operations
   - Validate pose format matches expectations
   - Test with various job types and scenarios

For new robot platform integrations, study the existing ABB and FANUC implementations as reference examples, and always validate your implementation against the official protocol documentation.

