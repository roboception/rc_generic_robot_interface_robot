# Generic Robot Interface
## Robot Side Implementations

This repository contains the official robot-side implementations that demonstrate how to integrate various industrial robot platforms with the Generic Robot Interface (GRI). The GRI is part of the firmware of rc_cube and rc_visard devices and bridges their REST-API with a standardized TCP socket interface, enabling robot controllers to communicate with vision modules using simple binary messages over TCP/IP.

**Why is this important?**  
Integrating REST-API directly into robot controllers poses significant challenges due to diverse programming environments and limited REST support on many platforms. The GRI consolidates these interactions and employs a fixed-length binary protocol over TCP, ensuring that vision module communication is both standardized and straightforward on any robot supporting TCP/IP.

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

### Python Reference Implementation
Complete Python reference implementation demonstrating the GRI protocol.  
[View Python Documentation](Python/README_Python.md)  
- Reference example for implementing GRI support on new robot platforms
- Runs on standard PC for testing and validation
- Uses only Python standard library (no external dependencies)

## System Architecture Overview

The GRI consists of a TCP socket server integrated into the firmware that handles all REST-API interactions and communicates with robot controllers using a fixed-length binary protocol. Robot-side implementations connect to this server and exchange standardized messages to control vision workflows.

For detailed architecture information, refer to the [official GRI documentation](https://doc.rc-cube.com/latest/en/gri.html).

## Adding New Robot Support

Developers can extend support for new robot platforms by:
- Implementing a TCP socket client following the GRI binary protocol.
- Using the provided code examples as a reference.

## Requirements

- A vision sensor (rc_visard or rc_cube) with an enabled Generic Robot Interface license
- A robot controller with TCP/IP support and the ability to pack robot poses into a binary message and to parse binary messages into robot poses
- The appropriate development environment for your robot's programming language

---

## Protocol System

The Generic Robot Interface uses Protocol V1 (currently the only version) with a fixed-length binary protocol (54-byte requests, 80-byte responses). The 8-byte header contains the magic number "GRI\0" (ASCII bytes 47 52 49 00), protocol version, message length, pose format, and action. All multi-byte integers use little-endian byte order. Pose data uses 32-bit signed integers scaled by 1,000,000 for precision, with positions in millimeters before scaling.

The protocol supports multiple pose formats (quaternions, Euler angles, axis-angle) and uses signed 16-bit error codes (negative = error, zero = success, positive = warning).

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
- See `FANUC/README_FANUC.md` for detailed usage instructions

**Python Reference Implementation**
- Reference implementation demonstrating all GRI protocol aspects
- Useful for understanding protocol structure and testing before robot deployment
- See `Python/README_Python.md` for detailed usage instructions

### Implementation Guidelines

When implementing robot-side communication, connect to port 7100 and implement proper timeout and error handling. Follow the protocol specifications outlined above, ensuring correct message construction, pose data packing, and response parsing. First, find out your robot controller's rotation format using the [Pose Format Reference](https://doc.rc-cube.com/latest/en/gri.html#pose-formats).

For new robot platform integrations, stick to the Python reference implementation as the primary reference example, and study the existing ABB and FANUC implementations for platform-specific patterns. Always validate your implementation against the [official protocol documentation](https://doc.rc-cube.com/latest/en/gri.html).

