using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using LightType = UnityEngine.LightType;

namespace DopeRP.CPU
{
	[CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
	public class DopeRPAsset : RenderPipelineAsset
	{
		public static DopeRPAsset instance;

		[Header("General RP settings")]
		public bool samplingOn;
		public bool useDynamicBatching = true;
		public bool useGPUInstancing = true;
		public bool useSRPBatcher = true;
		
		[Header("Lighting")]
		public Material LitDeferredMaterial;
		public bool ambientLightOn;
		[Range(0, 0.2f)]
		public float ambientLightScale;
		[OnChangedCall("onPropertyChangeMain")]
		[Range(0, 1f)]
		public float mainDirLightStrength;
		[Header("(Just so unity don't create a new material each render call)")]
		[SerializeField] private ShadowSettings m_shadowsSettings = default;
		public ShadowSettings shadowSettings => m_shadowsSettings;
		
		[Header("SSAO")]
		[SerializeField] 
		private bool m_SSAO;
		public bool SSAO => m_SSAO;
		[SerializeField] 
		private SSAOSettings ssaoSettings;
		public SSAOSettings SSAOSettings => ssaoSettings;
		
		[Header("Decals")]
		[SerializeField] 
		private bool m_decalsOn;
		public bool decalsOn => m_decalsOn;
		
		[Header("PostFX")]
		[SerializeField] 
		private bool m_postFXOn;
		public bool postFXOn => m_postFXOn;
		[SerializeField]
		private PostFXSettings m_postFXSettings = default;
		public PostFXSettings postFXSettings => m_postFXSettings;
		

		
		protected override RenderPipeline CreatePipeline () {
			instance = this;
			return new DopeRP(this);
			
		}
		
		// ---------------------------
		public void onPropertyChangeSSAOSettings()
		{
			Material ssaoMaterial = ssaoSettings.SSAOMaterial;
			ssaoMaterial.SetTexture(SProps.SSAO.NoiseTexture, ssaoSettings.noiseTexture);
			ssaoMaterial.SetFloat(SProps.SSAO.RandomSize, ssaoSettings.randomSize);
			ssaoMaterial.SetFloat(SProps.SSAO.SampleRadius, ssaoSettings.sampleRadius);
			ssaoMaterial.SetFloat(SProps.SSAO.Bias, ssaoSettings.bias);
			ssaoMaterial.SetFloat(SProps.SSAO.Magnitude, ssaoSettings.magnitude);
			ssaoMaterial.SetFloat(SProps.SSAO.Contrast, ssaoSettings.contrast);
		}
		
		public void onPropertyChangeMain()
		{
			var lights = FindObjectsOfType<Light>();
			foreach (var light in lights)
			{
				if (light.type == LightType.Directional)
				{
					light.shadowStrength = mainDirLightStrength;
					return;
				}
			}
		}
	}
}