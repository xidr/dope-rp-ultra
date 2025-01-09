using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
	public class Lighting
	{
		private const string BUFFER_NAME = "Lighting";

		private const int MAX_DIR_LIGHT_COUNT = 1;
		private const int MAX_OTHER_LIGHT_COUNT = 60;
		

		// Dir light

		private static Vector4 DirLightDirection = new Vector4();
		private static Vector4 DirLightColor = new Vector4();
		private static Vector4 DirLightShadowData = new Vector4();
		
		// ---
		
		// Point lights
		
		private static Vector4[] OtherLightPositions = new Vector4[MAX_OTHER_LIGHT_COUNT];
		private static Vector4[] OtherLightColors = new Vector4[MAX_OTHER_LIGHT_COUNT];
		private static Vector4[] OtherLightDirections = new Vector4[MAX_OTHER_LIGHT_COUNT];
		private static Vector4[] OtherLightSpotAngles = new Vector4[MAX_OTHER_LIGHT_COUNT];
		
		// ---
		
		private Shadows m_shadows = new Shadows();
		private bool m_shadowsOn;

		public void Setup(ShadowSettings shadowSettings)
		{
			
			if (shadowSettings.shadowsOn)
			{
				m_shadowsOn = true;
				RAPI.SetKeyword("SHADOWS_ON", m_shadowsOn);
				m_shadows.Setup(shadowSettings);
				SetupLights();
				m_shadows.Render();
			}
			else
			{
				m_shadowsOn = false;
				RAPI.SetKeyword("SHADOWS_ON", m_shadowsOn);
				SetupLights();
			}

			RAPI.Context.ExecuteCommandBuffer(RAPI.Buffer);
			RAPI.Buffer.Clear();
		}

		void SetupLights()
		{
			var visibleLights = RAPI.CullingResults.visibleLights;
			int dirLightCount = 0;
			int otherLightCount = 0;
			
			foreach (var visibleLight in visibleLights)
			{
				switch (visibleLight.lightType) {
					case LightType.Directional:
						if (dirLightCount < MAX_DIR_LIGHT_COUNT) 
						{
							SetupDirectionalLight(visibleLight);
							dirLightCount++;
						}
						break;
					case LightType.Point:
						if (otherLightCount < MAX_OTHER_LIGHT_COUNT) 
						{
							SetupPointLight(otherLightCount++, visibleLight);
						}
						break;
					case LightType.Spot:
						if (otherLightCount < MAX_OTHER_LIGHT_COUNT) 
						{
							SetupSpotLight(otherLightCount++, visibleLight);
						}
						break;
				}
			}

			if (dirLightCount == 1)
			{
				
				RAPI.SetKeyword(SProps.LightingMain.DirLightOnKeyword, true);
				RAPI.Buffer.SetGlobalVector(SProps.LightingMain.DirLightDirectionId, -DirLightDirection);
				RAPI.Buffer.SetGlobalVector(SProps.LightingMain.DirLightColorId, DirLightColor);
				if (m_shadowsOn)
					RAPI.Buffer.SetGlobalVector(SProps.LightingMain.DirLightShadowDataId, DirLightShadowData);
				
				if (RAPI.assetSettings.ambientLightOn)
				{
					RAPI.SetKeyword("AMBIENT_LIGHT_ON", true);
					RAPI.Buffer.SetGlobalFloat(SProps.CameraRenderer.AmbientLightScale, RAPI.assetSettings.ambientLightScale);
				}
				else
				{
					RAPI.SetKeyword("AMBIENT_LIGHT_ON", false);
				}
				
			}
			else
			{
				
				RAPI.SetKeyword(SProps.LightingMain.DirLightOnKeyword, false);
				
			}

			RAPI.Buffer.SetGlobalInt(SProps.LightingMain.OtherLightCountId, otherLightCount);
			if (otherLightCount > 0) {
				
				RAPI.Buffer.SetGlobalVectorArray(SProps.LightingMain.OtherLightPositionsId, OtherLightPositions);
				RAPI.Buffer.SetGlobalVectorArray(SProps.LightingMain.OtherLightColorsId, OtherLightColors);
				RAPI.Buffer.SetGlobalVectorArray(SProps.LightingMain.OtherLightDirectionsId, OtherLightDirections);
				RAPI.Buffer.SetGlobalVectorArray(SProps.LightingMain.OtherLightSpotAnglesId, OtherLightSpotAngles);
				
			}
			
			int otherLightCountDiv10 = (otherLightCount - 1) / 10;

			for (int i = 0; i <= (MAX_OTHER_LIGHT_COUNT - 1) / 10; i++)
			{
				string keyword = SProps.LightingMain.OtherLightnCountKeyword_base + (i+1) * 10;
				RAPI.SetKeyword(keyword, i == otherLightCountDiv10);
			}
			

		}

		void SetupDirectionalLight (VisibleLight visibleLight)
		{
			DirLightDirection = -visibleLight.localToWorldMatrix.GetColumn(2);
			DirLightColor = visibleLight.finalColor;
			if (m_shadowsOn)
				DirLightShadowData = m_shadows.ReserveDirectionalShadows(visibleLight.light);
		}
		
		void SetupPointLight (int index, VisibleLight visibleLight) 
		{
			Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
			// 1/range^2
			position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
			OtherLightPositions[index] = position;
			OtherLightColors[index] = visibleLight.finalColor;
			OtherLightSpotAngles[index] = new Vector4(0f, 1f);
		}
		
		void SetupSpotLight (int index, VisibleLight visibleLight) {
			OtherLightColors[index] = visibleLight.finalColor;
			Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
			position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
			OtherLightPositions[index] = position;
			OtherLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
			
			Light light = visibleLight.light;
			float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
			float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
			float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
			OtherLightSpotAngles[index] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
		}
		
		
		
	}
	
}