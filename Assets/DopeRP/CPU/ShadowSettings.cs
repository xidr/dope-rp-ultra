using UnityEngine;

namespace DopeRP.CPU
{
    [System.Serializable]
    public class ShadowSettings
    {

        public bool shadowsOn;
        
        public enum TextureSize {
            _256 = 256, _512 = 512, _1024 = 1024,
            _2048 = 2048, _4096 = 4096, _8192 = 8192
        }
        
        public enum FilterMode {
            _DIRECTIONAL_PCF_NONE, _DIRECTIONAL_PCF2x2, _DIRECTIONAL_PCF4x4, _DIRECTIONAL_PCF6x6, _DIRECTIONAL_PCF8x8
        }
        
        public enum Cascades {
            CASCADE_COUNT_2, CASCADE_COUNT_4
        }
        
        [System.Serializable]
        public struct Directional {

            public TextureSize atlasSize;
            public FilterMode filter;

            public Cascades cascades;

            [Range(0f, 1f)]
            public float cascadeRatio1, cascadeRatio2, cascadeRatio3;
            public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);

        }
        
        [Min(0.001f)]
        public float maxDistance = 100f;
        
        [Range(0.001f, 1f)]
        public float distanceFade = 0.1f;

        public Directional directional = new Directional {
            atlasSize = TextureSize._1024,
            filter = FilterMode._DIRECTIONAL_PCF2x2,
            cascades = Cascades.CASCADE_COUNT_4,
            cascadeRatio1 = 0.1f,
            cascadeRatio2 = 0.25f,
            cascadeRatio3 = 0.5f,
        };
    }
}