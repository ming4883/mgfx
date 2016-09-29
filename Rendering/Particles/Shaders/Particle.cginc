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