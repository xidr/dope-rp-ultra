#ifndef LIT_PASS_INCLUDED
#define LIT_PASS_INCLUDED


#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"
#include "Assets/DopeRP/GPU/HLSL/GI.hlsl"
#include "Assets/DopeRP/GPU/HLSL/Lighting.hlsl"




CBUFFER_START(LitMain)

	float4 _ScreenSize;
	float2 _NearFarPlanes;
	float4x4 _Matrix_I_V;
	float4x4 _Matrix_V;
	float4x4 _Matrix_P;
	float4x4 _Matrix_I_P;
	float _AmbientLightScale;

CBUFFER_END


TEXTURE2D(_SSAOBlurAtlas);
SAMPLER(sampler_SSAOBlurAtlas);

TEXTURE2D(_G_AlbedoAtlas);
SAMPLER(sampler_G_AlbedoAtlas);

TEXTURE2D(_G_NormalWorldSpaceAtlas);
SAMPLER(sampler_G_NormalWorldSpaceAtlas);

TEXTURE2D(_G_SpecularAtlas);
SAMPLER(sampler_G_SpecularAtlas);

TEXTURE2D(_G_BRDFAtlas);
SAMPLER(sampler_G_BRDFAtlas);

TEXTURE2D(_DepthBuffer);
SAMPLER(sampler_DepthBuffer);


struct MeshData {
	float3 positionOS : POSITION;
	float3 normalOS   : NORMAL;
	float2 uv         : TEXCOORD0;
	float4 tangentOS : TANGENT;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS   : VAR_NORMAL;
	float2 uv         : TEXCOORD0;
	float4 tangentWS : VAR_TANGENT;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Interpolators vert(MeshData i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	Interpolators o;
	UNITY_TRANSFER_INSTANCE_ID(i, o);
	
	o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
	o.positionCS = TransformWorldToHClip(o.positionWS);
	o.normalWS = TransformObjectToWorldNormal(i.normalOS);
	
	o.uv = i.uv;
	o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);
	
	return o;
}


float4 frag(Interpolators i) : SV_TARGET
{
	
	UNITY_SETUP_INSTANCE_ID(i);
	float4 baseColor = SAMPLE_TEXTURE2D(_G_AlbedoAtlas, sampler_G_AlbedoAtlas, i.uv);
	
	clip(baseColor.a-0.0001);
	SurfaceData surfaceData;

	#if defined(SSAO_ON)
	
		// float4 ssao = SAMPLE_TEXTURE2D(_SSAOBlurAtlas, sampler_SSAOBlurAtlas, i.uv);
		// return ssao;
	
		float ssao = SAMPLE_TEXTURE2D(_SSAOBlurAtlas, sampler_SSAOBlurAtlas, i.uv).r;
		// if (ssao > 0)
		baseColor *= ssao * when_gt(ssao, 0) + 1 * when_le(ssao, 0);

	#endif

	surfaceData.normal = SAMPLE_TEXTURE2D(_G_NormalWorldSpaceAtlas, sampler_G_NormalWorldSpaceAtlas, i.uv).xyz;

	float depth = SAMPLE_TEXTURE2D(_DepthBuffer, sampler_DepthBuffer, i.uv).r;

	float4 clipSpacePosition;
	float4 viewSpacePosition;

	#if !UNITY_REVERSED_Z
		depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);

		float sceneZ =CalcLinearZ(depth, _NearFarPlanes.x, _NearFarPlanes.y);
		clipSpacePosition = float4((i.uv * 2.0 - 1.0) * sceneZ/depth, sceneZ, 1.0 * sceneZ/depth);
		viewSpacePosition = mul(_Matrix_I_P, clipSpacePosition);
		viewSpacePosition /= viewSpacePosition.w;

	#else

		clipSpacePosition = float4(i.uv * 2 - 1, depth, 1);
		viewSpacePosition = mul(Inverse(_Matrix_P), clipSpacePosition);
		viewSpacePosition /= viewSpacePosition.w;
	
	#endif

	
	surfaceData.positionWS = mul(_Matrix_I_V, viewSpacePosition).xyz;
	surfaceData.viewDirection = normalize(_WorldSpaceCameraPos - surfaceData.positionWS);
	surfaceData.depth = -TransformWorldToView(surfaceData.positionWS).z;

	float4 brdfAtlas = SAMPLE_TEXTURE2D(_G_BRDFAtlas, sampler_G_BRDFAtlas, i.uv);
	
	surfaceData.metallic = brdfAtlas.x;
	// surfaceData.isMetal = brdfAtlas.x;
	#ifdef _PREMULTIPLY_ALPHA
		surfaceData.color = computeDiffuseColor(baseColor.rgb, surfaceData.metallic) * baseColor.a;
	#else
		surfaceData.color = computeDiffuseColor(baseColor.rgb, surfaceData.metallic);
	#endif
	surfaceData.alpha = baseColor.a;
	surfaceData.roughness = brdfAtlas.y;
	surfaceData.f0 = computeReflectance(baseColor, surfaceData.metallic, brdfAtlas.z);

	float4 specularAtlas = SAMPLE_TEXTURE2D(_G_SpecularAtlas, sampler_G_SpecularAtlas, i.uv);

	surfaceData.specular = specularAtlas.xyz;

	
	float3 fragColor = 0;

	
	// GI gi = GetGI(GI_FRAGMENT_DATA(input), surfaceData);
	// fragColor += IndirectBRDF(surfaceData)* 0.1;

	fragColor += GetLighting(surfaceData);
	// fragColor += GetEmission(i.uv) ;

	fragColor += brdfAtlas.w * baseColor;

	#if defined(AMBIENT_LIGHT_ON)
	
		float3 ambientSafetyNet = baseColor * _AmbientLightScale;
		return float4(max(fragColor, ambientSafetyNet), surfaceData.alpha);

	#else

		return float4(fragColor, surfaceData.alpha);

	#endif
	
}

#endif