#include "graphics_math.h"

Matrix4 createIdentityMatrix(){
    Matrix4 m = {};
    m.m[0][0] = 1;
    m.m[1][1] = 1;
    m.m[2][2] = 1;
    m.m[3][3] = 1;
    return m;
}

Matrix4 createOrthogonalProjectionMatrix(float left, float right, float bottom, float top, float near, float far){
    Matrix4 m = {};
    m.m[0][0] = 2.0f / (right - left);
    m.m[1][1] = 2.0f / (top - bottom);
    m.m[2][2] = 2.0f / (near - far);
    m.m[3][3] = 1;

    m.m[3][0] = -(right + left) / (right - left);
    m.m[3][1] = -(top + bottom) / (top - bottom);
    m.m[3][2] = (far + near) / (far - near);
    return m;
}

