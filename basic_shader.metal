#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float2 pos [[attribute(0)]];
};

struct VertOut{
    float4 position [[position]];
};

vertex VertOut vertexShader(VertIn in[[stage_in]]){
    VertOut out;
    out.position = float4(in.pos, 0, 1);
    return out;
}

fragment float4 fragmentShader(VertOut in [[stage_in]]){
    return float4(0.8, 0.5, 0.3, 1.0);
}