#include "functions.h.hlsl"
#include "vsoutput.h.hlsl"

float4 pbr_frag_main(pbr_vert_output input) : SV_Target
{
    // offset texture coordinates with Parallax Mapping
    //float3 viewDir   = normalize(input.camPos_tangent - input.v_tangent);
    //float2 texCoords = ParallaxMapping(input.uv, viewDir);
    float2 texCoords = input.uv;

    float3 tangent_normal = normalMap.Sample(samp0, texCoords).rgb;
    tangent_normal = tangent_normal * 2.0f - 1.0f;   
    float3 N = normalize(mul(tangent_normal, input.TBN)); 

    float3 V = normalize(camPos.xyz - input.v_world.xyz);
    float3 R = reflect(-V, N);   

    float3 albedo = inverse_gamma_correction(diffuseMap.Sample(samp0, texCoords).rgb); 

    float meta = metallicMap.Sample(samp0, texCoords).r; 

    float rough = roughnessMap.Sample(samp0, texCoords).r; 

    float3 F0 = 0.04f.xxx; 
    F0 = lerp(F0, albedo, meta);
	           
    // reflectance equation
    float3 Lo = 0.0f.xxx;
    for (int i = 0; i < numLights; i++)
    {
        Light light = lights[i];

        // calculate per-light radiance
        float3 L = normalize(light.lightPosition.xyz - input.v_world.xyz);
        float3 H = normalize(V + L);

        float NdotL = max(dot(N, L), 0.0f);

        // shadow test
        //float visibility = shadow_test(input.v_world, light, NdotL);
        float visibility = 1.0f;

        float lightToSurfDist = length(L);
        float lightToSurfAngle = acos(dot(-L, light.lightDirection.xyz));

        // angle attenuation
        float atten = apply_atten_curve(lightToSurfAngle, light.lightAngleAttenCurveType, light.lightAngleAttenCurveParams);

        // distance attenuation
        atten *= apply_atten_curve(lightToSurfDist, light.lightDistAttenCurveType, light.lightDistAttenCurveParams);

        float3 radiance = light.lightIntensity * atten * light.lightColor.rgb;
        
        // cook-torrance brdf
        float NDF = DistributionGGX(N, H, rough);        
        float G   = GeometrySmithDirect(N, V, L, rough);      
        float3 F    = fresnelSchlick(max(dot(H, V), 0.0f), F0);       
        
        float3 kS = F;
        float3 kD = float3(1.0f) - kS;
        kD *= 1.0f - meta;	  
        
        float3 numerator    = NDF * G * F;
        float denominator = 4.0f * max(dot(N, V), 0.0f) * NdotL;
        float3 specular     = numerator / max(denominator, 0.001f);  
            
        // add to outgoing radiance Lo
        Lo += (kD * albedo / PI + specular) * radiance * NdotL * visibility; 
    }   
  
    float3 ambient;
    {
        // ambient diffuse
        float ambientOcc = aoMap.Sample(samp0, texCoords).r;

        float3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0f), F0, rough);
        float3 kS = F;
        float3 kD = 1.0f - kS;
        kD *= 1.0f - meta;	  

        float3 irradiance = skybox.SampleLevel(samp0, float4(N, 0.0f), 1.0f).rgb;
        float3 diffuse = irradiance * albedo;

        // ambient reflect
        const float MAX_REFLECTION_LOD = 9.0f;
        float3 prefilteredColor = skybox.SampleLevel(samp0, float4(R, 1.0f), rough * MAX_REFLECTION_LOD).rgb;    
        float2 envBRDF  = brdfLUT.Sample(samp0, float2(max(dot(N, V), 0.0f), rough)).rg;
        float3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

        ambient = (kD * diffuse + specular) * ambientOcc;
    }

    float3 linearColor = ambient + Lo;
	
    // tone mapping
    linearColor = reinhard_tone_mapping(linearColor);
   
    // gamma correction
    linearColor = gamma_correction(linearColor);

    return float4(linearColor, 1.0f);
}