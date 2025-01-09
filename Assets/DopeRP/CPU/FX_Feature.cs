using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "DopeRP/Post FX Settings")]
public abstract class FX_Feature : ScriptableObject
{
    public static PostFXStack.Pass m_FXFeaturePass;
    public abstract void SetupUniforms();
    
    public abstract void Render(int sourceRT, int targetRT, PostFXSettings generalFXSettings);

    
    // void Draw (
    //     RenderTargetIdentifier from, RenderTargetIdentifier to, ShaderData.Pass pass
    // ) {
    //     buffer.SetGlobalTexture(fxSourceId, from);
    //     buffer.SetRenderTarget(
    //         to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store
    //     );
    //     buffer.DrawProcedural(
    //         Matrix4x4.identity, settings.Material, (int)pass,
    //         MeshTopology.Triangles, 3
    //     );
    // }
}