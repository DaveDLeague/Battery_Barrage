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
    float r = ((in.y + 1) / 2) - 0.5;
    float g = ((in.y + 1) / 2) + 0.5;
    float b = abs(in.y);
    return half4(r, g, b, 1);
}