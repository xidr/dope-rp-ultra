#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"
#include "CommonMath.hlsl"
#include "CommonMaterial.hlsl"


#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_I_V unity_MatrixInvV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_PREV_MATRIX_M unity_prev_MatrixM
#define UNITY_PREV_MATRIX_I_M unity_prev_MatrixIM
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_MATRIX_I_P unity_CameraInvProjection

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

struct Light
{
	
	float3 direction;
	float3 color;
	float attenuation;
	
};

float2 MultiplyUV (float4x4 mat, float2 inUV) {
	float4 temp = float4 (inUV.x, inUV.y, 0, 0);
	temp = mul (mat, temp);
	return temp.xy;
}

float3 DecodeNormal (float4 sample, float scale) {
	#if defined(UNITY_NO_DXT5nm)
		return normalize(UnpackNormalRGB(sample, scale));
	#else
		return normalize(UnpackNormalmapRGorAG(sample, scale));
	#endif
}

float CalcLinearZ(float depth, float zNear, float zFar) {


	// bias it from [0, 1] to [-1, 1]
	float linearZ = zNear / (zFar - depth * (zFar - zNear)) * zFar;

	return linearZ *2-1;
}

float CalcLinearZ2(float depth, float zNear, float zFar) {
	// Convert depth from [0, 1] to normalized device coordinate (NDC) space [-1, 1]
	float zNdc = 2.0 * depth - 1.0; // Convert from [0, 1] to [-1, 1]
    
	// Convert from NDC space to view space
	float linearZ = 2.0 * zNear * zFar / (zFar + zNear - zNdc * (zFar - zNear));
    
	return linearZ;
}

float4 ViewSpaceFromDepth(float2 uv, float depth, float4x4 inverseProjection)
{
	float4 clipSpacePosition = float4(uv * 2 - 1, depth, 1);

	float4 viewSpacePosition = mul(Inverse(inverseProjection), clipSpacePosition);

	viewSpacePosition /= viewSpacePosition.w;

	return viewSpacePosition;
}

float4 ViewSpaceFromDepth(float depth, float2 uv, float nearPlane, float farPlane, float4x4 invProjMatrix)
{
	float linearZ =CalcLinearZ(depth, nearPlane, farPlane);

	float4 clipSpacePosition = float4((uv * 2.0 - 1.0) * linearZ/depth, linearZ, 1.0 * linearZ/depth);

	float4 viewSpacePosition = mul(invProjMatrix, clipSpacePosition);

	return viewSpacePosition / viewSpacePosition.w;
}



float3 NormalTangentToWorld (float3 normalTS, float3 normalWS, float4 tangentWS) {
	float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	
	return TransformTangentToWorld(normalTS, tangentToWorld);
}

#endif