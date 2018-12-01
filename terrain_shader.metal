#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float3 pos [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertOut{
    float4 position [[position]];
    float3 fragPosition;
    float3 normal;
    float3 lightPosition;
};

struct Uniforms{
    float4x4 perspectiveViewMatrix;
    float3 lightPosition;
};

vertex VertOut vertexShader(VertIn in[[stage_in]], constant Uniforms* uniforms[[buffer(2)]]){
    VertOut out;
    out.fragPosition = in.pos;
    out.position = uniforms->perspectiveViewMatrix * float4(in.pos, 1);
    out.normal = in.normal;
    out.lightPosition = uniforms->lightPosition;
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]]){
    float y = in.fragPosition.y;
    float r = ((y + 1) / 2) - 0.5;
    float g = ((y + 1) / 2) + 0.5;
    float b = abs(y);

    float3 lightDirection = normalize(in.fragPosition - in.lightPosition);

    float diff = max(dot(in.normal, lightDirection), 0.0);
    diff = 1;
    return half4(diff * r, diff * g, diff * b, 1);
}