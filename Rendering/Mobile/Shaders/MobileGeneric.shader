Shader "MGFX/Mobile/Generic"
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


	// High Quality
	SubShader
	{
		LOD 300

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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
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


			#define SHADING_QUALITY SHADING_QUALITY_HIGH
			#pragma target 3.0
			
			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdbase LIGHTMAP_OFF DYNAMICLIGHTMAP_OFF
#pragma skip_variants SHADOWS_SOFT

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
		/*
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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2


			#define SHADING_QUALITY SHADING_QUALITY_HIGH
			#pragma target 3.0

			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdadd_fullshadows
#pragma skip_variants SHADOWS_SOFT

#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIFFUSE_LUT_ON

#pragma vertex vert
#pragma fragment frag_add
			ENDCG
		}
		*/
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

			Cull Back

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

	// Medium Quality
	SubShader
	{
		LOD 200

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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
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


			#define SHADING_QUALITY SHADING_QUALITY_MEDIUM
			#pragma target 2.0
			
			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdbase LIGHTMAP_OFF DYNAMICLIGHTMAP_OFF
#pragma skip_variants SHADOWS_SOFT

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
		/*
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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2


			#define SHADING_QUALITY SHADING_QUALITY_MEDIUM
			#pragma target 2.0

			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdadd_fullshadows
#pragma skip_variants SHADOWS_SOFT

#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIFFUSE_LUT_ON

#pragma vertex vert
#pragma fragment frag_add
			ENDCG
		}
		*/
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

			Cull Back

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

	// Low Quality
	SubShader
	{
		LOD 100

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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

			
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


			#define SHADING_QUALITY SHADING_QUALITY_LOW
			#pragma target 2.0
			
			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdbase LIGHTMAP_OFF DYNAMICLIGHTMAP_OFF
#pragma skip_variants SHADOWS_SOFT

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
		/*
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


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2


			#define SHADING_QUALITY SHADING_QUALITY_LOW
			#pragma target 2.0

			#include "Lighting.cginc"
#include "AutoLight.cginc"

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
	float2 texcoord : TEXCOORD0;

	#ifndef LIGHTMAP_OFF
	float2 lmapcoord : TEXCOORD1;
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
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
	SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	float4 worldPosAndZ : TEXCOORD2;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD3;
	float4 tanSpace1 : TEXCOORD4;
	float4 tanSpace2 : TEXCOORD5;
#else
	float3 worldNormal : TEXCOORD3;
#endif

#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	float4 lmap : TEXCOORD6;
#endif

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.vcolor = v.vcolor;
	o.uv = v.texcoord.xyxy;

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


	#ifndef LIGHTMAP_OFF
	{
		o.lmap = v.lmapcoord.xyxy * unity_LightmapST.xyxy + unity_LightmapST.zwzw;
	}
	#endif

	#ifndef DYNAMICLIGHTMAP_OFF
	{
		o.lmap.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

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
	half4 uv;
	half4 lmapUV;
	half4 albedo;
	half occlusion;
	fixed vface;
	fixed shadow;
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

	if (ctx.vface < 0 || (SHADING_QUALITY == SHADING_QUALITY_LOW))
	{
		ctx.shadow = 1;
	}
	else
	{
		UNITY_LIGHT_ATTENUATION(attenWithShadow, i, ctx.worldPos);
		ctx.shadow = attenWithShadow;
	}

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

	#if !defined(LIGHTMAP_OFF) || !defined(DYNAMICLIGHTMAP_OFF)
	{
		ctx.lmapUV = i.lmap;
	}
	#else
	{
		ctx.lmapUV = i.uv;
	}
	#endif

	ctx.result = half4(0, 0, 0, ctx.albedo.a);
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#ifdef LIGHTMAP_OFF
		{
			half ndotl = dot(ctx.worldNormal, _WorldSpaceLightPos0.xyz);

			#if _DIFFUSE_LUT_ON
			{
				ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * ctx.shadow).r;
			}
			#else
			{
				ndotl = saturate(ndotl) * ctx.shadow;
			}
			#endif

			half3 lighting = ctx.albedo * ndotl * _LightColor0.rgb;
			
			#if _GI_IRRADIANCE_ON
			{
				half3 irrad = half3(0, 0, 0);

				#if (SHADING_QUALITY >= SHADING_QUALITY_MEDIUM)
				{
					#ifndef DYNAMICLIGHTMAP_OFF
					{
						irrad = DecodeRealtimeLightmap (UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ctx.lmapUV.zw));

						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
						{
							fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_DynamicDirectionality, unity_DynamicLightmap, ctx.lmapUV.zw);
							irrad = DecodeDirectionalLightmap (irrad, dirmap, ctx.worldNormal);
						}
						#endif

						ctx.occlusion = saturate(Luminance(irrad));
						ctx.occlusion = ctx.occlusion * ctx.occlusion;
						//ctx.occlusion = 1.0;
					}
					#elif UNITY_SHOULD_SAMPLE_SH
					{
						#if (SHADING_QUALITY == SHADING_QUALITY_HIGH)
						{
							irrad = ShadeSHPerPixel (ctx.worldNormal, irrad, ctx.worldPos);
						}
						#else
						{
							irrad = ShadeSHPerVertex (ctx.worldNormal, irrad);
						}
						#endif
					}
					#endif
				}
				#else
				{
					irrad = lerp(unity_AmbientSky, unity_AmbientGround, ctx.worldNormal * 0.5 + 0.5);
				}
				#endif

				lighting += irrad * ctx.albedo.rgb * _GIIrradianceIntensity;
			}
			#endif

			ctx.result.rgb += lighting * ctx.occlusion;
		}
		#else // LIGHTMAP_OFF
		{
			half3 lmap = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.lmapUV.xy));

			#if (SHADING_QUALITY == SHADING_QUALITY_HIGH) && DIRLIGHTMAP_COMBINED
			{
				fixed4 dirmap = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, ctx.lmapUV.xy);
				lmap = DecodeDirectionalLightmap (lmap, dirmap, ctx.worldNormal);
			}
			#endif

			ctx.result.rgb += lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * lmap;
			ctx.occlusion = saturate(Luminance(lmap));
			ctx.occlusion = ctx.occlusion * ctx.occlusion;
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow) * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = lerp(ctx.albedo * 0.25, ctx.albedo, ctx.shadow);
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
			#pragma multi_compile_fwdadd_fullshadows
#pragma skip_variants SHADOWS_SOFT

#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIFFUSE_LUT_ON

#pragma vertex vert
#pragma fragment frag_add
			ENDCG
		}
		*/
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

			Cull Back

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

	CustomEditor "MGFX.Rendering.MobileGenericUI"
}