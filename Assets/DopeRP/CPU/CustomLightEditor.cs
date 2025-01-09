using UnityEditor;
using UnityEngine;

namespace DopeRP.CPU
{
    #if UNITY_EDITOR

    [CanEditMultipleObjects]
    [CustomEditorForRenderPipeline(typeof(Light), typeof(DopeRPAsset))]
    public class CustomLightEditor : LightEditor
    {
        public override void OnInspectorGUI() {
            base.OnInspectorGUI();
            
            if (
                !settings.lightType.hasMultipleDifferentValues &&
                (LightType)settings.lightType.enumValueIndex == LightType.Spot
            )
            {
                settings.DrawInnerAndOuterSpotAngle();
                settings.ApplyModifiedProperties();
            }
        }
    }
    
    #endif

    
}