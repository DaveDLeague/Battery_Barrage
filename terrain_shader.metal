#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float3 pos [[attribute(0)]];
};

struct VertOut{
    float4 position [[position]];
    float y;
};

struct Uniforms{
    float4x4 perspectiveViewMatrix;
};

vertex VertOut vertexShader(VertIn in[[stage_in]], constant Uniforms* uniforms[[buffer(2)]]){
    VertOut out;
    out.y = in.pos.y;
    out.position = uniforms->perspectiveViewMatrix * float4(in.pos, 1);
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]]){
    return half4(0.1, in.y, 0.2, 1);
}