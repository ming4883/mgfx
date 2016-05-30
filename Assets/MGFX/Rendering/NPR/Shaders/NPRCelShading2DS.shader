Shader "MGFX/NPRCelShading2DS"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}

        [Toggle(_DIM_ON)] _DimOn("Enable Dim", Int) = 0
        [NoScaleOffset] _DimTex ("Dim (RGB)", 2D) = "white" {}

        [Toggle(_OVERLAY_ON)] _OverlayOn("Enable Overlay", Int) = 0
        _OverlayTex ("Overlay (RGBA)", 2D) = "white" {}

        [NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}

        [NoScaleOffset] _BayerTex ("Bayer Matrix", 2D) = "white" {}

        [Toggle(_RIM_ON)] _RimOn("Enable Rim", Int) = 0
        [NoScaleOffset] _RimLUTTex ("Rim LUT (R)", 2D) = "white" {}
        _RimIntensity ("RimIntensity", Range(0,1)) = 1.0
    }

    CGINCLUDE
    #include "NPRCelShading2.cginc"
    ENDCG

    SubShader
    {
    	Tags
    	{ 
        	"RenderType"="Opaque"
        }
		
		Cull Off

        Pass
        {
            Tags
            {
            	"LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_base
            #pragma multi_compile_fwdbase nolightmap nodynlightmap novertexlight
            #pragma target 3.0

            #pragma shader_feature _DIM_ON
            #pragma shader_feature _RIM_ON

            ENDCG
        }

        Pass
        {
            Tags
            {
            	"LightMode"="ForwardAdd"
            }

            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_add
            #pragma multi_compile_fwdadd_fullshadows
            #pragma target 3.0

            #pragma shader_feature _DIM_ON

            ENDCG
        }

        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}