using System;
using System.Collections;
using System.Collections.Generic;
using DopeRP.CPU;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "DopeRP/PostFX/ColorGrading")]
public partial class FX_ColorGrading : FX_Feature
{
    private const string BUFFER_NAME = "ColorGrading";
    
    private int colorAdjustmentsId = Shader.PropertyToID("_ColorAdjustments");
    private int colorFilterId = Shader.PropertyToID("_ColorFilter");
    private int whiteBalanceId = Shader.PropertyToID("_WhiteBalance");
    private int splitToningShadowsId = Shader.PropertyToID("_SplitToningShadows");
    private int splitToningHighlightsId = Shader.PropertyToID("_SplitToningHighlights");
    private int channelMixerRedId = Shader.PropertyToID("_ChannelMixerRed");
    private int channelMixerGreenId = Shader.PropertyToID("_ChannelMixerGreen");
    private int channelMixerBlueId = Shader.PropertyToID("_ChannelMixerBlue");
    private int smhShadowsId = Shader.PropertyToID("_SMHShadows");
    private int smhMidtonesId = Shader.PropertyToID("_SMHMidtones");
    private int smhHighlightsId = Shader.PropertyToID("_SMHHighlights");
    private int smhRangeId = Shader.PropertyToID("_SMHRange");
     
    private int colorGradingLUTId = Shader.PropertyToID("_ColorGradingLUT");
    private int colorGradingLUTParametersId = Shader.PropertyToID("_ColorGradingLUTParameters");
    private int colorGradingLUTInLogId = Shader.PropertyToID("_ColorGradingLUTInLogC");
    
    
    
    
    public override void SetupUniforms()
    {
        ConfigureColorAdjustments();
        ConfigureWhiteBalance();
        ConfigureSplitToning();
        ConfigureChannelMixer();
        ConfigureShadowsMidtonesHighlights();
    }

    public override void Render(int sourceRT, int targetRT, PostFXSettings generalFXSettings)
    {
        RAPI.BeginSample(BUFFER_NAME);
        
        int lutHeight = (int)settings.colorLUTResolution;
        int lutWidth = lutHeight * lutHeight;
        RAPI.Buffer.GetTemporaryRT(colorGradingLUTId, lutWidth, lutHeight, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
        RAPI.Buffer.SetGlobalVector(colorGradingLUTParametersId, new Vector4(lutHeight, 0.5f / lutWidth, 0.5f / lutHeight, lutHeight / (lutHeight - 1f)));

        Settings.ToneMappingSettings.Mode mode = settings.ToneMapping.mode;
        PostFXStack.Pass pass = PostFXStack.Pass.ColorGradingNone + (int)mode;
        // HDR
        // RAPI.Buffer.SetGlobalFloat(colorGradingLUTInLogId, useHDR && pass != Pass.ColorGradingNone ? 1f : 0f);
        RAPI.Buffer.SetGlobalFloat(colorGradingLUTInLogId, 0f);
        // RAPI.DrawFullscreenQuadFromTo(SProps.PostFX.fxSourceAtlas, colorGradingLUTId,
        //     generalFXSettings.Material, (int)pass);
        RAPI.Draw(sourceRT, colorGradingLUTId, pass, generalFXSettings.Material);
        
        // HDR
        // RenderTextureFormat format = useHDR ?
        //     RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default;
        RAPI.Buffer.SetGlobalVector(colorGradingLUTParametersId, new Vector4(1f / lutWidth, 1f / lutHeight, lutHeight - 1f));

        // RenderTextureFormat format = RenderTextureFormat.Default;
        // RAPI.Buffer.GetTemporaryRT(Shader.PropertyToID("_ColorGrading"), RAPI.CurCamera.pixelWidth, RAPI.CurCamera.pixelHeight, 0, FilterMode.Bilinear, format);
        // RAPI.DrawFullscreenQuadFromTo(SProps.PostFX.fxSourceAtlas, Shader.PropertyToID("_ColorGrading"),
        //     generalFXSettings.Material, (int)PostFXStack.Pass.Final);
        
        RAPI.Draw(sourceRT, targetRT, PostFXStack.Pass.Final, generalFXSettings.Material);
        
        RAPI.Buffer.ReleaseTemporaryRT(colorGradingLUTId);

        RAPI.EndSample(BUFFER_NAME);
    }
    
    void ConfigureColorAdjustments () {
        Settings.ColorAdjustmentsSettings colorAdjustments = settings.ColorAdjustments;
        
        RAPI.Buffer.SetGlobalVector(colorAdjustmentsId, new Vector4(Mathf.Pow(2f, colorAdjustments.postExposure), colorAdjustments.contrast * 0.01f + 1f, colorAdjustments.hueShift * (1f / 360f), colorAdjustments.saturation * 0.01f + 1f));
        RAPI.Buffer.SetGlobalColor(colorFilterId, colorAdjustments.colorFilter.linear);
    }
    
    void ConfigureWhiteBalance () {
        Settings.WhiteBalanceSettings whiteBalance = settings.WhiteBalance;
        RAPI.Buffer.SetGlobalVector(whiteBalanceId, ColorUtils.ColorBalanceToLMSCoeffs(whiteBalance.temperature, whiteBalance.tint));
    }
    
    void ConfigureSplitToning () {
        Settings.SplitToningSettings splitToning = settings.SplitToning;
        Color splitColor = splitToning.shadows;
        splitColor.a = splitToning.balance * 0.01f;
        RAPI.Buffer.SetGlobalColor(splitToningShadowsId, splitColor);
        RAPI.Buffer.SetGlobalColor(splitToningHighlightsId, splitToning.highlights);
    }
    
    void ConfigureChannelMixer () {
        Settings.ChannelMixerSettings channelMixer = settings.ChannelMixer;
        RAPI.Buffer.SetGlobalVector(channelMixerRedId, channelMixer.red);
        RAPI.Buffer.SetGlobalVector(channelMixerGreenId, channelMixer.green);
        RAPI.Buffer.SetGlobalVector(channelMixerBlueId, channelMixer.blue);
    }
    
    void ConfigureShadowsMidtonesHighlights () {
        Settings.ShadowsMidtonesHighlightsSettings smh = settings.ShadowsMidtonesHighlights;
        RAPI.Buffer.SetGlobalColor(smhShadowsId, smh.shadows.linear);
        RAPI.Buffer.SetGlobalColor(smhMidtonesId, smh.midtones.linear);
        RAPI.Buffer.SetGlobalColor(smhHighlightsId, smh.highlights.linear);
        RAPI.Buffer.SetGlobalVector(smhRangeId, new Vector4(smh.shadowsStart, smh.shadowsEnd, smh.highlightsStart, smh.highLightsEnd));
    }
}
