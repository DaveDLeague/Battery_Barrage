#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float3 pos [[attribute(0)]];
};

struct VertOut{
    float4 position [[position]];
};

struct Uniforms{
    float4x4 perspectiveViewMatrix;
};

vertex VertOut vertexShader(VertIn in[[stage_in]], constant Uniforms* uniforms[[buffer(2)]]){
    VertOut out;
    out.position = uniforms->perspectiveViewMatrix * float4(in.pos, 1);
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]]){

    return half4(1, 0, 1, 1);
}