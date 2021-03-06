#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct a2v_cube
{
    float3 inputPosition;
    float3 inputUVW;
};

struct cube_vert_output
{
    float4 pos;
    float3 uvw;
};

struct PerFrameConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
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

struct passthrough_cube_vert_main_out
{
    float3 _entryPointOutput_uvw [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct passthrough_cube_vert_main_in
{
    float3 a_inputPosition [[attribute(0)]];
    float3 a_inputUVW [[attribute(1)]];
};

cube_vert_output _passthrough_cube_vert_main(thread const a2v_cube& a)
{
    cube_vert_output o;
    o.pos = float4(a.inputPosition, 1.0);
    o.uvw = a.inputUVW;
    return o;
}

vertex passthrough_cube_vert_main_out passthrough_cube_vert_main(passthrough_cube_vert_main_in in [[stage_in]])
{
    passthrough_cube_vert_main_out out = {};
    a2v_cube a;
    a.inputPosition = in.a_inputPosition;
    a.inputUVW = in.a_inputUVW;
    a2v_cube param = a;
    cube_vert_output flattenTemp = _passthrough_cube_vert_main(param);
    out.gl_Position = flattenTemp.pos;
    out._entryPointOutput_uvw = flattenTemp.uvw;
    return out;
}

