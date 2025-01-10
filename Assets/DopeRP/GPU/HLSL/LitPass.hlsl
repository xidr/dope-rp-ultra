#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED


#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"
#include "Assets/DopeRP/GPU/HLSL/GI.hlsl"
#include "Assets/DopeRP/GPU/HLSL/Lighting.hlsl"


UNITY_INSTANCING_BUFFER_START(LitBasePerMaterial)

	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoMap_ST)

UNITY_DEFINE_INSTANCED_PROP(float4, _DetailsColor)
UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoDetailsMap_ST)

UNITY_DEFINE_INSTANCED_PROP(float, _EmissionScale)

	UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)

	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Reflectance)
	UNITY_DEFINE_INSTANCED_PROP(float, _IsMetal)	

UNITY_INSTANCING_BUFFER_END(LitBasePerMaterial)

CBUFFER_START(LitMain)

	float4 _ScreenSize;

CBUFFER_END

TEXTURE2D(_AlbedoMap);
SAMPLER(sampler_AlbedoMap);

TEXTURE2D(_AlbedoDetailsMap);
SAMPLER(sampler_AlbedoDetailsMap);

// TEXTURE2D(_DecalsAlbedoAtlas);
// SAMPLER(sampler_DecalsAlbedoAtlas);
//
// TEXTURE2D(_DecalsNormalAtlas);
// SAMPLER(sampler_DecalsNormalAtlas);

#if defined(_USE_EMISSION)

	TEXTURE2D(_EmissionMap);
	SAMPLER(sampler_EmissionMap);

#endif

TEXTURE2D(_NormalMap);

TEXTURE2D(_SSAOBlurAtlas);
SAMPLER(sampler_SSAOBlurAtlas);

// TEXTURE2D(_DepthBuffer);
// SAMPLER(sampler_DepthBuffer);


struct MeshData {
	float3 positionOS : POSITION;
	float3 normalOS   : NORMAL;
	float2 uv         : TEXCOORD0;
	float4 tangentOS : TANGENT;
	
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS   : VAR_NORMAL;
	float2 uv         : TEXCOORD0;
	float4 tangentWS : VAR_TANGENT;

	float4 positionTEST: TEXCOORD1;
	
	GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Interpolators vert(MeshData i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	Interpolators o;
	UNITY_TRANSFER_INSTANCE_ID(i, o);
	TRANSFER_GI_DATA(input, output);
	
	o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
	o.positionCS = TransformWorldToHClip(o.positionWS);
	o.normalWS = TransformObjectToWorldNormal(i.normalOS);
	float4 baseMap_ST =  UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _AlbedoMap_ST);
	o.uv = i.uv * baseMap_ST.xy + baseMap_ST.zw;
	o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);

	o.positionTEST = TransformObjectToHClip(i.positionOS);
	
	return o;
}

// float3 GetEmission (float2 baseUV) {
// 	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_AlbedoMap, baseUV);
// 	float4 color = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _EmissionColor);
// 	return map.rgb * color.rgb;
// }

float3 GetNormalTS (float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_AlbedoMap, baseUV);
	float scale = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _NormalScale);
	float3 normal = DecodeNormal(map, scale);
	
	return normal;
}

float4 frag(Interpolators i) : SV_TARGET
{
	
	UNITY_SETUP_INSTANCE_ID(i);

	float2 screenSpaceCoordinates;
	#if UNITY_REVERSED_Z
		screenSpaceCoordinates = float2((i.positionCS.x * _ScreenSize.z), (1 - i.positionCS.y * _ScreenSize.w));
	#else
		screenSpaceCoordinates = i.positionCS * _ScreenSize.zw;
	#endif

	float4 baseColor = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, i.uv);
	baseColor *= UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _BaseColor);

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
	
	#if defined(SSAO_ON)
	
	float ssao = SAMPLE_TEXTURE2D(_SSAOBlurAtlas, sampler_SSAOBlurAtlas, screenSpaceCoordinates).r;
	if (ssao > 0)
		baseColor *= ssao * when_eq(baseColor.a,1) + 1 * when_neq(baseColor.a,1);

	#endif

	
	SurfaceData surfaceData;
	surfaceData.normal = NormalTangentToWorld(GetNormalTS(i.uv), normalize(i.normalWS), normalize(i.tangentWS));

	
	#if defined(DECALS_ON)
	if (baseColor.a==1)
	{
		float4 decals = SAMPLE_TEXTURE2D(_DecalsAlbedoAtlas, sampler_DecalsAlbedoAtlas, screenSpaceCoordinates);
		if (decals.a > 0)
			baseColor = decals;
		float4 decalsNormals = SAMPLE_TEXTURE2D(_DecalsNormalAtlas, sampler_DecalsNormalAtlas, screenSpaceCoordinates);
		if (decalsNormals.a >0)
		{
			surfaceData.normal = decalsNormals;
		}
	}

	#endif

	surfaceData.viewDirection = normalize(_WorldSpaceCameraPos - i.positionWS);
	surfaceData.depth = -TransformWorldToView(i.positionWS).z;
	surfaceData.metallic = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Metallic);
	#ifdef _PREMULTIPLY_ALPHA
		surfaceData.color = computeDiffuseColor(baseColor.rgb, surfaceData.metallic) * baseColor.a;
	#else
		surfaceData.color = computeDiffuseColor(baseColor.rgb, surfaceData.metallic);
	#endif
	surfaceData.positionWS = i.positionWS;
	surfaceData.alpha = baseColor.a;
	surfaceData.roughness = perceptualRoughnessToRoughness(UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Roughness));
	surfaceData.isMetal = UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _IsMetal);
	surfaceData.f0 = computeReflectance(baseColor, surfaceData.metallic, UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Reflectance));
	surfaceData.specular = SampleEnvironment(surfaceData.viewDirection, i.normalWS);

	float3 fragColor = 0;;
	
	// GI gi = GetGI(GI_FRAGMENT_DATA(input), surfaceData);
	fragColor += IndirectBRDF(surfaceData)* 0.1;

	fragColor += GetLighting(surfaceData);
	// fragColor += GetEmission(i.uv) ;

	#if defined(_USE_EMISSION)

		float emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv);
		fragColor += emission * baseColor* UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _EmissionScale);
    
	#endif
	
	return float4(fragColor, surfaceData.alpha);
	
}

#endif