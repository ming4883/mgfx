Shader "MGFX/Particles/AddZAlways" {
	Properties {
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
_MainTex ("Particle Texture", 2D) = "white" {}
_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0

[Toggle(_SOFT_PARTICLE_SUPPORT)] _SoftParticleSupport("Enable Soft Particle", Int) = 0
	}

	Category {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		Blend SrcAlpha One
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off
		ZTest Always

		SubShader {
			Pass {
				CGPROGRAM
				#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

				#pragma shader_feature _SOFT_PARTICLE_SUPPORT

#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_particles
#pragma multi_compile_fog

#include "UnityCG.cginc"

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;
uniform fixed4 _TintColor;

#if _SOFT_PARTICLE_SUPPORT
uniform sampler2D_float _CameraDepthTexture;
uniform float _InvFade;
#endif

struct appdata_t {
	float4 vertex : POSITION;
	fixed4 color : COLOR;
	float2 texcoord : TEXCOORD0;
};

struct v2f {
	float4 vertex : SV_POSITION;
	fixed4 color : COLOR;
	float2 texcoord : TEXCOORD0;
	UNITY_FOG_COORDS(1)
	#ifdef SOFTPARTICLES_ON
	float4 projPos : TEXCOORD2;
	#endif
};

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	#ifdef SOFTPARTICLES_ON
	o.projPos = ComputeScreenPos (o.vertex);
	COMPUTE_EYEDEPTH(o.projPos.z);
	#endif
	o.color = v.color;
	o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
	UNITY_TRANSFER_FOG(o,o.vertex);
	return o;
}
				fixed4 frag(v2f i) : SV_Target
{
#ifdef SOFTPARTICLES_ON
#if _SOFT_PARTICLE_SUPPORT
    float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
    float partZ = i.projPos.z;
    float fade = saturate(_InvFade * (sceneZ - partZ));
    i.color.a *= fade;
#endif
#endif

    fixed4 col = 2.0f * i.color * _TintColor * tex2D(_MainTex, i.texcoord);
    UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0)); // fog towards black due to our blend mode
    return col;
}
				ENDCG 
			}
		}	
	}
}