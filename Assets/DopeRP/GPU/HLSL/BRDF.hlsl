#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/CommonMath.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"


float3 F_Schlick(const float3 f0, float f90, float VoH) {
	// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
	return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
	return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

//------------------------------------------------------------------------------
// Specular BRDF implementations
//------------------------------------------------------------------------------

float D_GGX(float roughness, float NoH, const float3 h) {
	// Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"

	// In mediump, there are two problems computing 1.0 - NoH^2
	// 1) 1.0 - NoH^2 suffers floating point cancellation when NoH^2 is close to 1 (highlights)
	// 2) NoH doesn't have enough precision around 1.0
	// Both problem can be fixed by computing 1-NoH^2 in highp and providing NoH in highp as well

	// However, we can do better using Lagrange's identity:
	//      ||a x b||^2 = ||a||^2 ||b||^2 - (a . b)^2
	// since N and H are unit vectors: ||N x H||^2 = 1.0 - NoH^2
	// This computes 1.0 - NoH^2 directly (which is close to zero in the highlights and has
	// enough precision).
	// Overall this yields better performance, keeping all computations in mediump
	#if defined(TARGET_MOBILE)
	vec3 NxH = cross(shading_normal, h);
	float oneMinusNoHSquared = dot(NxH, NxH);
	#else
	float oneMinusNoHSquared = 1.0 - NoH * NoH;
	#endif

	float a = NoH * roughness;
	float k = roughness / (oneMinusNoHSquared + a * a);
	float d = k * k * (1.0 / PI);
	return d;
}

float V_SmithGGXCorrelated(float roughness, float NoV, float NoL) {
	// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
	float a2 = roughness * roughness;
	// TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
	float lambdaV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
	float lambdaL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
	float v = 0.5 / (lambdaV + lambdaL);
	// a2=0 => v = 1 / 4*NoL*NoV   => min=1/4, max=+inf
	// a2=1 => v = 1 / 2*(NoL+NoV) => min=1/4, max=+inf
	// clamp to the maximum value representable in mediump
	return v;
}

//------------------------------------------------------------------------------
// Specular BRDF dispatch
//------------------------------------------------------------------------------

float distribution(float roughness, float NoH, const float3 h) {
	return D_GGX(roughness, NoH, h);
}

float visibility(float roughness, float NoV, float NoL) {
	return V_SmithGGXCorrelated(roughness, NoV, NoL);
}

float3 fresnel(const float3 f0, float LoH) {
	float questionMark = 50.0 * 0.33;
	float f90 = saturate(dot(f0, float3(questionMark, questionMark, questionMark)));
	return F_Schlick(f0, f90, LoH);

}

//------------------------------------------------------------------------------
// Diffuse BRDF implementations
//---

float Fd_Lambert() {
	return 1.0 / PI;
}

float Fd_Burley(float roughness, float NoV, float NoL, float LoH) {
	// Burley 2012, "Physically-Based Shading at Disney"
	float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
	float lightScatter = F_Schlick(1.0, f90, NoL);
	float viewScatter  = F_Schlick(1.0, f90, NoV);
	return lightScatter * viewScatter * (1.0 / PI);
}

//------------------------------------------------------------------------------
// Diffuse BRDF dispatch
//------------------------------------------------------------------------------

float diffuse(float roughness, float NoV, float NoL, float LoH) {
	return Fd_Burley(roughness, NoV, NoL, LoH);
}

float3 IndirectBRDF (SurfaceData surfaceData) {

	float3 reflection = surfaceData.specular * surfaceData.f0 * (1-surfaceData.roughness);
	reflection /= surfaceData.roughness * surfaceData.roughness + 1.0;
	return reflection;
}

#endif