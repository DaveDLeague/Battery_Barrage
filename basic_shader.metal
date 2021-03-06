#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float2 pos [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertOut{
    float4 position [[position]];
    float2 texCoord;
};

struct Uniform {
    float4x4 perspectiveMatrix;
};

vertex VertOut vertexShader(VertIn in[[stage_in]], constant Uniform* uniforms[[buffer(2)]]){
    VertOut out;
    out.position = uniforms->perspectiveMatrix * float4(in.pos, 0, 1);
    out.texCoord = in.texCoord;
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]], texture2d<half> colorTexture[[texture(0)]], sampler defaultSampler[[sampler(0)]]){
    half4 texColor = colorTexture.sample(defaultSampler, in.texCoord);
    return half4(1 - texColor.r, 1 - texColor.r, 1 - texColor.r, texColor.r);
}