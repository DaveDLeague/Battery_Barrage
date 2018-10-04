#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float2 pos [[attribute(0)]];
    float2 tex [[attribute(1)]];
};

struct VertOut{
    float4 position [[position]];
    float2 texCoord;
};

vertex VertOut vertexShader(VertIn in[[stage_in]]){
    VertOut out;
    out.position = float4(in.pos, 0, 1);
    out.texCoord = in.tex;
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]], texture2d<half> colorTexture[[texture(0)]], sampler defaultSampler[[sampler(0)]]){
    const half4 colorSample = colorTexture.sample(defaultSampler, in.texCoord);
    return colorSample;
}