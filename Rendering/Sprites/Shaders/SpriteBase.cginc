#include "UnityCG.cginc"

struct appdata_t
{
	float4 vertex   : POSITION;
	float4 color    : COLOR;
	float2 texcoord : TEXCOORD0;
};

struct v2f
{
	float4 vertex   : SV_POSITION;
	fixed4 color    : COLOR;
	float2 texcoord  : TEXCOORD0;
};

v2f vert(appdata_t IN)
{
	v2f OUT;
	OUT.vertex = UnityObjectToClipPos (IN.vertex);
	OUT.texcoord = IN.texcoord;
	OUT.color = IN.color;
	#ifdef PIXELSNAP_ON
	OUT.vertex = UnityPixelSnap (OUT.vertex);
	#endif

	return OUT;
}

sampler2D _MainTex;
float4 _MainTex_TexelSize;
sampler2D _AlphaTex;
float _AlphaSplitEnabled;
float4 _Mixin;


float4 GetTexel( sampler2D tex, float4 texelSize, float2 p )
{
#if _IMPROVED_FILTERING
	p = p * texelSize.zw + 0.5;

	float2 i = floor(p);
	float2 f = p - i;
	f = f*f*f*(f*(f*6.0-15.0)+10.0);
	p = i + f;

	p = (p - 0.5) * texelSize.xy;
#endif
	return tex2D (tex, p);
}

fixed4 SampleSpriteTexture (float2 uv)
{
	//fixed4 color = tex2D (_MainTex, uv);
	fixed4 color = GetTexel (_MainTex, _MainTex_TexelSize, uv);

#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
	if (_AlphaSplitEnabled)
		//color.a = tex2D (_AlphaTex, uv).r;
		color.a = GetTexel (_AlphaTex, _MainTex_TexelSize, uv).r;
#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

	return color;
}