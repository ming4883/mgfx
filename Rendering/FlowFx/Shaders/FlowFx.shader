﻿Shader "MGFX/FlowFx" {
	Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
        [NoScaleOffset] _FlowMapTex("FlowMap", 2D) = "white" {}
		_FlowLayer1 ("Layer1", Float) = 0
		_FlowLayer2 ("Layer2", Float) = 1
		_FlowBlending ("Blending", Range(0, 1)) = 0.5
	}

	Category {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off
		
		SubShader {
			Pass {
				CGPROGRAM

#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_fog

#include "UnityCG.cginc"

uniform sampler2D _MainTex;
uniform float4 _MainTex_TexelSize;
uniform float4 _MainTex_ST;

uniform sampler2D _FlowMapTex;
uniform half _FlowLayer1;
uniform half _FlowLayer2;
uniform half _FlowBlending;

struct appdata_t {
	float4 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
};

struct v2f {
	float4 vertex : SV_POSITION;
	float2 texcoord : TEXCOORD0;
	UNITY_FOG_COORDS(1)
};

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
	UNITY_TRANSFER_FOG(o,o.vertex);
	return o;
}

fixed4 frag(v2f i) : SV_Target
{
    half4 flow = tex2D(_FlowMapTex, i.texcoord);
	flow.xyz = (flow.xyz * 2.0 - 1.0);
	half flowStrength = length(flow.xy);

    fixed4 col1 = tex2D(_MainTex, i.texcoord + flow.xy * _FlowLayer1 * _MainTex_TexelSize.xy);
	fixed4 col2 = tex2D(_MainTex, i.texcoord + flow.xy * _FlowLayer2 * _MainTex_TexelSize.xy);

	fixed4 col = lerp(col1, col2, saturate(_FlowBlending));
    col.a *= flow.a;

    UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(col.rgb,0)); // fog towards black due to our blend mode
    return col;
}

				ENDCG 
			}
		}	
	}
}