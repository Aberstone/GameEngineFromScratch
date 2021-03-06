#version 420

struct a2v
{
    vec3 inputPosition;
    vec3 inputNormal;
    vec2 inputUV;
    vec3 inputTangent;
    vec3 inputBiTangent;
};

struct pos_only_vert_output
{
    vec4 pos;
};

struct Light
{
    float lightIntensity;
    uint lightType;
    int lightCastShadow;
    int lightShadowMapIndex;
    uint lightAngleAttenCurveType;
    uint lightDistAttenCurveType;
    vec2 lightSize;
    uvec4 lightGuid;
    vec4 lightPosition;
    vec4 lightColor;
    vec4 lightDirection;
    vec4 lightDistAttenCurveParams[2];
    vec4 lightAngleAttenCurveParams[2];
    mat4 lightVP;
    vec4 padding[2];
};

layout(binding = 11, std140) uniform PerBatchConstants
{
    mat4 modelMatrix;
    mat4 arbitraryMatrix;
} _32;

layout(location = 0) in vec3 a_inputPosition;
layout(location = 1) in vec3 a_inputNormal;
layout(location = 2) in vec2 a_inputUV;
layout(location = 3) in vec3 a_inputTangent;
layout(location = 4) in vec3 a_inputBiTangent;

pos_only_vert_output _shadowmap_vert_main(a2v a)
{
    vec4 v = vec4(a.inputPosition, 1.0);
    v = _32.modelMatrix * v;
    pos_only_vert_output o;
    o.pos = _32.arbitraryMatrix * v;
    return o;
}

void main()
{
    a2v a;
    a.inputPosition = a_inputPosition;
    a.inputNormal = a_inputNormal;
    a.inputUV = a_inputUV;
    a.inputTangent = a_inputTangent;
    a.inputBiTangent = a_inputBiTangent;
    a2v param = a;
    gl_Position = _shadowmap_vert_main(param).pos;
}

