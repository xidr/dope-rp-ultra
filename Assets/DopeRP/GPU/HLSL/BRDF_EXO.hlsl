#ifndef BRDF_EXO_INCLUDED
#define BRDF_EXO_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"
#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"
#include "Assets/DopeRP/GPU/HLSL/Lighting.hlsl"


// Normal Distribution Function
// GGX by Trowbridge & Reitz
float ggxDistrib(SurfaceData surfaceData, float NoH)
{
    float alpha4 = pow4(surfaceData.roughness);
    float d = pow2(NoH) * (alpha4 - 1.0) + 1.0;
    float ggxdistrib = alpha4 / (PI * pow2(d));
    return ggxdistrib;
}

// Geometry Function
// Schlick-GGX by Schlick & Beckmann
float geomSmith(SurfaceData surfaceData, float dp)
{
    float k = pow2(surfaceData.roughness + 1.0) / 8.0;
    float denom = dp * (1 - k) + k;
    float geomsmith = dp / denom;
    return geomsmith;
}

// Fresnel Function
// Schlick Approximation
float3 schlickFresnel(SurfaceData surfaceData, float VoH)
{
    float3 F0 = float3(0.04, 0.04, 0.04) * when_eq(surfaceData.isMetal, false)
    + surfaceData.color * when_eq(surfaceData.isMetal, true);

    float3 ret = F0 + (1.0 - F0) * pow5(clamp(1.0 - VoH, 0.0, 1.1));

    return ret;
}


// float3 diffuseBRDF(float kD, float3 fLambert)
// {
//     return kD * fLambert / PI;
// }
//
// float3 specularBRDF(SurfaceData surfaceData, float3 normal, float3 lightDir, float3 viewDir)
// {
//     float D = ggxDistrib(surfaceData, halfDir);
//     float G = geomSmith(surfaceData, dot(normal, viewDir)) * geomSmith(surfaceData, dot(normal, lightDir));
//     
// }

float3 finalBRDF(SurfaceData surfaceData, Light lightData)
{
    // float3 lightIntensity = lightData.color * lightData.attenuation;
    float3 h = normalize(surfaceData.viewDirection + lightData.direction);

    float NoV = clampNoV(dot(surfaceData.normal, surfaceData.viewDirection));
    float NoL = saturate(dot(surfaceData.normal, lightData.direction));
    float NoH = saturate(dot(surfaceData.normal, h));
    float LoH = saturate(dot(lightData.direction, h));
    float VoH = saturate(dot(surfaceData.viewDirection, h));

    float3 F = schlickFresnel(surfaceData, VoH);

    float3 kS = F;
    float3 kD = 1.0 - kS;

    float D = ggxDistrib(surfaceData, NoH);
    float G = geomSmith(surfaceData, dot(surfaceData.normal, surfaceData.viewDirection))
    * geomSmith(surfaceData, dot(surfaceData.normal, surfaceData.viewDirection));

    float3 SpecBRDF_nom = D * G * F;

    float SpecBRDF_denom = 4.0 * NoV * NoL + 0.0001;

    float3 SpecBRDF = SpecBRDF_nom / SpecBRDF_denom; 
    
    // Diffuse part, only for dielectrics
    float3 fLambert = surfaceData.color * when_eq(surfaceData.isMetal, false);
    float3 DiffuseBRDF = kD * fLambert / PI;

    float3 FinalColor = (DiffuseBRDF + SpecBRDF) * lightData.color * lightData.attenuation * NoL;

    return FinalColor;
}




#endif
