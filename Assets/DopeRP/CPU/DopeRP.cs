using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
	public class DopeRP : RenderPipeline
	{
		global::DopeRP.CPU.CameraRenderer renderer = new global::DopeRP.CPU.CameraRenderer();
		

		private DopeRPAsset m_assetSettings;

		public DopeRP (DopeRPAsset assetSettings) {
			// GraphicsSettings.useScriptableRenderPipelineBatching = true;
			// GraphicsSettings.lightsUseLinearIntensity = true;
			m_assetSettings = assetSettings;
			// this.useDynamicBatching = useDynamicBatching;
			// this.useGPUInstancing = useGPUInstancing;
			GraphicsSettings.useScriptableRenderPipelineBatching = assetSettings.useSRPBatcher;
			GraphicsSettings.lightsUseLinearIntensity = true;
		}

		protected override void Render(ScriptableRenderContext context, Camera[] cameras)
		{
			RAPI.Context = context;
			for (int i = 0; i < cameras.Length; i++) {
				renderer.Render(cameras[i], m_assetSettings);
			}
		}
	}
}