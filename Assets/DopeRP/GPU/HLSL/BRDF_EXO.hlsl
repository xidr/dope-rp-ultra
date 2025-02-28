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
float3 schlickFresnel(float3 F0, float HoV)
{
    return F0 + (1.0 - F0) * pow5(1.0 - HoV);
}



float3 finalBRDF(SurfaceData surfaceData, Light lightData)
{
    float3 h = normalize(surfaceData.viewDirection + lightData.direction);
    float NoV = saturate(dot(surfaceData.normal, surfaceData.viewDirection));
    float NoL = saturate(dot(surfaceData.normal, lightData.direction));
    float NoH = saturate(dot(surfaceData.normal, h));
    float LoH = saturate(dot(lightData.direction, h));
    float VoH = saturate(dot(surfaceData.viewDirection, h));
    float HoV = saturate(dot(h, surfaceData.viewDirection));

    float3 F0 = lerp(float3(0.04, 0.04, 0.04), pow(surfaceData.color, float3(2.2, 2.2, 2.2)), surfaceData.metallic);

    float D = ggxDistrib(surfaceData, NoH);
    float G = geomSmith(surfaceData, NoL)
    * geomSmith(surfaceData, NoV);
    float3 F = schlickFresnel(F0, HoV);

    // float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - F;
    kD *= float3(1.0, 1.0, 1.0) - surfaceData.metallic;
    
    float3 SpecBRDF_nom = D * G * F;
    float SpecBRDF_denom = 4.0 * NoV * NoL;
    float3 SpecBRDF = SpecBRDF_nom / max(SpecBRDF_denom, 0.0001); 
    
    float3 DiffuseBRDF = kD * pow(surfaceData.color, 2.2) / PI;
    
    float3 FinalColor = (DiffuseBRDF + SpecBRDF) * lightData.color * lightData.attenuation * NoL;

    return FinalColor;
}




#endif
