# gri_config.py
"""
Configuration constants for the Robot Client Interface.

This file should contain parameters specific to the network connection
to the Generic Robot Interface (GRI) server.
"""

# Server Configuration
SERVER_IP = "1.2.3.4"  # IP address of the machine running the GRI server
SERVER_PORT = 7100  # TCP Port the GRI server listens on
SERVER_TIMEOUT = 65.0  # Timeout in seconds for socket operations (connect, receive)

# Note: Protocol-specific details (version, message sizes, pose format)
# are defined internally within the gri_comms module.
