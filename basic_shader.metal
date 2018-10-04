#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float2 pos [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 tex [[attribute(2)]];
};

struct VertOut{
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

vertex VertOut vertexShader(VertIn in[[stage_in]]){
    VertOut out;
    out.position = float4(in.pos, 0, 1);
    out.color = in.color;
    out.texCoord = in.tex;
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]], texture2d<half> colorTexture[[texture(0)]]){
    constexpr sampler defaultSampler;
    const half4 colorSample = colorTexture.sample(defaultSampler, in.texCoord);
    return colorSample;
}