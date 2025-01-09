using DopeRP.CPU;
using UnityEngine;
using UnityEngine.Rendering;
using static PostFXSettings;

public partial class PostFXStack {

    private const string BUFFER_NAME = "PostFX";
    
    public enum Pass {
        Copy,
        ColorGradingNone,
        ColorGradingACES,
        ColorGradingNeutral,
        ColorGradingReinhard,
        Final,
        FXAA,
        Vignette
    }


    
    public bool IsActive => settings != null;

    PostFXSettings settings;

    public void Setup (PostFXSettings settings) {

        this.settings = settings;
        this.settings = RAPI.CurCamera.cameraType <= CameraType.SceneView && RAPI.assetSettings.postFXOn ? settings : null;
        ApplySceneViewState();
        RAPI.Buffer.GetTemporaryRT(SProps.PostFX.fxSourceAtlas, RAPI.CurCamera.pixelWidth, RAPI.CurCamera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
        RAPI.Buffer.GetTemporaryRT(SProps.PostFX.fxDestinationAtlas, RAPI.CurCamera.pixelWidth, RAPI.CurCamera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
        // RAPI.Draw();
        
    }
    
    public void Render (int sourceId) {
        
        RAPI.BeginSample(BUFFER_NAME);
        
        foreach (var fxFeature in settings.currentFXFeaturesList)
        {
            if (fxFeature.FXFeatureIsOne)
            {
                fxFeature.fxFeature.SetupUniforms();
                fxFeature.fxFeature.Render(SProps.PostFX.fxSourceAtlas, SProps.PostFX.fxDestinationAtlas, settings);
                RAPI.Draw(SProps.PostFX.fxDestinationAtlas, SProps.PostFX.fxSourceAtlas, Pass.Copy, settings.Material);
            }
        }
      
        RAPI.Draw(SProps.PostFX.fxSourceAtlas, BuiltinRenderTextureType.CameraTarget, Pass.Copy,
            settings.Material);
        
        RAPI.CleanupTempRT(SProps.PostFX.fxSourceAtlas);
        RAPI.CleanupTempRT(SProps.PostFX.fxDestinationAtlas);
        
        RAPI.EndSample(BUFFER_NAME);
        
    }
    
}