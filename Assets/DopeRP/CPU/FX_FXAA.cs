using System;
using System.Collections;
using System.Collections.Generic;
using DopeRP.CPU;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "DopeRP/PostFX/FXAA")]
public partial class FX_FXAA : FX_Feature
{
    private const string BUFFER_NAME = "FXAA";

    
    public override void SetupUniforms()
    {

    }

    public override void Render(int sourceRT, int targetRT, PostFXSettings generalFXSettings)
    {
        RAPI.BeginSample(BUFFER_NAME);

        RAPI.Draw(sourceRT,targetRT, PostFXStack.Pass.FXAA, generalFXSettings.Material);
        
        RAPI.EndSample(BUFFER_NAME);
    }
    
}