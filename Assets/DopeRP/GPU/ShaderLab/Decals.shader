Shader "DopeRP/Shaders/Decals"
{
	Properties
	{
		
		[Toggle(_CONTRIBUTE_ALBEDO)] _ContributeAlbedo ("Contribute Albedo", Float) = 0
		_BaseMap("Albedo Texture", 2D) = "(0,0,0,0)" {}
		_BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[Toggle(_ADD_COLOR)] _AddColor ("Additive Color", Float) = 0
		
		[Toggle(_OPACITY_ATLAS)] _OpacityAtlas ("Opacity as texture", Float) = 0
		[NoScaleOffset] _OpacityMap("Albedo Texture", 2D) = "(0,0,0,0)" {}
		_Cutoff ("Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_R_CUTOUT)] _RCutout ("R Cutout for details (notalpha)", Float) = 1

		[Toggle(_CONTRIBUTE_NORMAL)] _ContributeNormals ("Contribute Normals", Float) = 0
		[NoScaleOffset] _NormalMap("Normal Texture", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 1)) = 1
		
		[Toggle(_CONTRIBUTE_BRDF)] _ContributeBRDF ("Contribute BRDF", Float) = 0
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Roughness ("Roughness", Range(0, 1)) = 0.5
		_Reflectance ("Reflectance", Range(0, 1)) = 0.5

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		
//		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
		
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
		
		[InRange] _StencilID ("Stencil ID", Range(0, 255)) = 0
		[InRange] _StencilReadMask ("Stencil Readmask", Range(0, 255)) = 0

		
	}

	SubShader
	{

		Pass {
			Name "DecalsPass"
			Tags {
				"LightMode" = "DecalsPass"
			}
			
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Front
			ZTest Off

			Stencil {
				Ref  [_StencilID]
				Comp Equal
				ReadMask [_StencilReadMask]
			}
			
			HLSLPROGRAM
			#pragma target 3.5
			#pragma multi_compile_instancing
			// #pragma enable_d3d11_debug_symbols
			// #pragma shader_feature _CLIPPING
			#pragma shader_feature _CONTRIBUTE_ALBEDO
			#pragma shader_feature _ADD_COLOR
			#pragma shader_feature _OPACITY_ATLAS
			#pragma shader_feature _R_CUTOUT
			#pragma shader_feature _CONTRIBUTE_NORMAL
			#pragma shader_feature _CONTRIBUTE_BRDF
			


			#pragma vertex vert
			#pragma fragment frag

			#include "Assets/DopeRP/GPU/HLSL/Common/Common.hlsl"

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			TEXTURE2D(_OpacityMap);
			SAMPLER(sampler_OpacityMap);

			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);
			

			#if !UNITY_REVERSED_Z
			
				TEXTURE2D(_DepthBuffer);
				SAMPLER(sampler_DepthBuffer);
			
			#else
			
				TEXTURE2D(_GAux_WorldSpaceAtlas);
				SAMPLER(sampler_GAux_WorldSpaceAtlas);

			#endif
			

			TEXTURE2D(_GAux_ClearNormalWorldSpaceAtlas);
			SAMPLER(sampler_GAux_ClearNormalWorldSpaceAtlas);

			TEXTURE2D(_GAux_TangentWorldSpaceAtlas);
			SAMPLER(sampler_GAux_TangentWorldSpaceAtlas);

			TEXTURE2D(_G_BRDFAtlas);
			SAMPLER(sampler_G_BRDFAtlas);

			
			CBUFFER_START(Decals)
			
				float4 _ScreenSize;
				float2 _NearFarPlanes;
			
				float4x4 _Matrix_I_P;
			    float4x4 _Matrix_P;
			
			CBUFFER_END
			

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial_DECALS)
			
				UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
				UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)

				UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
    			UNITY_DEFINE_INSTANCED_PROP(float, _Reflectance)	

			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial_DECALS)

			struct MeshData {
				float4 position : POSITION;
			    float3 normal   : NORMAL;
				float2 uv   : TEXCOORD0;
				float4 tangentOS : TANGENT;
				
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Interpolators {
			    float4 positionSV : SV_POSITION;
			    float3 positionVS   : TEXCOORD0;
			    float3 normalVS   : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float2 uv   : TEXCOORD3;
				float4 tangentWS : VAR_TANGENT;
				
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Interpolators vert(MeshData i)
			{
			    UNITY_SETUP_INSTANCE_ID(i);
			    Interpolators o;
			    UNITY_TRANSFER_INSTANCE_ID(i, o);
			   
			    o.positionSV = TransformObjectToHClip(i.position);
			    o.positionVS = TransformWorldToView(TransformObjectToWorld(i.position));
			    o.normalVS = TransformWorldToViewNormal(TransformObjectToWorldNormal(i.normal));

				o.positionWS = TransformObjectToWorld(i.position);

				o.uv = i.uv;

				o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);
			    return o;
			}
			

			float3 GetNormalTS (float2 baseUV) {
				float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, baseUV);
				float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _NormalScale);
				float3 normal = DecodeNormal(map, scale);
				return normal;
			}

			
			struct fragOutput
			{
			    float4 decalsArtisticAlbedoAtlas : SV_Target0;
			    float4 decalsArtisticNormalAtlas : SV_Target1;
				float4 decalsArtisticBRDFAtlas : SV_Target2;
			};
			
			fragOutput frag(Interpolators i)
			{
				
				UNITY_SETUP_INSTANCE_ID(i);
				fragOutput o;

				float2 screenUV = i.positionSV.xy * _ScreenSize.zw;
				float4 worldPos;
				
				#if !UNITY_REVERSED_Z
				float depth = SAMPLE_TEXTURE2D(_DepthBuffer, sampler_DepthBuffer, screenUV).r;
				float4 clipSpacePosition;
				float4 viewSpacePosition;
				// #if !UNITY_REVERSED_Z
					depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
				
					float sceneZ =CalcLinearZ(depth, _NearFarPlanes.x, _NearFarPlanes.y);
					clipSpacePosition = float4((screenUV * 2.0 - 1.0) * sceneZ/depth, sceneZ, 1.0 * sceneZ/depth);
					viewSpacePosition = mul(_Matrix_I_P, clipSpacePosition);
					viewSpacePosition /= viewSpacePosition.w;
				
				// #else
				//
				// 	clipSpacePosition = float4(screenUV * 2 - 1, depth, 1);
				// 	viewSpacePosition = mul(Inverse(_Matrix_P), clipSpacePosition);
				// 	viewSpacePosition /= viewSpacePosition.w;
				
				// #endif
				
				worldPos = float4(TransformViewToWorld(viewSpacePosition.xyz),1);
									o.decalsArtisticAlbedoAtlas = 0;


				#else

					worldPos = SAMPLE_TEXTURE2D(_GAux_WorldSpaceAtlas, sampler_GAux_WorldSpaceAtlas, screenUV);
					o.decalsArtisticAlbedoAtlas = 0;
				// o.decalsArtisticAlbedoAtlas = worldPos;
				// return o;
				#endif
				// o.decalsArtisticAlbedoAtlas = worldPos;
				float4 objectPos = float4(TransformWorldToObject(worldPos), 1);
				// return o;
				clip(0.5 - abs(objectPos.xyz));
				
				float4 baseMap_ST =  UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _BaseMap_ST);
				float2 texCoords = (objectPos.xy + 0.5) * baseMap_ST.xy + baseMap_ST.zw;
				#if defined(_OPACITY_ATLAS)

					#if defined(_R_CUTOUT)
						clip(SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, texCoords).r - UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Cutoff));

					#else
				
						clip(SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, texCoords).a - UNITY_ACCESS_INSTANCED_PROP(LitBasePerMaterial, _Cutoff));

					#endif
				
				#endif
				
				
				#if defined(_CONTRIBUTE_NORMAL)
				
					float3 normalWS = normalize(SAMPLE_TEXTURE2D(_GAux_ClearNormalWorldSpaceAtlas, sampler_GAux_ClearNormalWorldSpaceAtlas, screenUV).xyz);
					float4 tangentWS = normalize(SAMPLE_TEXTURE2D(_GAux_TangentWorldSpaceAtlas, sampler_GAux_TangentWorldSpaceAtlas, screenUV));
				
					o.decalsArtisticNormalAtlas = float4(NormalTangentToWorld(GetNormalTS(texCoords), normalWS, tangentWS),1) ;
				
				#else
				
					// o.decalsArtisticNormalAtlas = 0;
				
				#endif
				
				
				#if defined(_CONTRIBUTE_ALBEDO)
				
					float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, texCoords);
				
					#if defined(_ADD_COLOR)
    
						baseColor += UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _BaseColor);

					#else
    
						baseColor *= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _BaseColor);

					#endif
				
					o.decalsArtisticAlbedoAtlas = baseColor;
				
				#endif
				
									// o.decalsArtisticAlbedoAtlas = 1;

				#if defined(_CONTRIBUTE_BRDF)
				
					float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _Metallic);
					float roughness = perceptualRoughnessToRoughness(UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _Roughness));
					float reflectance = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial_DECALS, _Reflectance);
					float4 brdf = float4(metallic, roughness, reflectance, 0);
				
					o.decalsArtisticBRDFAtlas = brdf;
				
				#endif
				
				
				return o;
				
			}
			
			ENDHLSL
		}
		
	}

}