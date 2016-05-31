Shader "MGFX/NPRCelShading2"
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
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#if UNITY_VERSION < 540
#define unity_WorldToLight _LightMatrix0 
#endif

#ifdef POINT
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
	fixed destName = (tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL);
#endif

#ifdef SPOT
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)); \
	fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif

#ifdef DIRECTIONAL
	#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos)	fixed destName = 1;
#endif


#ifdef POINT_COOKIE
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
	fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w;
#endif

#ifdef DIRECTIONAL_COOKIE
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy; \
	fixed destName = tex2D(_LightTexture0, lightCoord).w;
#endif
uniform sampler2D _BayerTex;
uniform float4 _BayerTex_TexelSize;

#define F1 float
#define F2 float2
#define F3 float3
#define F4 float4
#define fract frac
#define iGlobalTime _Time.y * 16.0

F1 Noise(F2 n,F1 x){n+=x;return fract(sin(dot(n.xy,F2(12.9898, 78.233)))*43758.5453)*2.0-1.0;}

// Step 1 in generation of the dither source texture.
F1 Step1(F2 uv,F1 n){
    F1 a=1.0,b=2.0,c=-12.0,t=1.0;   
    return (1.0/(a*4.0+b*4.0-c))*(
        Noise(uv+F2(-1.0,-1.0)*t,n)*a+
        Noise(uv+F2( 0.0,-1.0)*t,n)*b+
        Noise(uv+F2( 1.0,-1.0)*t,n)*a+
        Noise(uv+F2(-1.0, 0.0)*t,n)*b+
        Noise(uv+F2( 0.0, 0.0)*t,n)*c+
        Noise(uv+F2( 1.0, 0.0)*t,n)*b+
        Noise(uv+F2(-1.0, 1.0)*t,n)*a+
        Noise(uv+F2( 0.0, 1.0)*t,n)*b+
        Noise(uv+F2( 1.0, 1.0)*t,n)*a+
        0.0);}

// Step 2 in generation of the dither source texture.
F1 Step2(F2 uv,F1 n){
    F1 a=1.0,b=2.0,c=-2.0,t=1.0;
    return (4.0/(a*4.0+b*4.0-c))*(
        Step1(uv+F2(-1.0,-1.0)*t,n)*a+
        Step1(uv+F2( 0.0,-1.0)*t,n)*b+
        Step1(uv+F2( 1.0,-1.0)*t,n)*a+
        Step1(uv+F2(-1.0, 0.0)*t,n)*b+
        Step1(uv+F2( 0.0, 0.0)*t,n)*c+
        Step1(uv+F2( 1.0, 0.0)*t,n)*b+
        Step1(uv+F2(-1.0, 1.0)*t,n)*a+
        Step1(uv+F2( 0.0, 1.0)*t,n)*b+
        Step1(uv+F2( 1.0, 1.0)*t,n)*a+
        0.0);}

// Used for stills.
F3 Step3(F2 uv){
    F1 a=Step2(uv,0.07);    
    #ifdef CHROMATIC
    F1 b=Step2(uv,0.11);    
    F1 c=Step2(uv,0.13);
    return F3(a,b,c);
    #else
    // Monochrome can look better on stills.
    return F3(a, a, a);
    #endif
}

// Used for temporal dither.
F3 Step3T(F2 uv){
    F1 a=Step2(uv,0.07*(fract(iGlobalTime)+1.0));
    F1 b=Step2(uv,0.11*(fract(iGlobalTime)+1.0));
    F1 c=Step2(uv,0.13*(fract(iGlobalTime)+1.0));
    return F3(a,b,c);}

F1 InterleavedGradientNoise( F2 uv )
{
	const F3 magic = F3( 0.06711056, 0.00583715, 52.9829189 );
	F1 n = fract( magic.z * fract( dot( uv, magic.xy ) ) );
	return n * 2.0 - 1.0;
}

F1 Bayer( F2 uv )
{
	return (tex2D(_BayerTex, uv * _BayerTex_TexelSize.xy).r) * 2.0 - 1.0;
}
// ====

///
/// Vertex
///
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 texcoord1 : TEXCOORD1;
};

struct v2f
{
    float4 uv : TEXCOORD0;
    SHADOW_COORDS(1) // put shadows data into TEXCOORD1
    float3 worldNormal : TEXCOORD2;
    float4 worldPosAndZ : TEXCOORD3;
    float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv.xy = v.texcoord;
    o.uv.zw = v.texcoord1;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPosAndZ.xyz = mul(_Object2World, v.vertex).xyz;
    COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
    // compute shadows data
    TRANSFER_SHADOW(o)
    return o;
}

///
/// Fragment
///
uniform sampler2D _MainTex;
uniform sampler2D _DiffuseLUTTex;

#if _OVERLAY_ON
uniform sampler2D _OverlayTex;
#endif

#if _DIM_ON
uniform sampler2D _DimTex;
#endif

#if _RIM_ON
uniform sampler2D _RimLUTTex;
uniform float _RimIntensity;
#endif

half dither(in v2f i)
{
	half d1 = Bayer(i.pos.xy);
	half d2 = InterleavedGradientNoise(i.pos.xy);

	//return clamp(d2 + d1 * 0.5, -1, 1);
	//return clamp(d1 + d2 * 0.0625, -1, 1);
	//return (d1 + d2) * 0.5;
	return d1;
	//return d2;
}

half shadowTerm(in v2f i)
{
	half s = SHADOW_ATTENUATION(i);
	return s;
}

half shadowTermWithDither(in v2f i)
{
	half s = SHADOW_ATTENUATION(i);
	half d = InterleavedGradientNoise(i.pos.xy * 0.5 + iGlobalTime);
	s = clamp(s * (s + 0.25 * d), 0, 1);
	//d = d * 0.5 + 0.5;
	//d = (1-cos(d * d * 3.1415926)) / 2;
	//s = lerp(1 - pow(1-s, 2), s, d);
	return s;
}

void fade(in v2f i, fixed vface)
{
	half viewZ = i.worldPosAndZ.w;
	half d = dither(i);

	//if (vface < 1)
	//	clip(d);

	half bZ = _ProjectionParams.y * 2;
	half eZ = _ProjectionParams.y * 6;
	half rZ = eZ - bZ;
	half f = (viewZ - bZ) / rZ; // do not clamp f to [0, 1]

	f = f + d * rZ;
	clip(f);
}

half3 lighting(in v2f i, in half3 albedo, in half ndotl, in half shadow)
{
#if _DIM_ON
	half3 dark = tex2D(_DimTex, i.uv.xy);
#else
	half3 dark = pow(albedo * 0.9, 2.0);
#endif

	ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * shadow).r;
	
	return lerp(dark, albedo, ndotl) * _LightColor0.rgb;
}

void darkout(inout half3 col, fixed vface)
{
	if (vface < 0)
    	col *= 0.25;
}

half4 fetchAlbedo(v2f i)
{
	half4 albedo = tex2D(_MainTex, i.uv.xy);
#if _OVERLAY_ON
	half4 overlay = tex2D(_OverlayTex, i.uv.zw);

	half t = overlay.a;
	t = (1-cos(t*3.1415926)) / 2;

	albedo.rgb = lerp(albedo.rgb, overlay.rgb, t);
#endif
	return albedo;
}

half4 frag_base (v2f i, fixed vface : VFACE) : SV_Target
{
   	fade(i, vface);

    fixed shadow = shadowTerm(i);

    half3 worldNormal = normalize(i.worldNormal) * vface;

    half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);

    half4 albedo = fetchAlbedo(i);

    half3 col = lighting(i, albedo, ndotl, shadow);

#if _RIM_ON
	half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);

	half vdotl = dot(worldNormal, worldViewDir);
	vdotl = tex2D(_RimLUTTex, saturate(vdotl * 0.5 + 0.5)).r;

	col += vdotl * albedo * _RimIntensity;

#endif

    darkout(col, vface);

    return half4(col, 1);
}


half4 frag_add (v2f i, fixed vface : VFACE) : SV_Target
{
	fade(i, vface);

    fixed shadow = shadowTerm(i);

    half3 worldNormal = normalize(i.worldNormal) * vface;

    half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);

    half4 albedo = fetchAlbedo(i);

    half3 col = lighting(i, albedo, ndotl, shadow);

    darkout(col, vface);

    MGFX_LIGHT_ATTENUATION(lightAtten, i, i.worldPosAndZ.xyz);
    col *= lightAtten;

    return half4(col, 1);
}
    ENDCG

    SubShader
    {
Tags
{ 
	"RenderType"="Opaque"
}

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
	#pragma shader_feature _OVERLAY_ON
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
	#pragma shader_feature _OVERLAY_ON

	ENDCG
}

// shadow casting support
UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}