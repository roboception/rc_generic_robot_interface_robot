"""
gri_protocol.py
~~~~~~~~~~~~~~~~

Binary packing/unpacking helpers for the Roboception Generic Robot Interface
(GRI) protocol.  This module exposes dataclasses representing requests and
responses, together with utility functions for dealing with scaled poses and
additional payload fields.
"""

from __future__ import annotations

import logging
import math
import struct
from dataclasses import dataclass, field
from typing import Optional, Sequence, Tuple

import gri_actions as actions

logger = logging.getLogger(__name__)

# Protocol constants (version 1, quaternion XYZW pose representation)
PROTOCOL_VERSION = 1
REQUEST_MAGIC = int.from_bytes(b"GRI\0", "little")
RESPONSE_MAGIC = REQUEST_MAGIC
REQUEST_LENGTH = 54
RESPONSE_LENGTH = 80
POSE_SCALE_FACTOR = 1_000_000


def float_to_scaled(value: float) -> int:
    """Convert a floating-point value to a 32-bit scaled integer."""

    return int(round(value * POSE_SCALE_FACTOR))


def scaled_to_float(value: int) -> float:
    """Convert a scaled integer value back to float."""

    return float(value) / POSE_SCALE_FACTOR


@dataclass
class Pose:
    """Robot pose encoded as millimeters + quaternion."""

    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    q1: float = 0.0
    q2: float = 0.0
    q3: float = 0.0
    q4: float = 1.0

    def normalize(self) -> None:
        """Normalize quaternion components to unit length."""

        magnitude = math.sqrt(self.q1**2 + self.q2**2 + self.q3**2 + self.q4**2)
        if magnitude <= 0.0:
            self.q1, self.q2, self.q3, self.q4 = 0.0, 0.0, 0.0, 1.0
            return

        self.q1 /= magnitude
        self.q2 /= magnitude
        self.q3 /= magnitude
        self.q4 /= magnitude

    def to_scaled_tuple(self) -> Tuple[int, int, int, int, int, int, int]:
        """Return the pose components scaled to protocol integers."""

        self.normalize()
        return (
            float_to_scaled(self.x),
            float_to_scaled(self.y),
            float_to_scaled(self.z),
            float_to_scaled(self.q1),
            float_to_scaled(self.q2),
            float_to_scaled(self.q3),
            float_to_scaled(self.q4),
        )

    @classmethod
    def from_scaled_tuple(cls, values: Sequence[int]) -> "Pose":
        """Instantiate a pose from scaled protocol integers."""

        if len(values) != 7:
            raise ValueError(f"Expected 7 pose components, received {len(values)}.")
        return cls(
            x=scaled_to_float(values[0]),
            y=scaled_to_float(values[1]),
            z=scaled_to_float(values[2]),
            q1=scaled_to_float(values[3]),
            q2=scaled_to_float(values[4]),
            q3=scaled_to_float(values[5]),
            q4=scaled_to_float(values[6]),
        )


@dataclass
class RequestMessage:
    """High-level representation of a protocol request."""

    action: actions.Action
    job_id: int
    pose: Optional[Pose] = None
    data_fields: Sequence[int] = field(default_factory=lambda: (0, 0, 0, 0))

    def __post_init__(self) -> None:
        if len(self.data_fields) != 4:
            raise ValueError(
                "RequestMessage requires exactly four additional data fields."
            )

    def to_bytes(self) -> bytes:
        """Pack the request into its 54-byte binary representation."""

        header = struct.pack(
            "<I4B",
            REQUEST_MAGIC,
            PROTOCOL_VERSION,
            REQUEST_LENGTH,
            actions.PoseFormat.QUATERNION_XYZW,
            int(self.action),
        )

        job_id_bytes = self.job_id.to_bytes(2, byteorder="little", signed=False)

        pose = self.pose or Pose()
        pose_values = pose.to_scaled_tuple()
        pose_bytes = struct.pack("<iii", *pose_values[:3]) + struct.pack(
            "<iiii", *pose_values[3:]
        )
        data_bytes = struct.pack("<4i", *self.data_fields)

        packed = bytearray(header)
        packed.extend(job_id_bytes)
        packed.extend(pose_bytes)
        packed.extend(data_bytes)

        if len(packed) != REQUEST_LENGTH:
            logger.warning(
                "Packed request length mismatch (expected %s, got %s).",
                REQUEST_LENGTH,
                len(packed),
            )

        return bytes(packed)


@dataclass
class ResponseMessage:
    """Decoded wire representation of a protocol response."""

    action: actions.Action
    job_id: int
    error_code: int
    pose: Pose
    data_fields: Tuple[int, int, int, int, int, int, int, int, int, int]

    @classmethod
    def from_bytes(cls, payload: bytes) -> "ResponseMessage":
        """Decode a binary response payload into a ResponseMessage."""

        if len(payload) != RESPONSE_LENGTH:
            raise ValueError(
                f"Expected {RESPONSE_LENGTH} byte response, got {len(payload)} bytes."
            )

        magic, proto_ver, msg_len, pose_format, action_code = struct.unpack(
            "<I4B", payload[0:8]
        )

        if magic != RESPONSE_MAGIC:
            raise ValueError(f"Unexpected response magic: {magic}")
        if proto_ver != PROTOCOL_VERSION:
            logger.warning(
                "Protocol version mismatch: response=%s expected=%s",
                proto_ver,
                PROTOCOL_VERSION,
            )
        if msg_len != RESPONSE_LENGTH:
            raise ValueError(f"Response header length mismatch: {msg_len}")
        if pose_format != actions.PoseFormat.QUATERNION_XYZW:
            logger.warning(
                "Pose format mismatch: response=%s expected=%s",
                pose_format,
                actions.PoseFormat.QUATERNION_XYZW,
            )

        job_id = int.from_bytes(payload[8:10], byteorder="little", signed=False)
        error_code = int.from_bytes(payload[10:12], byteorder="little", signed=True)

        pose_values = struct.unpack("<iii", payload[12:24]) + struct.unpack(
            "<iiii", payload[24:40]
        )
        pose = Pose.from_scaled_tuple(pose_values)

        data_fields = struct.unpack("<10i", payload[40:80])

        try:
            action = actions.Action(action_code)
        except ValueError:
            logger.warning(
                "Unknown action code in response: %s. Defaulting to STATUS.",
                action_code,
            )
            action = actions.Action.STATUS

        return cls(
            action=action,
            job_id=job_id,
            error_code=error_code,
            pose=pose,
            data_fields=tuple(data_fields),
        )

    @property
    def node_return_code(self) -> int:
        return self.data_fields[0]

    @property
    def remaining_primary(self) -> int:
        return self.data_fields[1]

    @property
    def remaining_related(self) -> int:
        return self.data_fields[2]

    def data_slice(self, count: int) -> Tuple[int, ...]:
        """Return the first *count* data fields."""

        if count < 0:
            raise ValueError("Count must be non-negative.")
        return self.data_fields[:count]


def iter_pose_bytes(pose: Pose) -> bytes:
    """
    Utility returning the packed bytes of a pose.

    Mainly useful for debugging or test verification.
    """

    pose_values = pose.to_scaled_tuple()
    return struct.pack("<iii", *pose_values[:3]) + struct.pack(
        "<iiii", *pose_values[3:]
    )
