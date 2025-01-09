using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
    public class GBuffers
    {
        private const string BUFFER_NAME = "GBuffer";
        
        
        public void Render()
        {
            RAPI.BeginSample(BUFFER_NAME);

            
            RAPI.ExecuteBuffer();
            
            var cameraWidth = RAPI.CurCamera.pixelWidth;
            var cameraHeight = RAPI.CurCamera.pixelHeight;

            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.GAux_TangentWorldSpaceAtlas, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.GAux_WorldSpaceAtlas, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
            
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.G_AlbedoAtlas, cameraWidth, cameraHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.G_NormalWorldSpaceAtlas, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.GAux_ClearNormalWorldSpaceAtlas, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.G_SpecularAtlas, cameraWidth, cameraHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            RAPI.Buffer.GetTemporaryRT(SProps.GBuffer.G_BRDFAtlas, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
            
            RenderTargetIdentifier[] colorTargets = {
                new RenderTargetIdentifier(SProps.GBuffer.GAux_TangentWorldSpaceAtlas),
                
                new RenderTargetIdentifier(SProps.GBuffer.G_AlbedoAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.G_NormalWorldSpaceAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.GAux_ClearNormalWorldSpaceAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.G_SpecularAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.G_BRDFAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.GAux_WorldSpaceAtlas),
            };
            RAPI.Buffer.SetRenderTarget(colorTargets, SProps.Common.DepthBuffer);
            RAPI.Buffer.ClearRenderTarget(false, true, Color.clear);

            RAPI.ExecuteBuffer();

            var sortingSettings = new SortingSettings(RAPI.CurCamera)
            {
                criteria = SortingCriteria.CommonOpaque
            };

            var drawingSettings = new DrawingSettings(SProps.GBuffer.GBufferPassId, sortingSettings)
            {
                enableDynamicBatching = RAPI.assetSettings.useDynamicBatching,
                enableInstancing = RAPI.assetSettings.useGPUInstancing,
                perObjectData =
                PerObjectData.ReflectionProbes |
                PerObjectData.Lightmaps | PerObjectData.ShadowMask |
                PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
                PerObjectData.LightProbeProxyVolume |
                PerObjectData.OcclusionProbeProxyVolume
            };
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

            RAPI.Context.DrawRenderers(RAPI.CullingResults, ref drawingSettings, ref filteringSettings);

            RAPI.ExecuteBuffer();

            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.GAux_TangentWorldSpaceAtlas, SProps.GBuffer.GAux_TangentWorldSpaceAtlas);
            
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.G_AlbedoAtlas, SProps.GBuffer.G_AlbedoAtlas);
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.G_NormalWorldSpaceAtlas, SProps.GBuffer.G_NormalWorldSpaceAtlas);
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.GAux_ClearNormalWorldSpaceAtlas, SProps.GBuffer.GAux_ClearNormalWorldSpaceAtlas);
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.G_SpecularAtlas, SProps.GBuffer.G_SpecularAtlas);
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.G_BRDFAtlas, SProps.GBuffer.G_BRDFAtlas);
            RAPI.Buffer.SetGlobalTexture(SProps.GBuffer.GAux_WorldSpaceAtlas, SProps.GBuffer.GAux_WorldSpaceAtlas);
            
            RAPI.ExecuteBuffer();

            
            RAPI.EndSample(BUFFER_NAME);

        }
        
    }
}