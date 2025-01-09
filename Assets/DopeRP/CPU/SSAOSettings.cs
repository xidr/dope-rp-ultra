using UnityEngine;

namespace DopeRP.CPU
{
    
    [System.Serializable]
    public class SSAOSettings {
        
        public enum SamplesCount {
            _SAMPLES_COUNT16, _SAMPLES_COUNT32, _SAMPLES_COUNT64
        }

        [SerializeField]
        public SamplesCount samplesCount;
        
        // public String samplesCount
        // {
        //     get {
        //         return m_samplesCount.ToString();
        //     }
        //     private set{}
        // }

        [OnChangedCall("onPropertyChangeSSAOSettings")]
        public Texture2D noiseTexture;
        
        [OnChangedCall("onPropertyChangeSSAOSettings")]
        [Range(1, 128)]
        public int randomSize;
        
        [OnChangedCall("onPropertyChangeSSAOSettings")]
        [Range(0, 5)]
        public float sampleRadius;
        
        [OnChangedCall("onPropertyChangeSSAOSettings")]
        [Range(0, 5)]
        public float bias;
        
        [OnChangedCall("onPropertyChangeSSAOSettings")]
        [Range(0, 2)]
        public float magnitude;
        
        [OnChangedCall("onPropertyChangeSSAOSettings")]
        [Range(0, 2)]
        public float contrast;
        
        
        [Header("(Just so unity don't create a new material each render call)")]
        public Material SSAOMaterial;
        
    }
    
}