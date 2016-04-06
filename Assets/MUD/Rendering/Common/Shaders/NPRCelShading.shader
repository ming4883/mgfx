Shader "Mud/NPRCelShading" {
    Properties {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Toggle(_NORMAL_MAP_ON)] _NormalMapOn("Enable NormalMap", Int) = 0
        _NormalMapTex ("Normal Map", 2D) = "black" {}
        
        [Toggle(_OVERLAY_ON)] _OverlayOn("Enable Overlay", Int) = 0
        _OverlayTex ("Overlay (RGBA)", 2D) = "black" {}
        
        [Toggle(_RIM_ON)] _RimOn("Enable Rim", Int) = 0
        _RimSize ("RimSize", Range(0,1)) = 0.25
        _RimIntensity ("RimIntensity", Range(0,1)) = 1.0

        [Toggle(_DIFFUSE_LUT_ON)] _DiffuseLUTOn("Enable Diffuse LUT", Int) = 0
        _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}
        
        _EdgeStrengthCurve ("Edge Strength (Curve)", Range(0, 16)) = 4.0
        _EdgeStrengthPlanar ("Edge Strength (Planar)", Range(0, 16)) = 4.0
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        CGPROGRAM

        #pragma surface surf CelShading
        #pragma shader_feature _NORMAL_MAP_ON
        #pragma shader_feature _OVERLAY_ON
        #pragma shader_feature _RIM_ON
        #pragma shader_feature _DIFFUSE_LUT_ON

        #pragma target 3.0

        #include "NPRCelShadingCore.cginc"

        ENDCG
    }
    FallBack "Standard"
    CustomEditor "Mud.NPRCelShadingUI"
}
