Shader "MGFX/NPRCelShading2DS"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}
        [NoScaleOffset] _BayerTex ("Bayer Matrix", 2D) = "white" {}
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

            ENDCG
        }

        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}