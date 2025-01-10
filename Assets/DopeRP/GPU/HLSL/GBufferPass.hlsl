#ifndef GBUFFER_PASS_INCLUDED
#define GBUFFER_PASS_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/GI.hlsl"

UNITY_INSTANCING_BUFFER_START(LitBasePerMaterial)

    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoMap_ST)

    UNITY_DEFINE_INSTANCED_PROP(float4, _DetailsColor)
    UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoDetailsMap_ST)

    UNITY_DEFINE_INSTANCED_PROP(float, _EmissionScale)

    UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)

    UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
    UNITY_DEFINE_INSTANCED_PROP(float, _Reflectance)
    UNITY_DEFINE_INSTANCED_PROP(float, _IsMetal)

    UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)

UNITY_INSTANCING_BUFFER_END(LitBasePerMaterial)

TEXTURE2D(_AlbedoMap);
SAMPLER(sampler_AlbedoMap);

TEXTURE2D(_AlbedoDetailsMap);
SAMPLER(sampler_AlbedoDetailsMap);

#if defined(_USE_EMISSION)

    TEXTURE2D(_EmissionMap);
    SAMPLER(sampler_EmissionMap);

#endif

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

CBUFFER_START(GBuffer)

CBUFFER_END

struct MeshData {
    float4 position : POSITION;
    float3 normal   : NORMAL;
    float4 tangentOS : TANGENT;

    float2 uv : TEXCOORD0;

    GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators {
    float4 position : SV_POSITION;
    float3 positionWS : TEXCOORD2;
    float4 tangentWS : VAR_TANGENT;
    float3 normalWS : TEXCOORD3;

    float2 uv         : TEXCOORD5;

    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct fragOutput
{
    float4 tangentWorldSpace : SV_Target0;

    float4 albedo : SV_Target1;
    float4 normalWS : SV_Target2;
    float4 clearNormalWS : SV_Target3;
    float4 specular : SV_Target4;
    float4 BRDF : SV_Target5;
    float4 positionWS : SV_Target6;

};

Interpolators vert(MeshData i)
{
    UNITY_SETUP_INSTANCE_ID(i);
    Interpolators o;
    UNITY_TRANSFER_INSTANCE_ID(i, o);
    TRANSFER_GI_DATA(input, output);
   
    o.position = TransformObjectToHClip(i.position);
    o.positionWS = TransformObjectToWorld(i.position);
    o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);
    o.normalWS = TransformObjectToWorldNormal(i.normal);

    float4 baseMap_ST =  UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _AlbedoMap_ST);
    o.uv = i.uv * baseMap_ST.xy + baseMap_ST.zw;
    return o;
}

float3 GetNormalTS (float2 baseUV) {
    float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, baseUV);
    float scale = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _NormalScale);
    float3 normal = DecodeNormal(map, scale);
	
    return normal;
}

fragOutput frag(Interpolators i) 
{
    UNITY_SETUP_INSTANCE_ID(i);

    
    fragOutput o;


    float4 baseColor = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, i.uv);
    
    #if defined(_CLIPPING)

        clip(baseColor.a - UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Cutoff));

    #endif
    
    o.tangentWorldSpace = i.tangentWS;

    #if defined(_ADD_COLOR)
    
        baseColor += UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _BaseColor);

    #else
    
        baseColor *= UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _BaseColor);

    #endif

    #if defined(_USE_DETAILS_ALBEDO_MAP)
        // baseColor = 0;
        float4 detailsMap_ST = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _AlbedoDetailsMap_ST);
        float4 detailsColor = SAMPLE_TEXTURE2D(_AlbedoDetailsMap, sampler_AlbedoDetailsMap, i.uv *  detailsMap_ST.xy + detailsMap_ST.zw);
        float detailsCutout;
    
        #if defined(_R_CUTOUT)

            detailsCutout = when_gt(detailsColor.r - 0.1, 0);

        #else

            detailsCutout = when_gt(detailsColor.a - 0.1, 0);
    
        #endif

            detailsColor *= detailsCutout;
            detailsColor *= UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _DetailsColor);
            baseColor = detailsColor * detailsCutout + baseColor * not(detailsCutout);

    #endif
    
    
    o.albedo = baseColor;
    
    float3 normal = NormalTangentToWorld(GetNormalTS(i.uv), normalize(i.normalWS), normalize(i.tangentWS));
    o.normalWS = float4(normal, 1);

    o.clearNormalWS = float4(i.normalWS, 1);

    float metallic = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Metallic);
    float roughness = perceptualRoughnessToRoughness(UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Roughness));
    roughness = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Roughness);
    float reflectance = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Reflectance);
    // float isMetal = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _IsMetal);
    float emission = 0;
    
    #if defined(_USE_EMISSION)

        emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv) * UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _EmissionScale);
    
    #endif
    
    o.BRDF = float4(metallic, roughness, reflectance, emission);

    float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
    float3 specular = SampleEnvironment(viewDir, i.normalWS);
    o.specular = float4(specular, 1);

    o.positionWS = float4(i.positionWS, 1);

    return o;
    
}

#endif