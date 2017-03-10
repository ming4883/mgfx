Shader "MGFX/Mobile/Transparent"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
[HDR] _Color ("Color", Color) = (1.0, 1.0, 1.0, 0.0)

[Toggle(_REALTIME_LIGHTING_ON)] _RealtimeLightingOn("Enable Realtime Lighting", Int) = 1

[Toggle(_REFLECTION_PROBES_ON)] _ReflectionProbesOn("Enable Reflection Probes", Int) = 0
_ReflectionIntensity ("Reflection Intensity", Range(0,8)) = 1.0

[NoScaleOffset] _GIAlbedoTex ("GI Albedo Tex", 2D) = "white" {}
[HDR] _GIAlbedoColor ("GI Albedo Color", Color) = (1.0, 1.0, 1.0, 0.0)

[NoScaleOffset] _GIEmissionTex ("GI Emission Tex", 2D) = "white" {}
[HDR] _GIEmissionColor ("GI Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)

[Toggle(_GI_IRRADIANCE_ON)] _GIIrradianceOn("Enable GI Irradiance", Int) = 1
_GIIrradianceIntensity ("Irradiance Intensity", Range(0,8)) = 1.0

[Toggle(_NORMAL_MAP_ON)] _NormalMapOn("Enable NormalMap", Int) = 0
[NoScaleOffset] _NormalMapTex ("Normal Map", 2D) = "black" {}

[Toggle(_DIFFUSE_LUT_ON)] _DiffuseLUTOn("Enable Diffuse LUT", Int) = 0
[NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}

[Toggle(_MATCAP_ON)] _MatCapOn("Enable MatCap", Int) = 0
[Toggle(_MATCAP_PLANAR_ON)] _MatCapPlanarOn("MatCap Planar Mode", Int) = 0
[Toggle(_MATCAP_ALBEDO_ON)] _MatCapAlbedoOn("MatCap Albedo Mode", Int) = 0
[NoScaleOffset] _MatCapTex ("MatCap", 2D) = "black" {}
_MatCapIntensity ("MatCapIntensity", Range(0,4)) = 1.0

	}

	// ---------------------
	// High Quality
	
	
	SubShader
	{
		LOD 300

		Tags
		{ 
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
		#pragma target 3.0
		#define SHADING_QUALITY SHADING_QUALITY_HIGH
	
			
half2 matCapUV(half3 worldNormal, half3 worldViewDir)
{
	half3 rx = half3(1, 0, 0);
	half3 ry = half3(0, 1, 0);
	half3 rz = UNITY_MATRIX_V[2].xyz;

	rx = cross(ry, rz);
	ry = cross(rz, rx);

	half3x3 m;
	m[0] = rx;
	m[1] = -ry;
	m[2] = rz;

	half2 uv;
	#if _MATCAP_PLANAR_ON
	{
		half3 dir = reflect(worldViewDir, worldNormal);
		dir = normalize(mul(m, dir));
		uv = saturate(dir.xy * 0.5 + 0.5);
	}
	#else
	{
		half3 viewNormal = mul(m, worldNormal);
		uv = saturate(viewNormal.xy * 0.5 + 0.5);
	}
	#endif

	return uv;
}

			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

/// override shading feature for quaity

#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _NORMAL_MAP_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _NORMAL_MAP_ON
		#define _NORMAL_MAP_ON 0
	#endif
#endif

#if _REFLECTION_PROBES_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _REFLECTION_PROBES_ON
		#define _REFLECTION_PROBES_ON 0
	#endif
#endif

/// Vertex
///
struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 vcolor : COLOR;
	float2 texcoord0 : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
	
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dlmapcoord : TEXCOORD2;
#endif

#if _NORMAL_MAP_ON
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 ambientOrLightmapUV : TEXCOORD2;
	float4 worldPosAndZ : TEXCOORD3;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD4;
	float4 tanSpace1 : TEXCOORD5;
	float4 tanSpace2 : TEXCOORD6;
#else
	float3 worldNormal : TEXCOORD4;
#endif

	float4 pos : SV_POSITION;
};


inline half4 VertexGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		ambientOrLightmapUV.zw = 0;
	}
	#elif UNITY_SHOULD_SAMPLE_SH
	{
		// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
		ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, ambientOrLightmapUV.rgb);
	}
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
	{
		ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = float4(v.texcoord0.xy, v.texcoord1.xy);

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(v.normal);

	#if _NORMAL_MAP_ON
	{
		float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
		o.tanSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, 0);
		o.tanSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, 0);
		o.tanSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, 0);
	}
	#else
	{
		o.worldNormal = worldNormal;

		#if _MATCAP_ON
		{
			half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPosAndZ.xyz);
			o.uv.zw = matCapUV(worldNormal, worldViewDir);
		}
		#endif
	}
	#endif

	o.ambientOrLightmapUV = VertexGIForward(v, o.worldPosAndZ.xyz, o.worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;

#if _REFLECTION_PROBES_ON
uniform float _ReflectionIntensity;
#endif

#if _GI_IRRADIANCE_ON
uniform float _GIIrradianceIntensity;
#endif

#if _NORMAL_MAP_ON
uniform sampler2D _NormalMapTex;
#endif

#if _DIFFUSE_LUT_ON
uniform sampler2D _DiffuseLUTTex;
#endif

#if _MATCAP_ON
uniform sampler2D _MatCapTex;
uniform float _MatCapIntensity;
#endif

struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	half3 shadow;
	half4 result;
	half4 sv_pos;
};

#if defined(SHADER_API_PSSL)
void shadingContext(inout ShadingContext ctx, in v2f i, in uint vface)
#else
void shadingContext(inout ShadingContext ctx, in v2f i, in fixed vface)
#endif
{
	ctx.sv_pos = i.pos;
	ctx.uv = i.uv;
	ctx.vface = vface > 0 ? 1.0 : -1.0;
	ctx.albedo = tex2D(_MainTex, i.uv.xy) * _Color;
	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
		ctx.shadow = atten;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		ctx.shadow = 1;
	}
	#endif

	#if _NORMAL_MAP_ON
	{
		half3 tanNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv.xy));
		half3 worldNormal;
		worldNormal.x = dot(i.tanSpace0.xyz, tanNormal);
		worldNormal.y = dot(i.tanSpace1.xyz, tanNormal);
		worldNormal.z = dot(i.tanSpace2.xyz, tanNormal);
		ctx.worldNormal = normalize(worldNormal) * ctx.vface;
	}
	#else
	{
		//ctx.worldNormal = normalize(i.worldNormal) * vface;
		ctx.worldNormal = i.worldNormal * ctx.vface;
		#if SHADING_QUALITY >= SHADING_QUALITY_MEDIUM
		{
			ctx.worldNormal = normalize(ctx.worldNormal);
		}
		#endif
	}
	#endif

	ctx.worldPos = i.worldPosAndZ.xyz;
	ctx.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);
	ctx.eyeDepth = i.worldPosAndZ.w;
	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

UnityLight MainLight ()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		UnityLight light = MainLight();

		half ndotl = dot(ctx.worldNormal, light.dir);

		#if _DIFFUSE_LUT_ON
		{
			ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5)).r;
		}
		#else
		{
			ndotl = saturate(ndotl);
		}
		#endif

		half3 diff = 0;

		#if _GI_IRRADIANCE_ON
		{
			UnityGIInput d;
			d.light = light;
			d.worldPos = ctx.worldPos;
			d.worldViewDir = ctx.worldViewDir;
			d.atten = ctx.shadow;
			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
			{
				d.ambient = 0;
				d.lightmapUV = ctx.ambientOrLightmapUV;
			}
			#else
			{
				d.ambient = ctx.ambientOrLightmapUV.rgb;
				d.lightmapUV = 0;
			}
			#endif

			#if defined(LIGHTMAP_ON)
			{
				half bakedAtten = UnitySampleBakedOcclusion(d.lightmapUV.xy, ctx.worldPos);

				#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
				{
					//float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, dot(_WorldSpaceCameraPos - ctx.worldPos, UNITY_MATRIX_V[2].xyz));
					float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, -ctx.eyeDepth);
					bakedAtten = UnityMixRealtimeAndBakedShadows(d.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
				}
				#endif

				d.atten = bakedAtten;
			}
			#endif

			UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);

			diff += gi.indirect.diffuse + gi.light.color * ndotl;

			ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
		}
		#else // _GI_IRRADIANCE_ON
		{
			diff += ctx.shadow * ndotl * light.color;
		}
		#endif

		ctx.result.rgb = ctx.albedo.rgb * diff;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow + unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow;
		}
		#endif
	}
	#endif
}

void applyLightingFwdAdd(inout ShadingContext ctx)
{
	half ndotl = dot(ctx.worldNormal, normalize(_WorldSpaceLightPos0.xyz - ctx.worldPos));
	#if _DIFFUSE_LUT_ON
	{
		ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
	}
	#else
	{
		ndotl = saturate(ndotl) * ctx.shadow;
	}
	#endif
	
	ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
}

void applyMatcap(inout ShadingContext ctx)
{
	#if _MATCAP_ON
	{
		half2 uv;

		#if _NORMAL_MAP_ON
		{
			uv = matCapUV(ctx.worldNormal, ctx.worldViewDir);
		}
		#else
		{
			uv = ctx.uv.zw;
		}
		#endif

		half4 matCap = tex2D(_MatCapTex, uv);
		matCap = matCap * ctx.albedo.a * _MatCapIntensity;
		#if _MATCAP_ALBEDO_ON
		{
			matCap.rgb *= ctx.albedo.rgb;
		}
		#endif
		ctx.result.rgb += matCap;
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		half3 worldNormalRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
		float blendDistance = unity_SpecCube1_ProbePosition.w; // will be set to blend distance for this probe

#if UNITY_SPECCUBE_BOX_PROJECTION
		// For box projection, use expanded bounds as they are rendered; otherwise
		// box projection artifacts when outside of the box.
		float4 boxMin = unity_SpecCube0_BoxMin - float4(blendDistance, blendDistance, blendDistance, 0);
		float4 boxMax = unity_SpecCube0_BoxMax + float4(blendDistance, blendDistance, blendDistance, 0);
		half3 reflDir = BoxProjectedCubemapDirection(worldNormalRefl, ctx.worldPos, unity_SpecCube0_ProbePosition, boxMin, boxMax);
#else
		half3 reflDir = worldNormalRefl;
#endif

		float4 refl = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 1);
		refl.rgb = DecodeHDR_NoLinearSupportInSM2(refl, unity_SpecCube0_HDR);

		half fren = dot(ctx.worldViewDir, ctx.worldNormal);
		fren = saturate(fren);
		fren = saturate(1 - fren * fren + 0.25) * ctx.occlusion;
		
		ctx.result.rgb = lerp(ctx.result.rgb, (half3)refl.rgb * _ReflectionIntensity, ctx.albedo.a * fren);
	}
#endif
}

#if defined(SHADER_API_PSSL)
half4 frag_base(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_base(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdBase(ctx);

	applyMatcap(ctx);

	applyReflectionProbes(ctx);

	return ctx.result;
}


#if defined(SHADER_API_PSSL)
half4 frag_add(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_add(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdAdd(ctx);

	return ctx.result;
}

			#pragma multi_compile_fwdbase

			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _REFLECTION_PROBES_ON
			#pragma shader_feature _GI_IRRADIANCE_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON
			#pragma shader_feature _MATCAP_ON
			#pragma shader_feature _MATCAP_PLANAR_ON
			#pragma shader_feature _MATCAP_ALBEDO_ON

			#pragma vertex vert
			#pragma fragment frag_base
			ENDCG
		}
		
		Pass
		{
			Name "META"
			Tags
			{
				"LightMode"="Meta"
			}

			Cull Off

			CGPROGRAM
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

			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Cull Off

			CGPROGRAM
			#pragma vertex vert_shadowcaster
#pragma fragment frag_shadowcaster
#pragma target 2.0
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"

struct v2f_shadowcaster { 
	V2F_SHADOW_CASTER;
};

v2f_shadowcaster vert_shadowcaster( appdata_base v )
{
	v2f_shadowcaster o;
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}

float4 frag_shadowcaster( v2f_shadowcaster i ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}
			ENDCG
		}
	}

	// ---------------------
	// Medium Quality
	
	
	SubShader
	{
		LOD 200

		Tags
		{ 
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
		#pragma target 2.0
		#define SHADING_QUALITY SHADING_QUALITY_MEDIUM
	
			
half2 matCapUV(half3 worldNormal, half3 worldViewDir)
{
	half3 rx = half3(1, 0, 0);
	half3 ry = half3(0, 1, 0);
	half3 rz = UNITY_MATRIX_V[2].xyz;

	rx = cross(ry, rz);
	ry = cross(rz, rx);

	half3x3 m;
	m[0] = rx;
	m[1] = -ry;
	m[2] = rz;

	half2 uv;
	#if _MATCAP_PLANAR_ON
	{
		half3 dir = reflect(worldViewDir, worldNormal);
		dir = normalize(mul(m, dir));
		uv = saturate(dir.xy * 0.5 + 0.5);
	}
	#else
	{
		half3 viewNormal = mul(m, worldNormal);
		uv = saturate(viewNormal.xy * 0.5 + 0.5);
	}
	#endif

	return uv;
}

			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

/// override shading feature for quaity

#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _NORMAL_MAP_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _NORMAL_MAP_ON
		#define _NORMAL_MAP_ON 0
	#endif
#endif

#if _REFLECTION_PROBES_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _REFLECTION_PROBES_ON
		#define _REFLECTION_PROBES_ON 0
	#endif
#endif

/// Vertex
///
struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 vcolor : COLOR;
	float2 texcoord0 : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
	
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dlmapcoord : TEXCOORD2;
#endif

#if _NORMAL_MAP_ON
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 ambientOrLightmapUV : TEXCOORD2;
	float4 worldPosAndZ : TEXCOORD3;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD4;
	float4 tanSpace1 : TEXCOORD5;
	float4 tanSpace2 : TEXCOORD6;
#else
	float3 worldNormal : TEXCOORD4;
#endif

	float4 pos : SV_POSITION;
};


inline half4 VertexGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		ambientOrLightmapUV.zw = 0;
	}
	#elif UNITY_SHOULD_SAMPLE_SH
	{
		// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
		ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, ambientOrLightmapUV.rgb);
	}
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
	{
		ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = float4(v.texcoord0.xy, v.texcoord1.xy);

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(v.normal);

	#if _NORMAL_MAP_ON
	{
		float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
		o.tanSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, 0);
		o.tanSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, 0);
		o.tanSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, 0);
	}
	#else
	{
		o.worldNormal = worldNormal;

		#if _MATCAP_ON
		{
			half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPosAndZ.xyz);
			o.uv.zw = matCapUV(worldNormal, worldViewDir);
		}
		#endif
	}
	#endif

	o.ambientOrLightmapUV = VertexGIForward(v, o.worldPosAndZ.xyz, o.worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;

#if _REFLECTION_PROBES_ON
uniform float _ReflectionIntensity;
#endif

#if _GI_IRRADIANCE_ON
uniform float _GIIrradianceIntensity;
#endif

#if _NORMAL_MAP_ON
uniform sampler2D _NormalMapTex;
#endif

#if _DIFFUSE_LUT_ON
uniform sampler2D _DiffuseLUTTex;
#endif

#if _MATCAP_ON
uniform sampler2D _MatCapTex;
uniform float _MatCapIntensity;
#endif

struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	half3 shadow;
	half4 result;
	half4 sv_pos;
};

#if defined(SHADER_API_PSSL)
void shadingContext(inout ShadingContext ctx, in v2f i, in uint vface)
#else
void shadingContext(inout ShadingContext ctx, in v2f i, in fixed vface)
#endif
{
	ctx.sv_pos = i.pos;
	ctx.uv = i.uv;
	ctx.vface = vface > 0 ? 1.0 : -1.0;
	ctx.albedo = tex2D(_MainTex, i.uv.xy) * _Color;
	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
		ctx.shadow = atten;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		ctx.shadow = 1;
	}
	#endif

	#if _NORMAL_MAP_ON
	{
		half3 tanNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv.xy));
		half3 worldNormal;
		worldNormal.x = dot(i.tanSpace0.xyz, tanNormal);
		worldNormal.y = dot(i.tanSpace1.xyz, tanNormal);
		worldNormal.z = dot(i.tanSpace2.xyz, tanNormal);
		ctx.worldNormal = normalize(worldNormal) * ctx.vface;
	}
	#else
	{
		//ctx.worldNormal = normalize(i.worldNormal) * vface;
		ctx.worldNormal = i.worldNormal * ctx.vface;
		#if SHADING_QUALITY >= SHADING_QUALITY_MEDIUM
		{
			ctx.worldNormal = normalize(ctx.worldNormal);
		}
		#endif
	}
	#endif

	ctx.worldPos = i.worldPosAndZ.xyz;
	ctx.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);
	ctx.eyeDepth = i.worldPosAndZ.w;
	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

UnityLight MainLight ()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		UnityLight light = MainLight();

		half ndotl = dot(ctx.worldNormal, light.dir);

		#if _DIFFUSE_LUT_ON
		{
			ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5)).r;
		}
		#else
		{
			ndotl = saturate(ndotl);
		}
		#endif

		half3 diff = 0;

		#if _GI_IRRADIANCE_ON
		{
			UnityGIInput d;
			d.light = light;
			d.worldPos = ctx.worldPos;
			d.worldViewDir = ctx.worldViewDir;
			d.atten = ctx.shadow;
			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
			{
				d.ambient = 0;
				d.lightmapUV = ctx.ambientOrLightmapUV;
			}
			#else
			{
				d.ambient = ctx.ambientOrLightmapUV.rgb;
				d.lightmapUV = 0;
			}
			#endif

			#if defined(LIGHTMAP_ON)
			{
				half bakedAtten = UnitySampleBakedOcclusion(d.lightmapUV.xy, ctx.worldPos);

				#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
				{
					//float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, dot(_WorldSpaceCameraPos - ctx.worldPos, UNITY_MATRIX_V[2].xyz));
					float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, -ctx.eyeDepth);
					bakedAtten = UnityMixRealtimeAndBakedShadows(d.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
				}
				#endif

				d.atten = bakedAtten;
			}
			#endif

			UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);

			diff += gi.indirect.diffuse + gi.light.color * ndotl;

			ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
		}
		#else // _GI_IRRADIANCE_ON
		{
			diff += ctx.shadow * ndotl * light.color;
		}
		#endif

		ctx.result.rgb = ctx.albedo.rgb * diff;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow + unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow;
		}
		#endif
	}
	#endif
}

void applyLightingFwdAdd(inout ShadingContext ctx)
{
	half ndotl = dot(ctx.worldNormal, normalize(_WorldSpaceLightPos0.xyz - ctx.worldPos));
	#if _DIFFUSE_LUT_ON
	{
		ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
	}
	#else
	{
		ndotl = saturate(ndotl) * ctx.shadow;
	}
	#endif
	
	ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
}

void applyMatcap(inout ShadingContext ctx)
{
	#if _MATCAP_ON
	{
		half2 uv;

		#if _NORMAL_MAP_ON
		{
			uv = matCapUV(ctx.worldNormal, ctx.worldViewDir);
		}
		#else
		{
			uv = ctx.uv.zw;
		}
		#endif

		half4 matCap = tex2D(_MatCapTex, uv);
		matCap = matCap * ctx.albedo.a * _MatCapIntensity;
		#if _MATCAP_ALBEDO_ON
		{
			matCap.rgb *= ctx.albedo.rgb;
		}
		#endif
		ctx.result.rgb += matCap;
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		half3 worldNormalRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
		float blendDistance = unity_SpecCube1_ProbePosition.w; // will be set to blend distance for this probe

#if UNITY_SPECCUBE_BOX_PROJECTION
		// For box projection, use expanded bounds as they are rendered; otherwise
		// box projection artifacts when outside of the box.
		float4 boxMin = unity_SpecCube0_BoxMin - float4(blendDistance, blendDistance, blendDistance, 0);
		float4 boxMax = unity_SpecCube0_BoxMax + float4(blendDistance, blendDistance, blendDistance, 0);
		half3 reflDir = BoxProjectedCubemapDirection(worldNormalRefl, ctx.worldPos, unity_SpecCube0_ProbePosition, boxMin, boxMax);
#else
		half3 reflDir = worldNormalRefl;
#endif

		float4 refl = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 1);
		refl.rgb = DecodeHDR_NoLinearSupportInSM2(refl, unity_SpecCube0_HDR);

		half fren = dot(ctx.worldViewDir, ctx.worldNormal);
		fren = saturate(fren);
		fren = saturate(1 - fren * fren + 0.25) * ctx.occlusion;
		
		ctx.result.rgb = lerp(ctx.result.rgb, (half3)refl.rgb * _ReflectionIntensity, ctx.albedo.a * fren);
	}
#endif
}

#if defined(SHADER_API_PSSL)
half4 frag_base(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_base(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdBase(ctx);

	applyMatcap(ctx);

	applyReflectionProbes(ctx);

	return ctx.result;
}


#if defined(SHADER_API_PSSL)
half4 frag_add(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_add(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdAdd(ctx);

	return ctx.result;
}

			#pragma multi_compile_fwdbase

			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _REFLECTION_PROBES_ON
			#pragma shader_feature _GI_IRRADIANCE_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON
			#pragma shader_feature _MATCAP_ON
			#pragma shader_feature _MATCAP_PLANAR_ON
			#pragma shader_feature _MATCAP_ALBEDO_ON

			#pragma vertex vert
			#pragma fragment frag_base
			ENDCG
		}
		
		Pass
		{
			Name "META"
			Tags
			{
				"LightMode"="Meta"
			}

			Cull Off

			CGPROGRAM
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

			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Cull Off

			CGPROGRAM
			#pragma vertex vert_shadowcaster
#pragma fragment frag_shadowcaster
#pragma target 2.0
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"

struct v2f_shadowcaster { 
	V2F_SHADOW_CASTER;
};

v2f_shadowcaster vert_shadowcaster( appdata_base v )
{
	v2f_shadowcaster o;
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}

float4 frag_shadowcaster( v2f_shadowcaster i ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}
			ENDCG
		}
	}
	
	// ---------------------
	// Low Quality
	
	
	SubShader
	{
		LOD 100

		Tags
		{ 
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
		#pragma target 2.0
		#define SHADING_QUALITY SHADING_QUALITY_LOW
	
			
half2 matCapUV(half3 worldNormal, half3 worldViewDir)
{
	half3 rx = half3(1, 0, 0);
	half3 ry = half3(0, 1, 0);
	half3 rz = UNITY_MATRIX_V[2].xyz;

	rx = cross(ry, rz);
	ry = cross(rz, rx);

	half3x3 m;
	m[0] = rx;
	m[1] = -ry;
	m[2] = rz;

	half2 uv;
	#if _MATCAP_PLANAR_ON
	{
		half3 dir = reflect(worldViewDir, worldNormal);
		dir = normalize(mul(m, dir));
		uv = saturate(dir.xy * 0.5 + 0.5);
	}
	#else
	{
		half3 viewNormal = mul(m, worldNormal);
		uv = saturate(viewNormal.xy * 0.5 + 0.5);
	}
	#endif

	return uv;
}

			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

/// override shading feature for quaity

#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _NORMAL_MAP_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _NORMAL_MAP_ON
		#define _NORMAL_MAP_ON 0
	#endif
#endif

#if _REFLECTION_PROBES_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _REFLECTION_PROBES_ON
		#define _REFLECTION_PROBES_ON 0
	#endif
#endif

/// Vertex
///
struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 vcolor : COLOR;
	float2 texcoord0 : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
	
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dlmapcoord : TEXCOORD2;
#endif

#if _NORMAL_MAP_ON
	float4 tangent : TANGENT;
#endif
};

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 ambientOrLightmapUV : TEXCOORD2;
	float4 worldPosAndZ : TEXCOORD3;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD4;
	float4 tanSpace1 : TEXCOORD5;
	float4 tanSpace2 : TEXCOORD6;
#else
	float3 worldNormal : TEXCOORD4;
#endif

	float4 pos : SV_POSITION;
};


inline half4 VertexGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		ambientOrLightmapUV.zw = 0;
	}
	#elif UNITY_SHOULD_SAMPLE_SH
	{
		// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
		ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, ambientOrLightmapUV.rgb);
	}
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
	{
		ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = float4(v.texcoord0.xy, v.texcoord1.xy);

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(v.normal);

	#if _NORMAL_MAP_ON
	{
		float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
		float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
		o.tanSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, 0);
		o.tanSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, 0);
		o.tanSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, 0);
	}
	#else
	{
		o.worldNormal = worldNormal;

		#if _MATCAP_ON
		{
			half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPosAndZ.xyz);
			o.uv.zw = matCapUV(worldNormal, worldViewDir);
		}
		#endif
	}
	#endif

	o.ambientOrLightmapUV = VertexGIForward(v, o.worldPosAndZ.xyz, o.worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;

#if _REFLECTION_PROBES_ON
uniform float _ReflectionIntensity;
#endif

#if _GI_IRRADIANCE_ON
uniform float _GIIrradianceIntensity;
#endif

#if _NORMAL_MAP_ON
uniform sampler2D _NormalMapTex;
#endif

#if _DIFFUSE_LUT_ON
uniform sampler2D _DiffuseLUTTex;
#endif

#if _MATCAP_ON
uniform sampler2D _MatCapTex;
uniform float _MatCapIntensity;
#endif

struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	half3 shadow;
	half4 result;
	half4 sv_pos;
};

#if defined(SHADER_API_PSSL)
void shadingContext(inout ShadingContext ctx, in v2f i, in uint vface)
#else
void shadingContext(inout ShadingContext ctx, in v2f i, in fixed vface)
#endif
{
	ctx.sv_pos = i.pos;
	ctx.uv = i.uv;
	ctx.vface = vface > 0 ? 1.0 : -1.0;
	ctx.albedo = tex2D(_MainTex, i.uv.xy) * _Color;
	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
		ctx.shadow = atten;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		ctx.shadow = 1;
	}
	#endif

	#if _NORMAL_MAP_ON
	{
		half3 tanNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv.xy));
		half3 worldNormal;
		worldNormal.x = dot(i.tanSpace0.xyz, tanNormal);
		worldNormal.y = dot(i.tanSpace1.xyz, tanNormal);
		worldNormal.z = dot(i.tanSpace2.xyz, tanNormal);
		ctx.worldNormal = normalize(worldNormal) * ctx.vface;
	}
	#else
	{
		//ctx.worldNormal = normalize(i.worldNormal) * vface;
		ctx.worldNormal = i.worldNormal * ctx.vface;
		#if SHADING_QUALITY >= SHADING_QUALITY_MEDIUM
		{
			ctx.worldNormal = normalize(ctx.worldNormal);
		}
		#endif
	}
	#endif

	ctx.worldPos = i.worldPosAndZ.xyz;
	ctx.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosAndZ.xyz);
	ctx.eyeDepth = i.worldPosAndZ.w;
	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

UnityLight MainLight ()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		UnityLight light = MainLight();

		half ndotl = dot(ctx.worldNormal, light.dir);

		#if _DIFFUSE_LUT_ON
		{
			ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5)).r;
		}
		#else
		{
			ndotl = saturate(ndotl);
		}
		#endif

		half3 diff = 0;

		#if _GI_IRRADIANCE_ON
		{
			UnityGIInput d;
			d.light = light;
			d.worldPos = ctx.worldPos;
			d.worldViewDir = ctx.worldViewDir;
			d.atten = ctx.shadow;
			#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
			{
				d.ambient = 0;
				d.lightmapUV = ctx.ambientOrLightmapUV;
			}
			#else
			{
				d.ambient = ctx.ambientOrLightmapUV.rgb;
				d.lightmapUV = 0;
			}
			#endif

			#if defined(LIGHTMAP_ON)
			{
				half bakedAtten = UnitySampleBakedOcclusion(d.lightmapUV.xy, ctx.worldPos);

				#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
				{
					//float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, dot(_WorldSpaceCameraPos - ctx.worldPos, UNITY_MATRIX_V[2].xyz));
					float fadeDist = UnityComputeShadowFadeDistance(ctx.worldPos, -ctx.eyeDepth);
					bakedAtten = UnityMixRealtimeAndBakedShadows(d.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
				}
				#endif

				d.atten = bakedAtten;
			}
			#endif

			UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);

			diff += gi.indirect.diffuse + gi.light.color * ndotl;

			ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
		}
		#else // _GI_IRRADIANCE_ON
		{
			diff += ctx.shadow * ndotl * light.color;
		}
		#endif

		ctx.result.rgb = ctx.albedo.rgb * diff;
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow + unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.albedo * ctx.shadow;
		}
		#endif
	}
	#endif
}

void applyLightingFwdAdd(inout ShadingContext ctx)
{
	half ndotl = dot(ctx.worldNormal, normalize(_WorldSpaceLightPos0.xyz - ctx.worldPos));
	#if _DIFFUSE_LUT_ON
	{
		ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
	}
	#else
	{
		ndotl = saturate(ndotl) * ctx.shadow;
	}
	#endif
	
	ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
}

void applyMatcap(inout ShadingContext ctx)
{
	#if _MATCAP_ON
	{
		half2 uv;

		#if _NORMAL_MAP_ON
		{
			uv = matCapUV(ctx.worldNormal, ctx.worldViewDir);
		}
		#else
		{
			uv = ctx.uv.zw;
		}
		#endif

		half4 matCap = tex2D(_MatCapTex, uv);
		matCap = matCap * ctx.albedo.a * _MatCapIntensity;
		#if _MATCAP_ALBEDO_ON
		{
			matCap.rgb *= ctx.albedo.rgb;
		}
		#endif
		ctx.result.rgb += matCap;
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		half3 worldNormalRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
		float blendDistance = unity_SpecCube1_ProbePosition.w; // will be set to blend distance for this probe

#if UNITY_SPECCUBE_BOX_PROJECTION
		// For box projection, use expanded bounds as they are rendered; otherwise
		// box projection artifacts when outside of the box.
		float4 boxMin = unity_SpecCube0_BoxMin - float4(blendDistance, blendDistance, blendDistance, 0);
		float4 boxMax = unity_SpecCube0_BoxMax + float4(blendDistance, blendDistance, blendDistance, 0);
		half3 reflDir = BoxProjectedCubemapDirection(worldNormalRefl, ctx.worldPos, unity_SpecCube0_ProbePosition, boxMin, boxMax);
#else
		half3 reflDir = worldNormalRefl;
#endif

		float4 refl = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 1);
		refl.rgb = DecodeHDR_NoLinearSupportInSM2(refl, unity_SpecCube0_HDR);

		half fren = dot(ctx.worldViewDir, ctx.worldNormal);
		fren = saturate(fren);
		fren = saturate(1 - fren * fren + 0.25) * ctx.occlusion;
		
		ctx.result.rgb = lerp(ctx.result.rgb, (half3)refl.rgb * _ReflectionIntensity, ctx.albedo.a * fren);
	}
#endif
}

#if defined(SHADER_API_PSSL)
half4 frag_base(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_base(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdBase(ctx);

	applyMatcap(ctx);

	applyReflectionProbes(ctx);

	return ctx.result;
}


#if defined(SHADER_API_PSSL)
half4 frag_add(v2f i, uint vface : S_FRONT_FACE) : SV_Target
#else
half4 frag_add(v2f i, fixed vface : VFACE) : SV_Target
#endif
{
	ShadingContext ctx = (ShadingContext)0;
	shadingContext(ctx, i, vface);

	applyLightingFwdAdd(ctx);

	return ctx.result;
}

			#pragma multi_compile_fwdbase

			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _REFLECTION_PROBES_ON
			#pragma shader_feature _GI_IRRADIANCE_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON
			#pragma shader_feature _MATCAP_ON
			#pragma shader_feature _MATCAP_PLANAR_ON
			#pragma shader_feature _MATCAP_ALBEDO_ON

			#pragma vertex vert
			#pragma fragment frag_base
			ENDCG
		}
		
		Pass
		{
			Name "META"
			Tags
			{
				"LightMode"="Meta"
			}

			Cull Off

			CGPROGRAM
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

			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Cull Off

			CGPROGRAM
			#pragma vertex vert_shadowcaster
#pragma fragment frag_shadowcaster
#pragma target 2.0
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"

struct v2f_shadowcaster { 
	V2F_SHADOW_CASTER;
};

v2f_shadowcaster vert_shadowcaster( appdata_base v )
{
	v2f_shadowcaster o;
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}

float4 frag_shadowcaster( v2f_shadowcaster i ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}
			ENDCG
		}
	}

	CustomEditor "MGFX.Rendering.MobileTransparentUI"
}