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

fragment half4 fragmentShader(VertOut in [[stage_in]]){
    return half4(1, 0, 1, 1);
}