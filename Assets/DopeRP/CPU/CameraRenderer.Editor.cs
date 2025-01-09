using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace DopeRP.CPU
{
	public partial class CameraRenderer {

		partial void DrawGizmosBeforeFX ();
		partial void DrawGizmosAfterFX ();
		partial void DrawUnsupportedShaders();

		partial void PrepareUIForSceneWindow ();

#if UNITY_EDITOR
		static Material errorMaterial;

		static ShaderTagId[] legacyShaderTagIds = {
			new ShaderTagId("Always"),
			new ShaderTagId("ForwardBase"),
			new ShaderTagId("PrepassBase"),
			new ShaderTagId("Vertex"),
			new ShaderTagId("VertexLMRGBM"),
			new ShaderTagId("VertexLM")
		};

		partial void DrawUnsupportedShaders () {
			if (errorMaterial == null) {
				errorMaterial =
					new Material(Shader.Find("Hidden/InternalErrorShader"));
			}

			RenderTargetIdentifier[] colorTargets =
			{
				new RenderTargetIdentifier(Shader.PropertyToID("1")),
			};
			if( postFXStack.IsActive)
				RAPI.Buffer.SetRenderTarget(SProps.PostFX.fxSourceAtlas, new RenderTargetIdentifier(SProps.Common.DepthBuffer));
			else
			{
				RAPI.Buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, new RenderTargetIdentifier(SProps.Common.DepthBuffer));
			}
			RAPI.ExecuteBuffer();
			
			var drawingSettings = new DrawingSettings(
				legacyShaderTagIds[0], new SortingSettings(RAPI.CurCamera)
			)
			{
				overrideMaterial = errorMaterial
			};
			for (int i = 1; i < legacyShaderTagIds.Length; i++) {
				drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
			}
			var filteringSettings = FilteringSettings.defaultValue;
			RAPI.Context.DrawRenderers(
				RAPI.CullingResults, ref drawingSettings, ref filteringSettings
			);
		}

		partial void DrawGizmosBeforeFX  () {
			if (Handles.ShouldRenderGizmos()) {
				RAPI.Context.DrawGizmos(RAPI.CurCamera, GizmoSubset.PreImageEffects);
			}
		}
		
		partial void DrawGizmosAfterFX () {
			if (Handles.ShouldRenderGizmos()) {
				RAPI.Context.DrawGizmos(RAPI.CurCamera, GizmoSubset.PostImageEffects);
			}
		}

		partial void PrepareUIForSceneWindow () {
			if (RAPI.CurCamera.cameraType == CameraType.SceneView) {
				ScriptableRenderContext.EmitWorldGeometryForSceneView(RAPI.CurCamera);
			}
		}
#endif
	}
}

// // Build a matrix for cropping light's projection
// // Given vectors are in light's clip space
// Matrix Light::CalculateCropMatrix(Frustum splitFrustum) 
// {   Matrix lightViewProjMatrix = viewMatrix * projMatrix;   
// 	// Find boundaries in light's clip space
// 	BoundingBox cropBB = CreateAABB(splitFrustum.AABB, lightViewProjMatrix);   
// 	// Use default near-plane value
// 	cropBB.min.z = 0.0f;   
// 	// Create the crop matrix
// 	float scaleX, scaleY, scaleZ;   
// 	float offsetX, offsetY, offsetZ;   
// 	scaleX = 2.0f / (cropBB.max.x - cropBB.min.x);   
// 	scaleY = 2.0f / (cropBB.max.y - cropBB.min.y);   
// 	offsetX = -0.5f * (cropBB.max.x + cropBB.min.x) * scaleX;   
// 	offsetY = -0.5f * (cropBB.max.y + cropBB.min.y) * scaleY;   
// 	scaleZ = 1.0f / (cropBB.max.z - cropBB.min.z);   
// 	offsetZ = -cropBB.min.z * scaleZ;   
// 	return Matrix( scaleX, 0.0f, 0.0f, 0.0f, 0.0f, scaleY, 0.0f,  0.0f, 0.0f, 0.0f, scaleZ,  0.0f, offsetX,  offsetY,  offsetZ,  1.0f); 
// } 