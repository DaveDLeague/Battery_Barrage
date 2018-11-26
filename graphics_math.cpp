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
#include <math.h>//TODO: Remove this at some point
Matrix4 createPerpectiveProjectionMatrix(float fov, float aspect, float near, float far){
    Matrix4 m = {};
    m.m[0][0] = 1.0 / (aspect * tan(fov / 2));
    m.m[1][1] = 1.0 / (tan(fov / 2));
    m.m[2][2] = -(far + near) / (far - near);
    m.m[2][3] = -1;
    m.m[3][2] = -(2 * far * near) / (far - near);
    return m;
}

Matrix4 multiply(Matrix4 m1, Matrix4 m2){
    Matrix4 m;
    m.m[0][0] = (m1.m[0][0] * m2.m[0][0]) + (m1.m[1][0] * m2.m[0][1]) + (m1.m[2][0] * m2.m[0][2]) + (m1.m[3][0] * m2.m[0][3]);
    m.m[0][1] = (m1.m[0][1] * m2.m[0][0]) + (m1.m[1][1] * m2.m[0][1]) + (m1.m[2][1] * m2.m[0][2]) + (m1.m[3][1] * m2.m[0][3]);
    m.m[0][2] = (m1.m[0][2] * m2.m[0][0]) + (m1.m[1][2] * m2.m[0][1]) + (m1.m[2][2] * m2.m[0][2]) + (m1.m[3][2] * m2.m[0][3]);
    m.m[0][3] = (m1.m[0][3] * m2.m[0][0]) + (m1.m[1][3] * m2.m[0][1]) + (m1.m[2][3] * m2.m[0][2]) + (m1.m[3][3] * m2.m[0][3]);

    m.m[1][0] = (m1.m[0][0] * m2.m[1][0]) + (m1.m[1][0] * m2.m[1][1]) + (m1.m[2][0] * m2.m[1][2]) + (m1.m[3][0] * m2.m[1][3]);
    m.m[1][1] = (m1.m[0][1] * m2.m[1][0]) + (m1.m[1][1] * m2.m[1][1]) + (m1.m[2][1] * m2.m[1][2]) + (m1.m[3][1] * m2.m[1][3]);
    m.m[1][2] = (m1.m[0][2] * m2.m[1][0]) + (m1.m[1][2] * m2.m[1][1]) + (m1.m[2][2] * m2.m[1][2]) + (m1.m[3][2] * m2.m[1][3]);
    m.m[1][3] = (m1.m[0][3] * m2.m[1][0]) + (m1.m[1][3] * m2.m[1][1]) + (m1.m[2][3] * m2.m[1][2]) + (m1.m[3][3] * m2.m[1][3]);

    m.m[2][0] = (m1.m[0][0] * m2.m[2][0]) + (m1.m[1][0] * m2.m[2][1]) + (m1.m[2][0] * m2.m[2][2]) + (m1.m[3][0] * m2.m[2][3]);
    m.m[2][1] = (m1.m[0][1] * m2.m[2][0]) + (m1.m[1][1] * m2.m[2][1]) + (m1.m[2][1] * m2.m[2][2]) + (m1.m[3][1] * m2.m[2][3]);
    m.m[2][2] = (m1.m[0][2] * m2.m[2][0]) + (m1.m[1][2] * m2.m[2][1]) + (m1.m[2][2] * m2.m[2][2]) + (m1.m[3][2] * m2.m[2][3]);
    m.m[2][3] = (m1.m[0][3] * m2.m[2][0]) + (m1.m[1][3] * m2.m[2][1]) + (m1.m[2][3] * m2.m[2][2]) + (m1.m[3][3] * m2.m[2][3]);

    m.m[3][0] = (m1.m[0][0] * m2.m[3][0]) + (m1.m[1][0] * m2.m[3][1]) + (m1.m[2][0] * m2.m[3][2]) + (m1.m[3][0] * m2.m[3][3]);
    m.m[3][1] = (m1.m[0][1] * m2.m[3][0]) + (m1.m[1][1] * m2.m[3][1]) + (m1.m[2][1] * m2.m[3][2]) + (m1.m[3][1] * m2.m[3][3]);
    m.m[3][2] = (m1.m[0][2] * m2.m[3][0]) + (m1.m[1][2] * m2.m[3][1]) + (m1.m[2][2] * m2.m[3][2]) + (m1.m[3][2] * m2.m[3][3]);
    m.m[3][3] = (m1.m[0][3] * m2.m[3][0]) + (m1.m[1][3] * m2.m[3][1]) + (m1.m[2][3] * m2.m[3][2]) + (m1.m[3][3] * m2.m[3][3]);
    return m; 
}
