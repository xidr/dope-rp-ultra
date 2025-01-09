#ifndef GI_INCLUDED
#define GI_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

#if defined(LIGHTMAP_ON)
    #define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
    #define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
    #define TRANSFER_GI_DATA(input, output) \
        output.lightMapUV = input.lightMapUV * \
        unity_LightmapST.xy + unity_LightmapST.zw;
    #define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
    #define GI_ATTRIBUTE_DATA
    #define GI_VARYINGS_DATA
    #define TRANSFER_GI_DATA(input, output)
    #define GI_FRAGMENT_DATA(input) 0.0
#endif

struct GI {
    float3 specular;
};

float3 SampleEnvironment (SurfaceData surfaceData) {
    float3 uvw = reflect(-surfaceData.viewDirection, surfaceData.normal);
    float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, 0.0);
    return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);;
}

float3 SampleEnvironment (float3 viewDir, float3 surfaceNormal) {
    float3 uvw = reflect(-viewDir, surfaceNormal);
    float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, 0.0);
    return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);;
}

GI GetGI (float2 lightMapUV, SurfaceData surfaceData) {
    GI gi;
    
    gi.specular = SampleEnvironment(surfaceData);
    return gi;
}

#endif