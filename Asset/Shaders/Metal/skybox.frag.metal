#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct cube_vert_output
{
    float4 pos;
    float3 uvw;
};

struct PerFrameConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 arbitraryMatrix;
    float4 camPos;
    uint numLights;
};

struct PerBatchConstants
{
    float4x4 modelMatrix;
};

struct Light
{
    float lightIntensity;
    uint lightType;
    int lightCastShadow;
    int lightShadowMapIndex;
    uint lightAngleAttenCurveType;
    uint lightDistAttenCurveType;
    float2 lightSize;
    uint4 lightGuid;
    float4 lightPosition;
    float4 lightColor;
    float4 lightDirection;
    float4 lightDistAttenCurveParams[2];
    float4 lightAngleAttenCurveParams[2];
    float4x4 lightVP;
    float4 padding[2];
};

struct LightInfo
{
    Light lights[100];
};

struct skybox_frag_main_out
{
    float4 _entryPointOutput [[color(0)]];
};

struct skybox_frag_main_in
{
    float3 input_uvw [[user(locn0)]];
};

float3 exposure_tone_mapping(thread const float3& color)
{
    return float3(1.0) - exp((-color) * 1.0);
}

float3 gamma_correction(thread const float3& color)
{
    return pow(max(color, float3(0.0)), float3(0.4545454680919647216796875));
}

float4 _skybox_frag_main(thread const cube_vert_output& _input, thread texturecube_array<float> skybox, thread sampler samp0)
{
    float4 outputColor = skybox.sample(samp0, float4(_input.uvw, 0.0).xyz, uint(round(float4(_input.uvw, 0.0).w)), level(0.0));
    float3 param = outputColor.xyz;
    float3 _65 = exposure_tone_mapping(param);
    outputColor = float4(_65.x, _65.y, _65.z, outputColor.w);
    float3 param_1 = outputColor.xyz;
    float3 _71 = gamma_correction(param_1);
    outputColor = float4(_71.x, _71.y, _71.z, outputColor.w);
    return outputColor;
}

fragment skybox_frag_main_out skybox_frag_main(skybox_frag_main_in in [[stage_in]], texturecube_array<float> skybox [[texture(10)]], sampler samp0 [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    skybox_frag_main_out out = {};
    cube_vert_output _input;
    _input.pos = gl_FragCoord;
    _input.uvw = in.input_uvw;
    cube_vert_output param = _input;
    out._entryPointOutput = _skybox_frag_main(param, skybox, samp0);
    return out;
}

