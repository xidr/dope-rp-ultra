Shader "DopeRP/Shaders/LitDeferred"
{
	Properties
	{

		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1

	}

	SubShader
	{
		Pass
		{
			Name "Lit_Deferred"
			Tags {
				"LightMode" = "Lit_Deferred"
			}

//			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			
			

			HLSLPROGRAM

			
			#pragma target 3.5
			// #pragma enable_d3d11_debug_symbols
			#pragma multi_compile_instancing
			
			#pragma multi_compile _ _DIR_LIGHT_ON
			#pragma multi_compile _ _OTHER_LIGHT_COUNT_60 _OTHER_LIGHT_COUNT_50 _OTHER_LIGHT_COUNT_40 _OTHER_LIGHT_COUNT_30 _OTHER_LIGHT_COUNT_20 _OTHER_LIGHT_COUNT_10
			
			#pragma multi_compile _ SHADOWS_ON
			#pragma multi_compile _ _DIRECTIONAL_PCF_NONE _DIRECTIONAL_PCF2x2 _DIRECTIONAL_PCF4x4 _DIRECTIONAL_PCF6x6 _DIRECTIONAL_PCF8x8
			#pragma multi_compile _ CASCADE_COUNT_2 CASCADE_COUNT_4
			#pragma multi_compile _ AMBIENT_LIGHT_ON
			
			#pragma multi_compile _ SSAO_ON
			#pragma multi_compile _ DECALS_ON
			
			#pragma shader_feature _PREMULTIPLY_ALPHA
			// #pragma shader_feature _RECEIVE_SHADOWS
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/DopeRP/GPU/HLSL/LitDeferredPass.hlsl"
			ENDHLSL
		}

		
	}

}