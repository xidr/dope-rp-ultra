Shader "DopeRP/Shaders/Lit"
{
	Properties
	{
		_AlbedoMap("Albedo Map", 2D) = "white" {}
//		[Toggle(_ACT_AS_OPACITY)] _ActAsOpacity ("Act as Opacity", Float) = 0
		_BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[Toggle(_ADD_COLOR)] _AddColor ("Additive Color", Float) = 0
		
		[Toggle(_USE_DETAILS_ALBEDO_MAP)] _UseDetails ("Use details albedo map", Float) = 0
		_AlbedoDetailsMap("Albedo Details Map", 2D) = "white" {}
		_DetailsColor("Details Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[Toggle(_R_CUTOUT)] _RCutout ("R Cutout for details (notalpha)", Float) = 0

		[NoScaleOffset] _NormalMap("Normal Map", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 1)) = 1
		
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Roughness ("Roughness", Range(0, 1)) = 0.5
		_Reflectance ("Reflectance", Range(0, 1)) = 0.5
		[Enum(Off, 0, On, 1)] _IsMetal ("Is Metal", Float) = 0
		
		[Toggle(_USE_EMISSION)] _UseEmission ("Use Emission", Float) = 0
		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
//		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)
		_EmissionScale ("Emission scale", Range(0, 10)) = 1
		
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
		
		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha ("Premultiply Alpha", Float) = 0
//		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
		
//		_DepthLevel ("Depth Level", Range(1, 3)) = 1
		
		[InRange] _StencilID ("Stencil ID", Range(0, 255)) = 0
		
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
		
		
		
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompare ("Stencil Comparison", Float) = 8
		
		[Enum(UnityEngine.Rendering.CullMode)] _CullingMode2 ("Culling Mode", Float) = 2
		
//[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Float) = 0
//[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Float) = 0
		
//		[KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
		
		[Toggle(_SHADOWS_CLIP)] _ShadowsClip ("Shadows alpha Clipping", Float) = 0


		

	}

	SubShader
	{
		Pass
		{
			Tags {
				"LightMode" = "Lit"
			}

			Blend [_SrcBlend] [_DstBlend]
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
									#pragma shader_feature _USE_EMISSION

			
			#pragma shader_feature _PREMULTIPLY_ALPHA
						#pragma shader_feature _CLIPPING
						#pragma shader_feature _ADD_COLOR
									// #pragma shader_feature _ACT_AS_OPACITY
			#pragma shader_feature _USE_DETAILS_ALBEDO_MAP
			#pragma shader_feature _R_CUTOUT



			// #pragma shader_feature _RECEIVE_SHADOWS
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/DopeRP/GPU/HLSL/LitPass.hlsl"
			ENDHLSL
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _SHADOWS_CLIP
			#pragma multi_compile_instancing
			// #pragma enable_d3d11_debug_symbols
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "Assets/DopeRP/GPU/HLSL/ShadowCasterPass.hlsl"
			ENDHLSL
		}

		Pass {
			Name "GBufferPass"
			Tags {
				"LightMode" = "GBufferPass"
			}
			
			Stencil
			{
				ref [_StencilID]
				Comp [_StencilCompare]
				Pass [_StencilOp]
				Fail [_StencilOp]
				
			}
			
						Cull [_CullingMode2]

			
			HLSLPROGRAM


			#pragma target 3.5
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			// #pragma shader_feature _STENCIL_MASK
			#pragma shader_feature _ADD_COLOR
			// #pragma shader_feature _ACT_AS_OPACITY
						#pragma shader_feature _USE_DETAILS_ALBEDO_MAP
			#pragma shader_feature _R_CUTOUT
						#pragma shader_feature _USE_EMISSION

			// #pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			#include "Assets/DopeRP/GPU/HLSL/GBufferPass.hlsl"
			ENDHLSL
		}
		
	}

}