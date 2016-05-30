Shader "MGFX/NPRCelShading" {
    Properties {
        [NoScaleOffset] _MainTex ("Main (RGB)", 2D) = "white" {}

        [Toggle(_DIM_ON)] _DimOn("Enable Dim", Int) = 0
        [NoScaleOffset] _DimTex ("Dim (RGB)", 2D) = "black" {}

        [Toggle(_NORMAL_MAP_ON)] _NormalMapOn("Enable NormalMap", Int) = 0
        [NoScaleOffset] _NormalMapTex ("Normal Map", 2D) = "black" {}
        
        [Toggle(_OVERLAY_ON)] _OverlayOn("Enable Overlay", Int) = 0
        [NoScaleOffset] _OverlayTex ("Overlay (RGBA)", 2D) = "black" {}
        
        [Toggle(_RIM_ON)] _RimOn("Enable Rim", Int) = 0
        _RimSize ("RimSize", Range(0,1)) = 0.25
        _RimIntensity ("RimIntensity", Range(0,1)) = 1.0

        [Toggle(_DIFFUSE_LUT_ON)] _DiffuseLUTOn("Enable Diffuse LUT", Int) = 0
        [NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}
        
        [Toggle(_EDGE_ON)] _EdgeOn("Enable Edges", Int) = 0
        _EdgeColor ("EdgeColor", Color) = (0, 0, 0, 1)
        _EdgeAutoColor ("EdgeAutoColor", Range(0,1)) = 0.25
        _EdgeAutoColorFactor ("EdgeAutoColorFactor", Range(0.125,4)) = 0.25

        [Toggle(_SSAO_ON)] _SsaoOn("Enable SSAO", Int) = 0
        _SsaoShapness ("_SsaoShapness", Range(0,1)) = 0.0
    }
    SubShader {
        Tags { 
        	"RenderType"="Opaque"
        }
        LOD 200
        
        CGPROGRAM

        #pragma surface surf CelShading
        #pragma shader_feature _DIM_ON
        #pragma shader_feature _NORMAL_MAP_ON
        #pragma shader_feature _OVERLAY_ON
        #pragma shader_feature _RIM_ON
        #pragma shader_feature _DIFFUSE_LUT_ON
        #pragma shader_feature _EDGE_ON
        #pragma shader_feature _SSAO_ON

        #pragma target 3.0

        #include "NPRCelShadingCore.cginc"

        ENDCG
    }
    FallBack "Standard"
    CustomEditor "MGFX.NPRCelShadingUI"
}
