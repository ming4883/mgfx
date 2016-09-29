Shader "MGFX/NPR/Hair"
{
    Properties
    {
_FadeOut ("_FadeOut", Range(0,1)) = 0.0

[NoScaleOffset] _BayerTex ("Bayer Matrix", 2D) = "white" {}

[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}

[NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT", 2D) = "white" {}
[NoScaleOffset] _SpecularLUTTex ("Specular LUT", 2D) = "white" {}

[Toggle(_NORMAL_MAP_ON)] _NormalMapOn("Enable NormalMap", Int) = 0
[NoScaleOffset] _NormalMapTex ("Normal Map", 2D) = "black" {}

[Toggle(_DIM_ON)] _DimOn("Enable Dim", Int) = 0
[NoScaleOffset] _DimTex ("Dim (RGB)", 2D) = "white" {}

[Toggle(_RIM_ON)] _RimOn("Enable Rim", Int) = 0
[NoScaleOffset] _RimLUTTex ("Rim LUT (R)", 2D) = "white" {}
_RimIntensity ("RimIntensity", Range(0,2)) = 1.0


    }

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
			Cull Back

			CGPROGRAM
			#include "UnityCG.cginc"

#if UNITY_VERSION < 540
#define UNITY_SHADER_NO_UPGRADE
#define unity_ObjectToWorld _Object2World 
#define unity_WorldToObject _World2Object
#define unity_WorldToLight _LightMatrix0
#define unity_WorldToCamera _WorldToCamera
#define unity_CameraToWorld _CameraToWorld
#define unity_Projector _Projector
#define unity_ProjectorDistance _ProjectorDistance
#define unity_ProjectorClip _ProjectorClip
#define unity_GUIClipTextureMatrix _GUIClipTextureMatrix 
#endif

			#include "Lighting.cginc"
#include "AutoLight.cginc"

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


half3 autoLightDir()
{
    half3 camRight = UNITY_MATRIX_V[0].xyz;
    half3 camFwd = UNITY_MATRIX_V[2].xyz;
    half3 worldUp = half3(0, 1, 0);

    return normalize(camFwd);
    //return normalize(camFwd + camRight * -0.125f + worldUp * 0.5);
}

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
	F2 val = dot(tex2D(_BayerTex, uv * _BayerTex_TexelSize.xy).rg, F2(256.0 * 255.0, 255.0));
	val = val * _BayerTex_TexelSize.x * _BayerTex_TexelSize.y;
	return val * 2.0 - 1.0;
	//return (tex2D(_BayerTex, uv * _BayerTex_TexelSize.xy).r) * 2.0 - 1.0;
}
// ====

			#pragma vertex vert
#pragma fragment frag_base
#pragma multi_compile_fwdbase novertexlight
#pragma target 3.0

#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIM_ON
#pragma shader_feature _RIM_ON

//#pragma enable_d3d11_debug_symbols
			/// Vertex
///
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 vcolor : COLOR;
    float2 texcoord : TEXCOORD0;

#if _NORMAL_MAP_ON
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 vcolor : COLOR;
    float4 uv : TEXCOORD0;
    SHADOW_COORDS(1) // put shadows data into TEXCOORD1
    float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

    float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.vcolor = v.vcolor;
    o.uv = v.texcoord.xyxy;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);

#if _NORMAL_MAP_ON
	float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	o.tanSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, 0);
	o.tanSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, 0);
	o.tanSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, 0);
#else
	o.worldNormal = worldNormal;
#endif

    o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

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
uniform sampler2D _SpecularLUTTex;

uniform float _FadeOut;

uniform sampler2D _MudSSAOTex; // global property

#if _NORMAL_MAP_ON
uniform sampler2D _NormalMapTex;
#endif

#if _DIM_ON
uniform sampler2D _DimTex;
#endif

#if _RIM_ON
uniform sampler2D _RimLUTTex;
uniform float _RimIntensity;
#endif

struct ShadingContext
{
	half4 albedo;
	half4 dimmed;
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	fixed vface;
	fixed shadow;
	half4 result;
};

void fetchWorldNormal(inout ShadingContext ctx, in v2f i)
{
#if _NORMAL_MAP_ON
	half3 tanNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv.xy));
	half3 worldNormal;
	worldNormal.x = dot(i.tanSpace0.xyz, tanNormal);
	worldNormal.y = dot(i.tanSpace1.xyz, tanNormal);
	worldNormal.z = dot(i.tanSpace2.xyz, tanNormal);
	ctx.worldNormal = normalize(worldNormal);
#else
	ctx.worldNormal = normalize(i.worldNormal);
#endif

#ifdef BACKFACE_ON
	ctx.worldNormal *= -1;
#endif

	ctx.worldPos = i.worldPosAndZ.xyz;
	ctx.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);

}

void fetchShadowTerm(inout ShadingContext ctx, in v2f i)
{
#if !defined(BACKFACE_ON)
	ctx.shadow = SHADOW_ATTENUATION(i);
#else
	ctx.shadow = 1;
#endif
}

void fetchAlbedoAndDimmed(inout ShadingContext ctx, in v2f i)
{
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

#if _DIM_ON
	ctx.dimmed = tex2D(_DimTex, i.uv.xy);
#else
	half3 dimmed = ctx.albedo.rgb * 0.875;
	dimmed = dimmed * dimmed;
	ctx.dimmed = half4(dimmed, ctx.albedo.a);
#endif
}

void applyLightingFwdBase(inout ShadingContext ctx, in v2f i)
{
	half2 screenuv = i.pos.xy * _ScreenParams.zw - i.pos.xy;
	half occl = tex2D(_MudSSAOTex, screenuv).r;
	occl = saturate(occl * occl * 4);
	occl = 1 - occl;

	half ndotl = dot(ctx.worldNormal, autoLightDir());
	ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
	ndotl = lerp(1.0, ndotl * occl, i.vcolor.a);

	half3 lighting = lerp(ctx.dimmed, ctx.albedo, ndotl) * _LightColor0.rgb;

	ctx.result.rgb += lighting;
}

void applyLightingFwdAdd(inout ShadingContext ctx, in v2f i)
{
    UNITY_LIGHT_ATTENUATION(lightShadowAndAtten, i, i.worldPosAndZ.xyz);

	half ndotl = dot(ctx.worldNormal, normalize(_WorldSpaceLightPos0.xyz - ctx.worldPos));

	ndotl = saturate(ndotl) * ctx.shadow;

	ctx.result.rgb += lerp(ctx.dimmed, ctx.albedo, ndotl) * _LightColor0.rgb * lightShadowAndAtten;
}

void applyRim(inout ShadingContext ctx, in v2f i)
{
#if _RIM_ON
	half vdotl = dot(ctx.worldNormal, ctx.worldViewDir);
	vdotl = tex2D(_RimLUTTex, saturate(vdotl * 0.5 + 0.5)).r;

	ctx.result.rgb += vdotl * ctx.albedo * _RimIntensity;

#endif
}

void applySpecular(inout ShadingContext ctx, in v2f i)
{
	half3 worldNormal = ctx.worldNormal;

	half3 worldRLight = normalize(reflect(half3(0, -1, 0), worldNormal));

	half2 specUV = half2(saturate(dot(worldRLight, ctx.worldViewDir) * 0.5 + 0.5), 0.5);

	half4 spec = tex2D(_SpecularLUTTex, specUV);
	spec = spec * ctx.albedo.a;
	spec.rgb *= ctx.albedo.rgb;

	ctx.result.rgb += spec;
}

void shadingContext(inout ShadingContext ctx, in v2f i, in fixed vface)
{
	ctx = (ShadingContext)0;
	ctx.vface = vface;
	fetchAlbedoAndDimmed(ctx, i);
	fetchShadowTerm(ctx, i);
	fetchWorldNormal(ctx, i);

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}


half dither(in v2f i)
{
	half d1 = Bayer(i.pos.xy + float2(UNITY_MATRIX_MV._14, UNITY_MATRIX_MV._24));
	//half d2 = InterleavedGradientNoise(i.pos.xy);
	//return (d1 + d2) * 0.5;
	return d1;
}

void fade(inout ShadingContext ctx, in v2f i)
{
	half viewZ = i.worldPosAndZ.w;
	half d = dither(i);

	half fading = _FadeOut;
	fading = fading * 2.0 - 1.0;
	clip(d - fading);

#if _TEXTURE_FADE_OUT_ON
	clip(d + ctx.albedo.a);
#endif

	half bZ = _ProjectionParams.y * 2;
	half eZ = _ProjectionParams.y * 6;
	half rZ = eZ - bZ;
	half f = (viewZ - bZ) / rZ; // do not clamp f to [0, 1]

	f = f + d * rZ;
	clip(f);
}


half4 frag_base (v2f i, fixed vface : VFACE) : SV_Target
{
    ShadingContext ctx;
    shadingContext(ctx, i, vface);

   	fade(ctx, i);

	applyLightingFwdBase(ctx, i);

	applyRim(ctx, i);

	applySpecular(ctx, i);

    return ctx.result;
}


half4 frag_add (v2f i, fixed vface : VFACE) : SV_Target
{
    ShadingContext ctx;
    shadingContext(ctx, i, vface);

    fade(ctx, i);

    applyLightingFwdAdd(ctx, i);

    return ctx.result;
}
			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardAdd"
			}

			ZWrite Off
			ZTest LEqual
			Blend One One
			Cull Back

			CGPROGRAM
			#include "UnityCG.cginc"

#if UNITY_VERSION < 540
#define UNITY_SHADER_NO_UPGRADE
#define unity_ObjectToWorld _Object2World 
#define unity_WorldToObject _World2Object
#define unity_WorldToLight _LightMatrix0
#define unity_WorldToCamera _WorldToCamera
#define unity_CameraToWorld _CameraToWorld
#define unity_Projector _Projector
#define unity_ProjectorDistance _ProjectorDistance
#define unity_ProjectorClip _ProjectorClip
#define unity_GUIClipTextureMatrix _GUIClipTextureMatrix 
#endif

			#include "Lighting.cginc"
#include "AutoLight.cginc"

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


half3 autoLightDir()
{
    half3 camRight = UNITY_MATRIX_V[0].xyz;
    half3 camFwd = UNITY_MATRIX_V[2].xyz;
    half3 worldUp = half3(0, 1, 0);

    return normalize(camFwd);
    //return normalize(camFwd + camRight * -0.125f + worldUp * 0.5);
}

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
	F2 val = dot(tex2D(_BayerTex, uv * _BayerTex_TexelSize.xy).rg, F2(256.0 * 255.0, 255.0));
	val = val * _BayerTex_TexelSize.x * _BayerTex_TexelSize.y;
	return val * 2.0 - 1.0;
	//return (tex2D(_BayerTex, uv * _BayerTex_TexelSize.xy).r) * 2.0 - 1.0;
}
// ====

			#pragma vertex vert
#pragma fragment frag_add
#pragma multi_compile_fwdadd_fullshadows
#pragma target 3.0

#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIM_ON
//#pragma enable_d3d11_debug_symbols
			/// Vertex
///
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 vcolor : COLOR;
    float2 texcoord : TEXCOORD0;

#if _NORMAL_MAP_ON
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 vcolor : COLOR;
    float4 uv : TEXCOORD0;
    SHADOW_COORDS(1) // put shadows data into TEXCOORD1
    float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

    float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.vcolor = v.vcolor;
    o.uv = v.texcoord.xyxy;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);

#if _NORMAL_MAP_ON
	float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	o.tanSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, 0);
	o.tanSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, 0);
	o.tanSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, 0);
#else
	o.worldNormal = worldNormal;
#endif

    o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

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
uniform sampler2D _SpecularLUTTex;

uniform float _FadeOut;

uniform sampler2D _MudSSAOTex; // global property

#if _NORMAL_MAP_ON
uniform sampler2D _NormalMapTex;
#endif

#if _DIM_ON
uniform sampler2D _DimTex;
#endif

#if _RIM_ON
uniform sampler2D _RimLUTTex;
uniform float _RimIntensity;
#endif

struct ShadingContext
{
	half4 albedo;
	half4 dimmed;
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	fixed vface;
	fixed shadow;
	half4 result;
};

void fetchWorldNormal(inout ShadingContext ctx, in v2f i)
{
#if _NORMAL_MAP_ON
	half3 tanNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv.xy));
	half3 worldNormal;
	worldNormal.x = dot(i.tanSpace0.xyz, tanNormal);
	worldNormal.y = dot(i.tanSpace1.xyz, tanNormal);
	worldNormal.z = dot(i.tanSpace2.xyz, tanNormal);
	ctx.worldNormal = normalize(worldNormal);
#else
	ctx.worldNormal = normalize(i.worldNormal);
#endif

#ifdef BACKFACE_ON
	ctx.worldNormal *= -1;
#endif

	ctx.worldPos = i.worldPosAndZ.xyz;
	ctx.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);

}

void fetchShadowTerm(inout ShadingContext ctx, in v2f i)
{
#if !defined(BACKFACE_ON)
	ctx.shadow = SHADOW_ATTENUATION(i);
#else
	ctx.shadow = 1;
#endif
}

void fetchAlbedoAndDimmed(inout ShadingContext ctx, in v2f i)
{
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

#if _DIM_ON
	ctx.dimmed = tex2D(_DimTex, i.uv.xy);
#else
	half3 dimmed = ctx.albedo.rgb * 0.875;
	dimmed = dimmed * dimmed;
	ctx.dimmed = half4(dimmed, ctx.albedo.a);
#endif
}

void applyLightingFwdBase(inout ShadingContext ctx, in v2f i)
{
	half2 screenuv = i.pos.xy * _ScreenParams.zw - i.pos.xy;
	half occl = tex2D(_MudSSAOTex, screenuv).r;
	occl = saturate(occl * occl * 4);
	occl = 1 - occl;

	half ndotl = dot(ctx.worldNormal, autoLightDir());
	ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
	ndotl = lerp(1.0, ndotl * occl, i.vcolor.a);

	half3 lighting = lerp(ctx.dimmed, ctx.albedo, ndotl) * _LightColor0.rgb;

	ctx.result.rgb += lighting;
}

void applyLightingFwdAdd(inout ShadingContext ctx, in v2f i)
{
    UNITY_LIGHT_ATTENUATION(lightShadowAndAtten, i, i.worldPosAndZ.xyz);

	half ndotl = dot(ctx.worldNormal, normalize(_WorldSpaceLightPos0.xyz - ctx.worldPos));

	ndotl = saturate(ndotl) * ctx.shadow;

	ctx.result.rgb += lerp(ctx.dimmed, ctx.albedo, ndotl) * _LightColor0.rgb * lightShadowAndAtten;
}

void applyRim(inout ShadingContext ctx, in v2f i)
{
#if _RIM_ON
	half vdotl = dot(ctx.worldNormal, ctx.worldViewDir);
	vdotl = tex2D(_RimLUTTex, saturate(vdotl * 0.5 + 0.5)).r;

	ctx.result.rgb += vdotl * ctx.albedo * _RimIntensity;

#endif
}

void applySpecular(inout ShadingContext ctx, in v2f i)
{
	half3 worldNormal = ctx.worldNormal;

	half3 worldRLight = normalize(reflect(half3(0, -1, 0), worldNormal));

	half2 specUV = half2(saturate(dot(worldRLight, ctx.worldViewDir) * 0.5 + 0.5), 0.5);

	half4 spec = tex2D(_SpecularLUTTex, specUV);
	spec = spec * ctx.albedo.a;
	spec.rgb *= ctx.albedo.rgb;

	ctx.result.rgb += spec;
}

void shadingContext(inout ShadingContext ctx, in v2f i, in fixed vface)
{
	ctx = (ShadingContext)0;
	ctx.vface = vface;
	fetchAlbedoAndDimmed(ctx, i);
	fetchShadowTerm(ctx, i);
	fetchWorldNormal(ctx, i);

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}


half dither(in v2f i)
{
	half d1 = Bayer(i.pos.xy + float2(UNITY_MATRIX_MV._14, UNITY_MATRIX_MV._24));
	//half d2 = InterleavedGradientNoise(i.pos.xy);
	//return (d1 + d2) * 0.5;
	return d1;
}

void fade(inout ShadingContext ctx, in v2f i)
{
	half viewZ = i.worldPosAndZ.w;
	half d = dither(i);

	half fading = _FadeOut;
	fading = fading * 2.0 - 1.0;
	clip(d - fading);

#if _TEXTURE_FADE_OUT_ON
	clip(d + ctx.albedo.a);
#endif

	half bZ = _ProjectionParams.y * 2;
	half eZ = _ProjectionParams.y * 6;
	half rZ = eZ - bZ;
	half f = (viewZ - bZ) / rZ; // do not clamp f to [0, 1]

	f = f + d * rZ;
	clip(f);
}


half4 frag_base (v2f i, fixed vface : VFACE) : SV_Target
{
    ShadingContext ctx;
    shadingContext(ctx, i, vface);

   	fade(ctx, i);

	applyLightingFwdBase(ctx, i);

	applyRim(ctx, i);

	applySpecular(ctx, i);

    return ctx.result;
}


half4 frag_add (v2f i, fixed vface : VFACE) : SV_Target
{
    ShadingContext ctx;
    shadingContext(ctx, i, vface);

    fade(ctx, i);

    applyLightingFwdAdd(ctx, i);

    return ctx.result;
}
			ENDCG
		}
		
		// shadow casting support
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }

    CustomEditor "Minv.NPRHairUI"
}