#include <metal_stdlib>
using namespace metal;

struct VertIn{
    float2 pos [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float uniformIndex [[attribute(2)]];
};

struct VertOut{
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

struct Uniform {
    float4x4 perspectiveMatrix;
    float4 colors[256];
};

vertex VertOut vertexShader(VertIn in[[stage_in]], constant Uniform* uniforms[[buffer(2)]]){
    VertOut out;
    out.position = uniforms->perspectiveMatrix * float4(in.pos, 0, 1);
    out.texCoord = in.texCoord;
    out.color = uniforms->colors[(int)in.uniformIndex];
    return out;
}

fragment half4 fragmentShader(VertOut in [[stage_in]], texture2d<half> colorTexture[[texture(0)]], sampler defaultSampler[[sampler(0)]]){
    half4 texColor = colorTexture.sample(defaultSampler, in.texCoord);
    float4 color = in.color;
    return half4(texColor.r * color.x, texColor.r * color.y, texColor.r * color.z, texColor.r * in.color.w);
}