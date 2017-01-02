#pragma vertex vert_meta
#pragma fragment frag_meta

// define meta pass before including other files; they have conditions
// on that in some places
#define UNITY_PASS_META 1

#include "UnityCG.cginc"
#include "UnityMetaPass.cginc"

struct appdata_meta
{
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
    float2 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
};

struct v2f_meta
{
	float2 uv		: TEXCOORD0;
	float4 pos		: SV_POSITION;
};

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform sampler2D _GIAlbedoTex;
uniform float4 _GIAlbedoColor;

uniform sampler2D _GIEmissionTex;
uniform float4 _GIEmissionColor;

v2f_meta vert_meta (appdata_meta v)
{
	v2f_meta o;
	o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	return o;
}


float4 frag_meta (v2f_meta i) : SV_Target
{
	UnityMetaInput o;
	UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

	o.Albedo = tex2D(_GIAlbedoTex, i.uv) * _GIAlbedoColor;
	o.Emission = tex2D(_GIEmissionTex, i.uv) * _GIEmissionColor;

	return UnityMetaFragment(o);
}
