using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
    public static class RAPI
    {
        private const string BUFFER_NAME = "DefaultBufferName";
        static Mesh s_FullscreenTriangle = null;
        public static CommandBuffer Buffer { get;  set; } = new CommandBuffer {
            name = BUFFER_NAME
        };
        public static ScriptableRenderContext Context { get; set; }
        public static Camera CurCamera { get; set; }
        public static CullingResults CullingResults { get; private set; }

        public static RenderTexture a;
        
        static Mesh s_FullscreenMesh = null;

        public static bool m_samplingOn;
        
        private static int fxSourceId = Shader.PropertyToID("_PostFXSource");

        // public static Material Material;

        public static DopeRPAsset assetSettings;

        
    
        public static void ExecuteBuffer () {
            Context.ExecuteCommandBuffer(Buffer);
            Buffer.Clear();
        }
        

        public static void CleanupTempRT(int atlasID)
        {
            Buffer.ReleaseTemporaryRT(atlasID);
            ExecuteBuffer();
        }
    
        public static bool Cull(float maxShadowDistance)
        {
            if (CurCamera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
                p.shadowDistance = Mathf.Min(maxShadowDistance, CurCamera.farClipPlane);
                CullingResults = Context.Cull(ref p);
                return true;
            }
            return false;
        }
        
        public static void SetKeyword (string keyword, bool shouldBeSet) {
            if (shouldBeSet)
            {
                Buffer.EnableShaderKeyword(keyword);
            }
            else
            {
                Buffer.DisableShaderKeyword(keyword);
            }
        }
        
        public static void SetKeywords (string[] keywords, int enabledIndex) {
            for (int i = 0; i < keywords.Length; i++) {
                if (i == enabledIndex) {
                    Buffer.EnableShaderKeyword(keywords[i]);
                }
                else {
                    Buffer.DisableShaderKeyword(keywords[i]);
                }
            }
        }
        
        public static void SetKeywords <TEnum> (TEnum enabledIndex) where TEnum : Enum
        {
            var values = Enum.GetValues(typeof(TEnum));

            for (int i = 0; i < values.Length; i++)
            {
                var value = values.GetValue(i);
                string keyword = value.ToString();
                
                if(value.Equals(enabledIndex))
                {
                    Buffer.EnableShaderKeyword(keyword);
                }
                else
                    Buffer.DisableShaderKeyword(keyword);
            }
        }
        
        public static Mesh fullscreenTriangle
        {
            get
            {
                if (s_FullscreenTriangle != null)
                    return s_FullscreenTriangle;

                s_FullscreenTriangle = new Mesh { name = "Fullscreen Triangle" };

                // Because we have to support older platforms (GLES2/3, DX9 etc) we can't do all of
                // this directly in the vertex shader using vertex ids :(
                s_FullscreenTriangle.SetVertices(new List<Vector3>
                {
                    new Vector3(-1f, -1f, 0f),
                    new Vector3(-1f,  3f, 0f),
                    new Vector3( 3f, -1f, 0f)
                });

                s_FullscreenTriangle.SetIndices(new [] { 0, 1, 2 }, MeshTopology.Triangles, 0, false);
                s_FullscreenTriangle.UploadMeshData(false);

                return s_FullscreenTriangle;
            }
        }
        
        public static Mesh fullscreenMesh
        {
            get
            {
                if (s_FullscreenMesh != null)
                    return s_FullscreenMesh;

                float topV = 1.0f;
                float bottomV = 0.0f;

                s_FullscreenMesh = new Mesh { name = "Fullscreen Quad" };
                s_FullscreenMesh.SetVertices(new List<Vector3>
                {
                    new Vector3(-1.0f, -1.0f, 0.0f),
                    new Vector3(-1.0f,  1.0f, 0.0f),
                    new Vector3(1.0f, -1.0f, 0.0f),
                    new Vector3(1.0f,  1.0f, 0.0f)
                });

                s_FullscreenMesh.SetUVs(0, new List<Vector2>
                {
                    new Vector2(0.0f, bottomV),
                    new Vector2(0.0f, topV),
                    new Vector2(1.0f, bottomV),
                    new Vector2(1.0f, topV)
                });

                s_FullscreenMesh.SetIndices(new[] { 0, 1, 2, 2, 1, 3 }, MeshTopology.Triangles, 0, false);
                s_FullscreenMesh.UploadMeshData(true);
                return s_FullscreenMesh;
            }
            
            
        }
        
        public static Mesh fullscreenTrig
        {
            
            get
            {
                if (s_FullscreenTriangle != null)
                    return s_FullscreenTriangle;

                s_FullscreenTriangle = new Mesh { name = "Fullscreen Triangle" };
                s_FullscreenTriangle.SetVertices(new List<Vector3>
                {
                    new Vector3(-1f, -1f, 0f),  // Bottom-left
                    new Vector3(3f, -1f, 0f),   // Far right
                    new Vector3(-1f, 3f, 0f)    // Far top
                });

                // Even though we're drawing a triangle, UVs can still be useful for certain shaders.
                s_FullscreenTriangle.SetUVs(0, new List<Vector2>
                {
                    new Vector2(0f, 0f),
                    new Vector2(2f, 0f),
                    new Vector2(0f, 2f)
                });

                s_FullscreenTriangle.SetIndices(new[] { 0, 1, 2 }, MeshTopology.Triangles, 0);
                s_FullscreenTriangle.UploadMeshData(true);

                return s_FullscreenTriangle;
            }
        }
        public static void DrawEmpty(Material emptyMat)
        {
            RAPI.Buffer.SetRenderTarget(BuiltinRenderTextureType.None, BuiltinRenderTextureType.None);
            RAPI.ExecuteBuffer();
            RAPI.Buffer.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            RAPI.Buffer.DrawMesh(RAPI.fullscreenMesh, Matrix4x4.identity, emptyMat, 0, 0);
            RAPI.Buffer.SetViewProjectionMatrices(RAPI.CurCamera.worldToCameraMatrix, RAPI.CurCamera.projectionMatrix);
            
            RAPI.ExecuteBuffer();

        }

        public static void SetupCommonUniforms()
        {
            Matrix4x4 projectionMatrix = CurCamera.projectionMatrix;
            projectionMatrix = GL.GetGPUProjectionMatrix(projectionMatrix, false);
            Buffer.SetGlobalMatrix(SProps.Common.Matrix_P, projectionMatrix);
            Buffer.SetGlobalMatrix(SProps.Common.Matrix_I_P, Matrix4x4.Inverse(projectionMatrix));

            Buffer.SetGlobalMatrix(SProps.Common.Matrix_V,  RAPI.CurCamera.worldToCameraMatrix);
            Buffer.SetGlobalMatrix(SProps.Common.Matrix_I_V,  RAPI.CurCamera.cameraToWorldMatrix);
            
            var camPos = CurCamera.transform.position;
            Buffer.SetGlobalVector(SProps.Common.WorldSpaceCameraPos, new Vector4(camPos.x, camPos.y, camPos.z, 0 ));
            Buffer.SetGlobalVector(SProps.Common.NearFarPlanes, new Vector4(CurCamera.nearClipPlane, CurCamera.farClipPlane, 0, 0 ));

            var pixelWidth = CurCamera.pixelWidth;
            var pixelHeight = CurCamera.pixelHeight;
            RAPI.Buffer.SetGlobalVector(SProps.Common.ScreenSize, new Vector4(pixelWidth, pixelHeight, 1f/(float)pixelWidth, 1f/pixelHeight));

            
        }

        public static void DrawFullscreenQuad(Material material, string passName)
        {
            Buffer.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            Buffer.DrawMesh(fullscreenMesh, Matrix4x4.identity, material, 0, material.FindPass(passName));
            // RAPI.Buffer.SetViewProjectionMatrices(RAPI.CurCamera.worldToCameraMatrix, RAPI.CurCamera.projectionMatrix);
        }
        
        public static void DrawFullscreenQuad(Material material, int passNum)
        {
            Buffer.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            Buffer.DrawMesh(fullscreenMesh, Matrix4x4.identity, material, 0, passNum);
        }
        
        public static void DrawFullscreenQuadFromTo(RenderTargetIdentifier from, RenderTargetIdentifier to, 
            Material material, int passNum)
        {
            Buffer.SetGlobalTexture(SProps.PostFX.fxSourceAtlas, from);
            Buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            // buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int)pass, MeshTopology.Triangles, 3);
            Buffer.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            Buffer.DrawMesh(fullscreenMesh, Matrix4x4.identity, material, 0, passNum);
            // RAPI.Buffer.SetViewProjectionMatrices(RAPI.CurCamera.worldToCameraMatrix, RAPI.CurCamera.projectionMatrix);
        }

        public static void BeginSample(string bufferName)
        {
            if (!m_samplingOn)
            {
                return;
            }
            Buffer.name = bufferName;
            Buffer.BeginSample(bufferName);
            ExecuteBuffer();
        }

        public static void EndSample(string bufferName)
        {
            if (!m_samplingOn)
            {
                return;
            }
            Buffer.EndSample(bufferName);
            ExecuteBuffer();
        }
        
        // public static void CopyTexture (RenderTargetIdentifier from, RenderTargetIdentifier to) {
        //     Buffer.SetGlobalTexture(fxSourceId, from);
        //     Buffer.SetRenderTarget(to);
        //     Buffer.DrawProcedural(Matrix4x4.identity, Material, 0, MeshTopology.Triangles, 3);
        // }
        
        public static void Draw (RenderTargetIdentifier from, RenderTargetIdentifier to, PostFXStack.Pass pass,
            Material material) {
            Buffer.SetGlobalTexture(fxSourceId, from);
            Buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            Buffer.DrawProcedural(Matrix4x4.identity, material, (int)pass, MeshTopology.Triangles, 3);
        }
    }
}
