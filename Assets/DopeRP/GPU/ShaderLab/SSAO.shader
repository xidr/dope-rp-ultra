Shader "DopeRP/Shaders/SSAO"
{
	Properties
	{
		_NoiseTexture("Noise texture", 2D) = "white" {}
		_RandomSize("Random size", Range(0, 128)) = 64
		_SampleRadius ("Sample Radius", Range(0, 5)) = 0.6
		_Bias ("Bias", Range(0, 5)) = 0.005
		_Magnitude ("Magnitude", Range(0, 2)) = 1.1
		_Contrast ("Magnitude", Range(0, 2)) = 1
	}

	SubShader
	{
		
		Pass {
			Name "SSAORawPass"
			Tags {
				"LightMode" = "SSAORawPass"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma multi_compile_instancing
			// #pragma enable_d3d11_debug_symbols
			#pragma multi_compile _SAMPLES_COUNT16 _SAMPLES_COUNT32 _SAMPLES_COUNT64 
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/DopeRP/GPU/HLSL/SSAORawPass.hlsl"
			ENDHLSL
		}

		Pass {
			Name "SSAOBlurPass"
			Tags {
				"LightMode" = "SSAOBlurPass"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma multi_compile_instancing
			// #pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/DopeRP/GPU/HLSL/SSAOBlurPass.hlsl"
			ENDHLSL
		}


	}
}