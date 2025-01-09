using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
    public class Shadows
    {
        private const string BUFFER_NAME = "Shadows";

        private const int ACTIVE_LIGHT_INDEX = 0;
        private const int MAX_CASCADES = 4;
        // private const int MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT = 4;

        private static Vector4[] CascadeCullingSpheres = new Vector4[MAX_CASCADES];
        private static Vector4[] CascadeData = new Vector4[MAX_CASCADES];
        private static Matrix4x4[] DirShadowMatrices = new Matrix4x4[MAX_CASCADES];

        
        struct ShadowedDirectionalLight {
            public float slopeScaleBias;
            public float nearPlaneOffset;
        }

        private ShadowedDirectionalLight m_light;
        

        private ShadowSettings m_settings;
        
        

        private bool ready;
        public void Setup (ShadowSettings settings)
        {
            m_settings = settings;
            ready = false;
        }
        
        public void Render () {
            RAPI.BeginSample(BUFFER_NAME);
            if (ready) {
                RenderDepthBuffer();
            }
            else {
                RAPI.Buffer.GetTemporaryRT(SProps.Shadows.DirShadowAtlasId, 1, 1, 16, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
            }
            RAPI.EndSample(BUFFER_NAME);
        }

        private void RenderDepthBuffer()
        {
            int atlasSize = (int)m_settings.directional.atlasSize;
            RAPI.Buffer.GetTemporaryRT(SProps.Shadows.DirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
            RAPI.Buffer.SetRenderTarget(SProps.Shadows.DirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            RAPI.Buffer.ClearRenderTarget(true, false, Color.clear);
            

            int cascadesCount = m_settings.directional.cascades == ShadowSettings.Cascades.CASCADE_COUNT_2 ? 2 : 4;
            
            int tiles = cascadesCount;
            int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
            int tileSize = atlasSize / split;
            
            //
            
            var shadowSettings = new ShadowDrawingSettings(RAPI.CullingResults, 0, BatchCullingProjectionType.Orthographic);
            int cascadeCount = cascadesCount;
            int tileOffset = 0 * cascadeCount;
            Vector3 ratios = m_settings.directional.CascadeRatios;
            
            
            for (int i = 0; i < cascadeCount; i++) {
                RAPI.CullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(0, i, cascadeCount, ratios, tileSize, m_light.nearPlaneOffset, out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);
                splitData.shadowCascadeBlendCullingFactor = 1;
                shadowSettings.splitData = splitData;
                
                SetCascadeData(i, splitData.cullingSphere, tileSize);
                
                int tileIndex = tileOffset + i;
                DirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(projectionMatrix * viewMatrix, SetTileViewport(tileIndex, split, tileSize), split);
                RAPI.Buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
                RAPI.Buffer.SetGlobalDepthBias(0f, m_light.slopeScaleBias);
                RAPI.ExecuteBuffer();
                RAPI.Context.DrawShadows(ref shadowSettings);
                RAPI.Buffer.SetGlobalDepthBias(0f, 0f);
            }
            
            // RAPI.Buffer.SetGlobalInt(cascadeCountId, cascadesCount);
            RAPI.SetKeywords(m_settings.directional.cascades);
            RAPI.Buffer.SetGlobalVectorArray(SProps.Shadows.CascadesCullingSpheresId, CascadeCullingSpheres);
            RAPI.Buffer.SetGlobalVectorArray(SProps.Shadows.CascadeDataId, CascadeData);
            RAPI.Buffer.SetGlobalMatrixArray(SProps.Shadows.DirShadowMatricesId, DirShadowMatrices);
            float f = (float).9;
            RAPI.Buffer.SetGlobalVector(SProps.Shadows.ShadowDistanceFadeId, new Vector4(1f / m_settings.maxDistance, 1f / m_settings.distanceFade, 1f / (1f - f * f)));
            RAPI.SetKeywords(m_settings.directional.filter);
            // RAPI.SetKeywords(cascadeBlendKeywords, (int)m_settings.directional.cascadeBlend);
            RAPI.Buffer.SetGlobalVector(SProps.Shadows.ShadowAtlasSizeId, new Vector4(atlasSize, 1f / atlasSize));
            RAPI.Buffer.SetGlobalFloat(SProps.Shadows.CascadesCountId, cascadeCount);
            
            RAPI.ExecuteBuffer();

        }

        public Vector3 ReserveDirectionalShadows(Light light)
        {
            if (light.shadows != LightShadows.None && light.shadowStrength > 0f && RAPI.CullingResults.GetShadowCasterBounds(0, out Bounds b))
            {
                m_light = new ShadowedDirectionalLight {
                    slopeScaleBias = light.shadowBias,
                    nearPlaneOffset = light.shadowNearPlane
                };
                ready = true;
                return new Vector3(light.shadowStrength, m_settings.directional.cascades == ShadowSettings.Cascades.CASCADE_COUNT_2 ? 2 : 4, light.shadowNormalBias);
            }
            return Vector3.zero;
        }
        
        
        void SetCascadeData (int index, Vector4 cullingSphere, float tileSize) {
            float texelSize = 2f * cullingSphere.w / tileSize;
            float filterSize = texelSize * ((float)m_settings.directional.filter + 1f);
            cullingSphere.w -= filterSize;
            cullingSphere.w *= cullingSphere.w;
            CascadeCullingSpheres[index] = cullingSphere;
            CascadeData[index] = new Vector4(1f / cullingSphere.w, filterSize * 1.4142136f);
        }

        Vector2 SetTileViewport (int index, int split, float tileSize) {
            Vector2 offset = new Vector2(index % split, index / split);
            RAPI.Buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
            return offset;
        }
        
        Matrix4x4 ConvertToAtlasMatrix (Matrix4x4 m, Vector2 offset, int split) {
            if (SystemInfo.usesReversedZBuffer) {
                m.m20 = -m.m20;
                m.m21 = -m.m21;
                m.m22 = -m.m22;
                m.m23 = -m.m23;
            }
            float scale = 1f / split;
            m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
            m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
            m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
            m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
            m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
            m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
            m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
            m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
            m.m20 = 0.5f * (m.m20 + m.m30);
            m.m21 = 0.5f * (m.m21 + m.m31);
            m.m22 = 0.5f * (m.m22 + m.m32);
            m.m23 = 0.5f * (m.m23 + m.m33);
            return m;
        }

    }
    
}
