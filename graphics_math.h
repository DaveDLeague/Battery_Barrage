#pragma once

union Matrix4 {
    f32 m[4][4];
};

union Vector2 {
    f32 v[2];
    struct {
        f32 x;
        f32 y;
    };
    Vector2(){}
    Vector2(f32 val): x(val), y(val){}
    Vector2(f32 x, f32 y): x(x), y(y){}
};

union Vector3 {
    f32 v[3];
    struct {
        f32 x;
        f32 y;
        f32 z;
    };
    Vector3(){}
    Vector3(f32 val): x(val), y(val), z(val){}
    Vector3(f32 x, f32 y, f32 z): x(x), y(y), z(z){}
};

union Vector4 {
    f32 v[4];
    struct {
        f32 x;
        f32 y;
        f32 z;
        f32 w;
    };
    Vector4(){}
    Vector4(f32 val): x(val), y(val), z(val), w(val){}
    Vector4(f32 x, f32 y, f32 z, f32 w): x(x), y(y), z(z), w(w){}
    Vector4(Vector2 v2, f32 z, f32 w): x(v2.x), y(v2.y), z(z), w(w){}
    Vector4(Vector3 v3, f32 w): x(v3.x), y(v3.y), z(v3.z), w(w){}
};

union Quaternion {
    f32 v[4];
    struct {
        f32 x;
        f32 y;
        f32 z;
        f32 w;
    };
    Quaternion(){}
    Quaternion(f32 val): x(val), y(val), z(val), w(val){}
    Quaternion(f32 x, f32 y, f32 z, f32 w): x(x), y(y), z(z), w(w){}
    Quaternion(Vector2 v2, f32 z, f32 w): x(v2.x), y(v2.y), z(z), w(w){}
    Quaternion(Vector3 v3, f32 w): x(v3.x), y(v3.y), z(v3.z), w(w){}
};