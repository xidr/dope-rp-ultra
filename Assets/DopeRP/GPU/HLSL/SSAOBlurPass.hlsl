#ifndef SSAO_PASS2_BLUR_INCLUDED
#define SSAO_PASS2_BLUR_INCLUDED

#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"

#define ITER_COUNT 2

TEXTURE2D(_SSAORawAtlas);
SAMPLER(sampler_SSAORawAtlas);


CBUFFER_START(SSAOBlur)

    float4 _ScreenSize;

CBUFFER_END


struct MeshData
{
    float4 position : POSITION;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 positionSV : SV_POSITION;
    float2 uv : TEXCOORD0;
};


Interpolators vert (MeshData i)
{
    Interpolators o;
    o.uv = i.uv;
    o.positionSV = TransformObjectToHClip(i.position);
    return o;
}


float4 frag (Interpolators i) : SV_Target
{
    
    float result = 0;
    
    UNITY_UNROLL
    for (int x = -ITER_COUNT; x < ITER_COUNT; ++x) 
    {
        UNITY_UNROLL
        for (int y = -ITER_COUNT; y < ITER_COUNT; ++y) 
        {
            float2 offset = float2(float(x), float(y)) * _ScreenSize.zw;
            result += SAMPLE_TEXTURE2D(_SSAORawAtlas, sampler_SSAORawAtlas, i.uv + offset).r;
        }
    }
    
    float4 FragColor = result / (pow4(ITER_COUNT));
    return FragColor;
    // return SAMPLE_TEXTURE2D(_SSAORawAtlas, sampler_SSAORawAtlas, i.uv);
    
}

#endif