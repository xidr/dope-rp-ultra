#ifndef SHADOWS_INCLUDED
#define SHADOWS_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"


#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 1
#define MAX_CASCADE_COUNT 4

#if defined(_DIRECTIONAL_PCF2x2)
    #define PCF_VALUE 1
    #define PCF_MULT_VALUE 0.25
#elif defined(_DIRECTIONAL_PCF4x4)
    #define PCF_VALUE 3
    #define PCF_MULT_VALUE 0.0625
#elif defined(_DIRECTIONAL_PCF6x6)
    #define PCF_VALUE 5
    #define PCF_MULT_VALUE 0.028
#elif defined(_DIRECTIONAL_PCF8x8)
    #define PCF_VALUE 7
    #define PCF_MULT_VALUE 0.015625
#endif

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
int _CascadeCount;
    float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    float4 _CascadeData[MAX_CASCADE_COUNT];
    float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
    float4 _ShadowAtlasSize;
    float4 _ShadowDistanceFade;
    float2 _DirectionalShadowAtlas_TexelSize;
CBUFFER_END

struct ShadowData {
    int cascadeIndex;
    float strength;
};

struct DirectionalShadowData {
    float strength;
    float normalBias;
};

float FadedShadowStrength (float distance, float scale, float fade) {
    return saturate((1.0 - distance * scale) * fade);
}

ShadowData GetShadowData (SurfaceData surfaceData) {
    ShadowData data;
    data.strength = FadedShadowStrength(surfaceData.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    
    int i = 0;

    float fade;

    float4 forLoopConditions = float4(1,0,0,0);
    
    float checkIter_1;
    float checkIter_2 = 1;
    float checkCombo;

    float4 sphere = _CascadeCullingSpheres[0];
    float distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz);

    // data.color = distanceSqr < sphere.w;
    // return  data;

    // for (i = 0; i < _CascadeCount; i++) {
    //     float4 sphere = _CascadeCullingSpheres[i];
    //     float distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz);
    //     if (distanceSqr < sphere.w) {
    //         float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
    //         if (i == _CascadeCount - 1) {
    //             data.strength *= fade;
    //         }
    //         else {
    //             data.cascadeBlend = fade;
    //         }
    //         break;
    //     }
    // }

    // i = 0;
    
    #if defined(CASCADE_COUNT_4) || defined(CASCADE_COUNT_2)
    
     sphere = _CascadeCullingSpheres[0] * checkIter_2;
     distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz) * checkIter_2;
     
     checkIter_1 = when_lt(distanceSqr, sphere.w);
     checkCombo = checkIter_1 * checkIter_2;
     
     fade = FadedShadowStrength(distanceSqr, _CascadeData[0].x, _ShadowDistanceFade.z) * checkCombo;
     
     data.strength *= (1 * or(not(checkCombo),when_neq(0, _CascadeCount - 1))  + (fade) * when_eq(0, _CascadeCount - 1) * checkCombo);


     checkIter_2 = not(checkIter_1);
     
     i += 1 * checkIter_2;

    //---

    
     sphere = _CascadeCullingSpheres[1];
     distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz);
     
     checkIter_1 = when_lt(distanceSqr, sphere.w);
     checkCombo = checkIter_1 * checkIter_2;

     fade = FadedShadowStrength(distanceSqr, _CascadeData[1].x, _ShadowDistanceFade.z) * checkCombo;
     
     data.strength *= (1 * or(not(checkCombo),when_neq(0, _CascadeCount - 1))  + (fade) * when_eq(0, _CascadeCount - 1) * checkCombo);


     checkIter_2 = not(checkIter_1);
     
     i += 1 * checkIter_2;

    #endif
    
    // //--- ---
    
    #if defined(CASCADE_COUNT_4)
    
    sphere = _CascadeCullingSpheres[2];
    distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz);
     
    checkIter_1 = when_lt(distanceSqr, sphere.w);
    checkCombo = checkIter_1 * checkIter_2;

    fade = FadedShadowStrength(distanceSqr, _CascadeData[2].x, _ShadowDistanceFade.z) * checkCombo;
     
    data.strength *= (1 * or(not(checkCombo),when_neq(0, _CascadeCount - 1))  + (fade) * when_eq(0, _CascadeCount - 1) * checkCombo);


    checkIter_2 = not(checkIter_1);
     
    i += 1 * checkIter_2;
    
    //---
    
    sphere = _CascadeCullingSpheres[3];
    distanceSqr = DistanceSquared(surfaceData.positionWS, sphere.xyz);
     
    checkIter_1 = when_lt(distanceSqr, sphere.w);
    checkCombo = checkIter_1 * checkIter_2;

    fade = FadedShadowStrength(distanceSqr, _CascadeData[3].x, _ShadowDistanceFade.z) * checkCombo;
     
    data.strength *= (1 * or(not(checkCombo),when_neq(0, _CascadeCount - 1))  + (fade) * when_eq(0, _CascadeCount - 1) * checkCombo);


    checkIter_2 = not(checkIter_1);
     
    i += 1 * checkIter_2;

    #endif


    float iEqCascadeCount = when_eq(i, _CascadeCount);
    data.strength = data.strength * not(iEqCascadeCount);

    

    
    data.cascadeIndex = i;
    

    
    return data;
}

float SampleDirectionalShadowAtlas (float3 positionSTS) {
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

float offset_lookup(float3 coords)
{
    #if defined(PCF_VALUE) && defined(PCF_MULT_VALUE)
    float y;
    float x;
    float sum;
    float2 offset;
    for (y = -0.5 * PCF_VALUE; y <= 0.5 * PCF_VALUE; y +=1)
        for (x = -0.5 * PCF_VALUE; x <= 0.5 * PCF_VALUE; x +=1)
        {
            offset = float2(_DirectionalShadowAtlas_TexelSize.x * x, _DirectionalShadowAtlas_TexelSize.y * y);
            sum += SampleDirectionalShadowAtlas((coords + float3(offset.x,offset.y, 0)));
        }
    return sum * PCF_MULT_VALUE;

    // return sum * 1/
	
    #else
    return SampleDirectionalShadowAtlas(coords);
    #endif
}

float GetDirectionalShadowAttenuation (
    DirectionalShadowData directional, ShadowData global, SurfaceData surfaceData
) {
    // #if !defined(_RECEIVE_SHADOWS)
    //     return 1.0;
    // #endif
    if (directional.strength <= 0.0) {
        return 1.0;
    }
    float3 normalBias = surfaceData.normal * (directional.normalBias * _CascadeData[global.cascadeIndex].y);
    float3 positionSTS = mul(_DirectionalShadowMatrices[global.cascadeIndex], float4(surfaceData.positionWS + normalBias, 1.0)).xyz;

    float shadow = offset_lookup(positionSTS);

    return lerp(1.0, shadow, directional.strength);
}

#endif