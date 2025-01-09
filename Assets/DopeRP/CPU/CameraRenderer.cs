using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
	public partial class CameraRenderer {
		
		private const string BUFFER_NAME_MAIN = "AssembleMain";
		private const string BUFFER_NAME_TRANSPARENCY = "Transapency";


		private readonly StencilPrepass m_stencilPrepass = new StencilPrepass();
		private readonly Lighting m_lighting = new Lighting();
		private readonly GBuffers m_gBuffers = new GBuffers();
		private readonly Decals m_decals = new Decals();
		private readonly SSAO m_ssao = new SSAO();
		PostFXStack postFXStack = new PostFXStack();
		

		public void Render(Camera camera, DopeRPAsset assetSettings)
		{
			RAPI.CurCamera = camera;
			PrepareUIForSceneWindow();
			if (!RAPI.Cull(assetSettings.shadowSettings.maxDistance)) {
				return;
			}

			RAPI.assetSettings = assetSettings;
			// RAPI.Material = assetSettings.postFXSettings.Material;
			RAPI.m_samplingOn = assetSettings.samplingOn;
			RAPI.Context.SetupCameraProperties(RAPI.CurCamera);
			RAPI.SetupCommonUniforms();
			
			RAPI.CurCamera.depthTextureMode = DepthTextureMode.None;

			// if ( customRenderPipelineAsset.SSAO || customRenderPipelineAsset.decalsOn)
			m_stencilPrepass.Render();
				m_gBuffers.Render();
				// RAPI.DrawEmpty(customRenderPipelineAsset.EmptyMaterial);
				if (assetSettings.decalsOn)
				{
					// RAPI.SetKeyword("DECALS_ON", true);
					m_decals.Render();
				}
				else
				{
					// RAPI.SetKeyword("DECALS_ON", false);
				}
			if (assetSettings.SSAO)
			{
				m_ssao.Render(assetSettings.SSAOSettings);
				RAPI.SetKeyword("SSAO_ON", true);
			}
			else
			{
				RAPI.SetKeyword("SSAO_ON", false);
			}

			m_lighting.Setup(assetSettings.shadowSettings);
			postFXStack.Setup(assetSettings.postFXSettings);
			Setup();

			if (RAPI.CurCamera.cameraType == CameraType.Reflection)
			{
				DrawVisibleGeometryRefProbes();
			}
			else
			{
				DrawVisibleGeometry(assetSettings.LitDeferredMaterial);
				DrawUnsupportedShaders();
				// DrawGizmos();


				RAPI.CleanupTempRT(SProps.GBuffer.GAux_TangentWorldSpaceAtlas);
				RAPI.CleanupTempRT(SProps.SSAO.SSAORawAtlas);
				RAPI.CleanupTempRT(SProps.SSAO.SSAOBlurAtlas);
				RAPI.CleanupTempRT(SProps.Common.DepthBuffer);

				RAPI.CleanupTempRT((SProps.GBuffer.G_AlbedoAtlas));
				RAPI.CleanupTempRT((SProps.GBuffer.G_NormalWorldSpaceAtlas));
				RAPI.CleanupTempRT((SProps.GBuffer.GAux_ClearNormalWorldSpaceAtlas));
				RAPI.CleanupTempRT((SProps.GBuffer.G_SpecularAtlas));
				RAPI.CleanupTempRT((SProps.GBuffer.G_BRDFAtlas));
				RAPI.CleanupTempRT(SProps.Common.ColorFiller);
				RAPI.CleanupTempRT(SProps.GBuffer.GAux_WorldSpaceAtlas);
				
				DrawGizmosBeforeFX();
				if (postFXStack.IsActive)
				{
					postFXStack.Render(SProps.PostFX.fxSourceAtlas);
				}
				//DrawGizmosAfterFX();
				// if (postFXStack.IsActive)
				// {
				// 	RAPI.Buffer.ReleaseTemporaryRT(frameBufferId);
				// }
			}
			RAPI.CleanupTempRT(SProps.Shadows.DirShadowAtlasId);

			Submit();
		}

		void Setup () {
			RAPI.Context.SetupCameraProperties(RAPI.CurCamera);
			var flags = RAPI.CurCamera.clearFlags;
			
			if (postFXStack.IsActive) {
				if (flags > CameraClearFlags.Color) {
					flags = CameraClearFlags.Color;
				}
				// RAPI.Buffer.GetTemporaryRT(
				// 	frameBufferId, RAPI.CurCamera.pixelWidth, RAPI.CurCamera.pixelHeight,
				// 	32, FilterMode.Bilinear, RenderTextureFormat.Default
				// );
				RAPI.Buffer.SetRenderTarget(SProps.PostFX.fxSourceAtlas, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
			}
			

			
			RAPI.Buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color,
				flags == CameraClearFlags.Color ? RAPI.CurCamera.backgroundColor.linear : Color.clear);
			
			RAPI.ExecuteBuffer();
		}

		void DrawVisibleGeometry (Material litDeferredMaterial)
		{
			
			var sortingSettings = new SortingSettings(RAPI.CurCamera)
			{
				criteria = SortingCriteria.CommonOpaque
			};
			
			var drawingSettings = new DrawingSettings(SProps.CameraRenderer.UnlitShaderTagId, sortingSettings)
			{
				// enableDynamicBatching = useDynamicBatching,
				enableInstancing = RAPI.assetSettings.useGPUInstancing,
				enableDynamicBatching = RAPI.assetSettings.useDynamicBatching,
				perObjectData =
					PerObjectData.ReflectionProbes |
					PerObjectData.Lightmaps | PerObjectData.ShadowMask |
					PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
					PerObjectData.LightProbeProxyVolume |
					PerObjectData.OcclusionProbeProxyVolume
			};
			
			var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
			
			RAPI.Context.DrawRenderers(RAPI.CullingResults, ref drawingSettings, ref filteringSettings);

			RAPI.Context.DrawSkybox(RAPI.CurCamera);

			
			RAPI.BeginSample(BUFFER_NAME_MAIN);
			
			RAPI.DrawFullscreenQuad(litDeferredMaterial, litDeferredMaterial.FindPass(SProps.CameraRenderer.LitDeferredPassName));
			RAPI.Buffer.SetViewProjectionMatrices(RAPI.CurCamera.worldToCameraMatrix, RAPI.CurCamera.projectionMatrix);

			RAPI.EndSample(BUFFER_NAME_MAIN);

			RAPI.ExecuteBuffer();
			
			if(postFXStack.IsActive)
				RAPI.Buffer.SetRenderTarget(SProps.PostFX.fxSourceAtlas, new RenderTargetIdentifier(SProps.Common.DepthBuffer));
			else
				RAPI.Buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, new RenderTargetIdentifier(SProps.Common.DepthBuffer));
			RAPI.ExecuteBuffer();
			
			RAPI.BeginSample(BUFFER_NAME_TRANSPARENCY);
				
			//Draw transparent geometry
			drawingSettings.SetShaderPassName(1, SProps.CameraRenderer.LitShaderTagId);

			sortingSettings.criteria = SortingCriteria.CommonTransparent;
			drawingSettings.sortingSettings = sortingSettings;
			filteringSettings.renderQueueRange = RenderQueueRange.transparent;
			RAPI.Context.DrawRenderers(RAPI.CullingResults, ref drawingSettings, ref filteringSettings);
			
			RAPI.EndSample(BUFFER_NAME_TRANSPARENCY);
			
		}
		
				
		void DrawVisibleGeometryRefProbes () {

			var sortingSettings = new SortingSettings(RAPI.CurCamera) {
				criteria = SortingCriteria.CommonOpaque
			};
			var drawingSettings = new DrawingSettings(
				SProps.CameraRenderer.UnlitShaderTagId, sortingSettings
			) {
				// enableDynamicBatching = useDynamicBatching,
				enableInstancing = RAPI.assetSettings.useGPUInstancing,
				enableDynamicBatching = RAPI.assetSettings.useDynamicBatching,
				perObjectData =
					PerObjectData.ReflectionProbes |
					PerObjectData.Lightmaps | PerObjectData.ShadowMask |
					PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
					PerObjectData.LightProbeProxyVolume |
					PerObjectData.OcclusionProbeProxyVolume
					
			};
			drawingSettings.SetShaderPassName(1, SProps.CameraRenderer.LitShaderTagId);

			var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

			RAPI.Context.DrawRenderers(
				RAPI.CullingResults, ref drawingSettings, ref filteringSettings
			);

			RAPI.Context.DrawSkybox(RAPI.CurCamera);

			sortingSettings.criteria = SortingCriteria.CommonTransparent;
			drawingSettings.sortingSettings = sortingSettings;
			filteringSettings.renderQueueRange = RenderQueueRange.transparent;

			RAPI.Context.DrawRenderers(
				RAPI.CullingResults, ref drawingSettings, ref filteringSettings
			);
		}

		void Submit () {
			RAPI.ExecuteBuffer();
			RAPI.Context.Submit();
		}
		
	}
	
}