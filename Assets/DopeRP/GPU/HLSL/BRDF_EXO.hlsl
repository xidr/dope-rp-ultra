#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/SurfaceData.hlsl"
#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"



float3 DiffuseBRDF(float kD, float3 fLambert)
{
    return kD * fLambert / PI;
}


#endif
