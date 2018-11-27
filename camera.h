#pragma once

struct Camera {
    Vector3 position;
    Vector3 forward;
    Vector3 up;
    Vector3 right;
    Quaternion orientation;
    Matrix4 projection;
};