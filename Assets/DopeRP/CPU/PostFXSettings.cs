using System;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "DopeRP/Post FX Settings")]
public class PostFXSettings : ScriptableObject
{
    
    [SerializeField]
    Shader shader = default;
    [System.NonSerialized]
    Material material;
    public Material Material {
        get {
            if (material == null && shader != null) {
                material = new Material(shader);
                material.hideFlags = HideFlags.HideAndDontSave;
            }
            return material;
        }
    }
    
    [Serializable] 
    public struct PostFXFeaturesChoice
    {
        public bool FXFeatureIsOne;
        public FX_Feature fxFeature;
    }
    public List<PostFXFeaturesChoice> currentFXFeaturesList;
    
}