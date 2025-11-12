"""
gri_actions.py
~~~~~~~~~~~~~~~~

Enumerations and helper utilities describing the Roboception Generic Robot
Interface (GRI) protocol actions, statuses, and error codes.

This module centralizes the numeric identifiers that are exchanged over the
wire so that the rest of the client implementation can reference them in a
type-safe way and obtain human readable descriptions where appropriate.
"""

from __future__ import annotations

from enum import IntEnum
from typing import Dict


class Action(IntEnum):
    """Action identifiers defined by the GRI protocol."""

    STATUS = 1
    TRIGGER_JOB_SYNC = 2
    TRIGGER_JOB_ASYNC = 3
    GET_JOB_STATUS = 4
    GET_NEXT_POSE = 5
    GET_RELATED_POSE = 6
    HEC_INIT = 7
    HEC_SET_POSE = 8
    HEC_CALIBRATE = 9


class JobStatus(IntEnum):
    """Lifecycle states reported for asynchronous jobs."""

    UNKNOWN = 0
    INACTIVE = 1
    RUNNING = 2
    DONE = 3
    FAILED = 4


class PoseFormat(IntEnum):
    """Pose encoding format codes."""

    QUATERNION_XYZW = 2


class ErrorCode(IntEnum):
    """Signed GRI return codes (negative=error, positive=warning)."""

    NO_ERROR = 0

    UNKNOWN_ERROR = -1
    INTERNAL_ERROR = -2
    API_NOT_REACHABLE = -3
    API_RESPONSE_ERROR = -4
    PIPELINE_NOT_AVAILABLE = -5
    INVALID_REQUEST_ERROR = -6
    INVALID_REQUEST_LENGTH = -7
    INVALID_ACTION = -8
    PROCESSING_TIMEOUT = -9
    UNKNOWN_PROTOCOL_VERSION = -10
    WRONG_PROTOCOL_FOR_JOB = -11
    JOB_DOES_NOT_EXIST = -12
    MISCONFIGURED_JOB = -13
    HEC_CONFIG_ERROR = -14
    HEC_INIT_ERROR = -15
    HEC_SET_POSE_ERROR = -16
    HEC_CALIBRATE_ERROR = -17
    HEC_INSUFFICIENT_DETECTION = -18

    NO_POSES_FOUND = 1
    NO_RELATED_POSES = 2
    NO_RETURN_SPECIFIED = 3
    JOB_STILL_RUNNING = 4


ERROR_DESCRIPTIONS: Dict[int, str] = {
    ErrorCode.NO_ERROR: "No error",
    ErrorCode.UNKNOWN_ERROR: "Unknown error",
    ErrorCode.INTERNAL_ERROR: "Internal system error",
    ErrorCode.API_NOT_REACHABLE: "Cannot reach vision API",
    ErrorCode.API_RESPONSE_ERROR: "API returned a negative code",
    ErrorCode.PIPELINE_NOT_AVAILABLE: "Processing pipeline unavailable",
    ErrorCode.INVALID_REQUEST_ERROR: "Malformed request",
    ErrorCode.INVALID_REQUEST_LENGTH: "Wrong message length",
    ErrorCode.INVALID_ACTION: "Unsupported action",
    ErrorCode.PROCESSING_TIMEOUT: "Operation timed out",
    ErrorCode.UNKNOWN_PROTOCOL_VERSION: "Protocol version not supported",
    ErrorCode.WRONG_PROTOCOL_FOR_JOB: "Job does not match protocol version",
    ErrorCode.JOB_DOES_NOT_EXIST: "Invalid job ID",
    ErrorCode.MISCONFIGURED_JOB: "Invalid job configuration",
    ErrorCode.HEC_CONFIG_ERROR: "Invalid calibration configuration",
    ErrorCode.HEC_INIT_ERROR: "Calibration initialization failed",
    ErrorCode.HEC_SET_POSE_ERROR: "Failed to record calibration pose",
    ErrorCode.HEC_CALIBRATE_ERROR: "Unable to compute calibration",
    ErrorCode.HEC_INSUFFICIENT_DETECTION: "Calibration pattern not detected",
    ErrorCode.NO_POSES_FOUND: "No primary poses available",
    ErrorCode.NO_RELATED_POSES: "No related poses available",
    ErrorCode.NO_RETURN_SPECIFIED: "Job configured with no return type",
    ErrorCode.JOB_STILL_RUNNING: "Job still running",
}


def describe_error(code: int) -> str:
    """Return a human-readable description for a GRI error/warning code."""

    return ERROR_DESCRIPTIONS.get(code, f"Unknown error code: {code}")


JOB_STATUS_NAMES: Dict[int, str] = {
    JobStatus.UNKNOWN: "UNKNOWN",
    JobStatus.INACTIVE: "INACTIVE",
    JobStatus.RUNNING: "RUNNING",
    JobStatus.DONE: "DONE",
    JobStatus.FAILED: "FAILED",
}


def describe_status(status: int) -> str:
    """Return a human-readable label for a job status code."""

    return JOB_STATUS_NAMES.get(status, f"UNRECOGNIZED({status})")
