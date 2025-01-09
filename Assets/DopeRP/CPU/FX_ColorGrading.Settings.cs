using System;
using System.Collections;
using System.Collections.Generic;
using DopeRP.CPU;
using UnityEngine;
using UnityEngine.Rendering;

public partial class FX_ColorGrading
{
    
    [Serializable]
    public class Settings
    {
        [Serializable]
        public enum ColorLUTResolution { _16 = 16, _32 = 32, _64 = 64 }

        [SerializeField]
        private ColorLUTResolution m_colorLUTResolution = ColorLUTResolution._32;

        public ColorLUTResolution colorLUTResolution => m_colorLUTResolution;
        
        [Serializable]
        public struct ColorAdjustmentsSettings
        {
            public float postExposure;
    
            [Range(-100f, 100f)]
            public float contrast;
    
            [ColorUsage(false, true)]
            public Color colorFilter;
    
            [Range(-180f, 180f)]
            public float hueShift;
    
            [Range(-100f, 100f)]
            public float saturation;
        }
    
        [SerializeField]
        ColorAdjustmentsSettings colorAdjustments = new ColorAdjustmentsSettings {
            colorFilter = Color.white
        };
    
        public ColorAdjustmentsSettings ColorAdjustments => colorAdjustments;
        
        [System.Serializable]
        public struct ToneMappingSettings {
    
            public enum Mode { None = 0, ACES = 1, Neutral = 2, Reinhard = 3 }
    
            public Mode mode;
        }
    
        [SerializeField]
        ToneMappingSettings toneMapping = default;
    
        public ToneMappingSettings ToneMapping => toneMapping;
        
        [Serializable]
        public struct WhiteBalanceSettings {
    
            [Range(-100f, 100f)]
            public float temperature, tint;
        }
    
        [SerializeField]
        WhiteBalanceSettings whiteBalance = default;
    
        public WhiteBalanceSettings WhiteBalance => whiteBalance;
        
        
        [Serializable]
        public struct SplitToningSettings {
    
            [ColorUsage(false)]
            public Color shadows, highlights;
    
            [Range(-100f, 100f)]
            public float balance;
        }
    
        [SerializeField]
        SplitToningSettings splitToning = new SplitToningSettings {
            shadows = Color.gray,
            highlights = Color.gray
        };
    
        public SplitToningSettings SplitToning => splitToning;
        
        
        [Serializable]
        public struct ChannelMixerSettings {
    
            public Vector3 red, green, blue;
        }
	    
        [SerializeField]
        ChannelMixerSettings channelMixer = new ChannelMixerSettings {
            red = Vector3.right,
            green = Vector3.up,
            blue = Vector3.forward
        };
    
        public ChannelMixerSettings ChannelMixer => channelMixer;
        
        
        [Serializable]
        public struct ShadowsMidtonesHighlightsSettings {
    
            [ColorUsage(false, true)]
            public Color shadows, midtones, highlights;
    
            [Range(0f, 2f)]
            public float shadowsStart, shadowsEnd, highlightsStart, highLightsEnd;
        }
    
        [SerializeField]
        ShadowsMidtonesHighlightsSettings
            shadowsMidtonesHighlights = new ShadowsMidtonesHighlightsSettings {
                shadows = Color.white,
                midtones = Color.white,
                highlights = Color.white,
                shadowsEnd = 0.3f,
                highlightsStart = 0.55f,
                highLightsEnd = 1f
            };
    
        public ShadowsMidtonesHighlightsSettings ShadowsMidtonesHighlights => shadowsMidtonesHighlights;
        
    }

    [SerializeField] private Settings m_settings = new Settings();

    public Settings settings => m_settings;
    
}
