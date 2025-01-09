using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
    public class Decals
    {
        private const string BUFFER_NAME = "Decals";
        

        public void Render()
        {

            RAPI.BeginSample(BUFFER_NAME);
            
           
            RAPI.ExecuteBuffer();

            RenderTargetIdentifier[] colorTargets = {
                new RenderTargetIdentifier(SProps.GBuffer.G_AlbedoAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.G_NormalWorldSpaceAtlas),
                new RenderTargetIdentifier(SProps.GBuffer.G_BRDFAtlas)
            };

            RAPI.Buffer.SetRenderTarget(colorTargets, SProps.Common.DepthBuffer);
            // RAPI.Buffer.ClearRenderTarget(true, true, Color.clear);
            // RAPI.Buffer.ClearRenderTarget((RTClearFlags)( (int)RTClearFlags.Depth), Color.green, 1.0f, 0xF0);
            RAPI.ExecuteBuffer();
            
            var sortingSettings = new SortingSettings(RAPI.CurCamera)
            {
                criteria = SortingCriteria.CommonTransparent
            };
            var drawingSettings = new DrawingSettings(SProps.Decals.DecalsPassId, sortingSettings)
            {
                enableDynamicBatching = false,
                enableInstancing = RAPI.assetSettings.useGPUInstancing,
            };
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

            RAPI.Context.DrawRenderers(RAPI.CullingResults, ref drawingSettings, ref filteringSettings);
            
            
            RAPI.EndSample(BUFFER_NAME);
            // RAPI.Buffer.EndSample("decal");
            // RAPI.ExecuteBuffer();
            
            
            
        }
       
    }
}
