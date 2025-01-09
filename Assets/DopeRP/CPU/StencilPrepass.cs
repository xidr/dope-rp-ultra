using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
    public class StencilPrepass
    {
        private const string BUFFER_NAME = "StencilPrePass";
        
        
        public void Render()
        {
            
            RAPI.BeginSample(BUFFER_NAME);
            
            
            var cameraWidth = RAPI.CurCamera.pixelWidth;
            var cameraHeight = RAPI.CurCamera.pixelHeight;

            RAPI.Buffer.GetTemporaryRT(SProps.Common.ColorFiller, cameraWidth, cameraHeight, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);
            RAPI.Buffer.GetTemporaryRT(SProps.Common.DepthBuffer, cameraWidth, cameraHeight, 32, FilterMode.Bilinear, RenderTextureFormat.Depth);

            RenderTargetIdentifier[] colorTargets =
            {
                new RenderTargetIdentifier(SProps.Common.ColorFiller),
            };
                
            RAPI.Buffer.SetRenderTarget(colorTargets, SProps.Common.DepthBuffer);
            RAPI.Buffer.ClearRenderTarget(true, true, Color.clear);
            
            RAPI.ExecuteBuffer();

            var sortingSettings = new SortingSettings(RAPI.CurCamera)
            {
                criteria = SortingCriteria.CommonTransparent
            };

            var drawingSettings = new DrawingSettings(SProps.Common.StencilPrePassId, sortingSettings)
            {
                enableDynamicBatching = RAPI.assetSettings.useDynamicBatching,
                enableInstancing = RAPI.assetSettings.useGPUInstancing,
            };
            
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

            RAPI.Context.DrawRenderers(RAPI.CullingResults, ref drawingSettings, ref filteringSettings);
            
            RAPI.ExecuteBuffer();
            
            
            RAPI.EndSample(BUFFER_NAME);

        }
        
    }
}