Shader "MGFX/Mobile/GenericDS"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
[HDR] _Color ("Color", Color) = (1.0, 1.0, 1.0, 0.0)
_ShadowColor ("ShadowColor", Color) = (0.0, 0.0, 0.0, 0.5)

[HideInInspector] _SrcBlend ("__src", Float) = 1.0
[HideInInspector] _DstBlend ("__dst", Float) = 0.0
[HideInInspector] _ZWrite ("__zw", Float) = 1.0
[Toggle(_DECAL_ON)] _DecalOn("Enable Decal", Int) = 0
_DecalOffset ("Decal Offset", Range(0,2)) = 0.0001

[Toggle(_REALTIME_LIGHTING_ON)] _RealtimeLightingOn("Enable Realtime Lighting", Int) = 1

[Toggle(_REFLECTION_PROBES_ON)] _ReflectionProbesOn("Enable Reflection Probes", Int) = 0
_ReflectionIntensity ("Reflection Intensity", Range(0,8)) = 1.0

[Toggle(_VERTEX_ANIM_ROTATE_ON)] _VertexAnimRotateOn("Enable Vertex Rotation", Int) = 0
[PerRendererData] _VertexAnimRotateAxis ("Rotate Axis", Vector) = (1.0, 0.0, 0.0, 0.0)
[PerRendererData] _VertexAnimTime ("Time", Vector) = (90.0, 0.0, 0.0, 0.0)

[Toggle(_COMPOSITE_ON)] _CompositeOn("Enable Texture Composition", Int) = 0
[NoScaleOffset] _CompositeTex ("Composite Tex", 2D) = "white" {}
[Toggle(_COMPOSITE_EROSION_ON)] _CompositeErosionOn("Enable Erosion Effect", Int) = 0
_CompositeErosion ("Erosion Scale", Range(0, 1)) = 1

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
			"RenderType"="Opaque"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
			Tags
			{
				"LightMode"="ForwardAdd"
			}

			ZWrite Off
			ZTest LEqual
			Blend One One
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 3.0
		#define SHADING_QUALITY SHADING_QUALITY_HIGH
	
			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON

			#pragma vertex vert
			#pragma fragment frag_add

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
			"RenderType"="Opaque"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
			Tags
			{
				"LightMode"="ForwardAdd"
			}

			ZWrite Off
			ZTest LEqual
			Blend One One
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 2.0
		#define SHADING_QUALITY SHADING_QUALITY_MEDIUM
	
			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON

			#pragma vertex vert
			#pragma fragment frag_add

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
			"RenderType"="Opaque"
		}

		Pass
		{
			Tags
			{
				"LightMode"="ForwardBase"
			}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
	// Debug VertexAlpha
	
	
	
	SubShader
	{
		LOD 30

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

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 3.0
		#define DEBUG_VERTEXALPHA
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
	// Debug Reflection
	
	
	
	SubShader
	{
		LOD 20

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

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 3.0
		#define DEBUG_REFLECTION
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
	// Debug Lighting
	
	
	
	SubShader
	{
		LOD 10

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

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 3.0
		#define DEBUG_LIGHTING
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

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
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
			Tags
			{
				"LightMode"="ForwardAdd"
			}

			ZWrite Off
			ZTest LEqual
			Blend One One
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2

#if UNITY_VERSION < 560
	#define UNITY_SHADOW_COORDS(x) SHADOW_COORDS(x)
#endif
			
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotateVector3(float3 v, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


			
		#pragma target 3.0
		#define DEBUG_LIGHTING
		#define SHADING_QUALITY SHADING_QUALITY_HIGH
	
			#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityGlobalIllumination.cginc"

#ifndef SHADING_QUALITY
	#define SHADING_QUALITY SHADING_QUALITY_LOW
#endif

///
/// override shading feature for quaity
///
#if _REALTIME_LIGHTING_ON
	#if SHADING_QUALITY < SHADING_QUALITY_MEDIUM
		#undef _REALTIME_LIGHTING_ON
		#define _REALTIME_LIGHTING_ON 0
	#endif
#endif

#if _COMPOSITE_ON
	#if SHADING_QUALITY < SHADING_QUALITY_HIGH
		#undef _COMPOSITE_ON
		#define _COMPOSITE_ON 0
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

///
/// Structs
///
#if _COMPOSITE_ON
	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdCh2 : TEXCOORD1; // channel2
		float2 texcrdLmap : TEXCOORD2; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD3;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};

#else // _COMPOSITE_ON

	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 vcolor : COLOR;
		float2 texcrdCh1 : TEXCOORD0; // channel1
		float2 texcrdLmap : TEXCOORD1; // lightmap
		
	#if defined(DYNAMICLIGHTMAP_ON)
		float2 dlmapcoord : TEXCOORD2;
	#endif

	#if _NORMAL_MAP_ON
		float4 tangent : TANGENT;
	#endif
	};
#endif // _COMPOSITE_ON

struct v2f
{
	float4 vcolor : COLOR;
	float4 uv : TEXCOORD0;
	UNITY_SHADOW_COORDS(1) // put shadows data into TEXCOORD1
	UNITY_FOG_COORDS(2)
	float4 ambientOrLightmapUV : TEXCOORD3;
	float4 worldPosAndZ : TEXCOORD4;

#if _NORMAL_MAP_ON
	float4 tanSpace0 : TEXCOORD5;
	float4 tanSpace1 : TEXCOORD6;
	float4 tanSpace2 : TEXCOORD7;
#else
	float3 worldNormal : TEXCOORD5;
#endif

	float4 pos : SV_POSITION;
};

/// Uniforms
#if _DECAL_ON
uniform float _DecalOffset;
#endif

uniform float4 _VertexAnimRotateAxis;
uniform float4 _VertexAnimTime; // scale, offset

uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;

uniform float4 _Color;
uniform float4 _ShadowColor;

#if _COMPOSITE_ON
uniform sampler2D _CompositeTex;
uniform float _CompositeErosion;
#endif

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


///
/// Vertex
///
inline half4 vertGIForward(appdata v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
	{
		ambientOrLightmapUV.xy = v.texcrdLmap.xy * unity_LightmapST.xy + unity_LightmapST.zw;
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
		ambientOrLightmapUV.zw = v.dlmapcoord.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	}
	#endif

	return ambientOrLightmapUV;
}

v2f vert (appdata v)
{
	v2f o = (v2f)0;

	float4 vertexPos = v.vertex;
	float3 vertexNormal = v.normal;

	#if _VERTEX_ANIM_ROTATE_ON
	{
		float3 rotAxis = normalize(_VertexAnimRotateAxis.xyz);
		float rotAngle = _VertexAnimTime.x * _Time.y + _VertexAnimTime.y;
		vertexPos.xyz = animRotateVector3(vertexPos.xyz, rotAxis, rotAngle);
		vertexNormal.xyz = animRotateVector3(vertexNormal.xyz, rotAxis, rotAngle);
	}
	#endif

	o.pos = UnityObjectToClipPos(vertexPos);
	UNITY_TRANSFER_FOG(o, o.pos);

	#if _DECAL_ON
	{
		float depthOffset = _DecalOffset;
		#if defined(UNITY_REVERSED_Z)
		{
			o.pos.z += depthOffset;
		}
		#else
		{
			o.pos.z -= depthOffset;
		}
		#endif
	}
	#endif

	o.vcolor = v.vcolor;
	o.uv = v.texcrdCh1.xyxy;

	#if _COMPOSITE_ON
	{
		o.uv.zw = v.texcrdCh2.xy;
	}
	#endif

	o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, vertexPos).xyz;

	float3 worldNormal = UnityObjectToWorldNormal(vertexNormal);

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

	o.ambientOrLightmapUV = vertGIForward(v, o.worldPosAndZ.xyz, worldNormal);

	COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
	// compute shadows data
	TRANSFER_SHADOW(o)
	return o;
}

///
/// Fragment
///
struct ShadingContext
{
	half3 worldNormal;
	half3 worldViewDir;
	half3 worldPos;
	half eyeDepth;
	half4 uv;
	half4 ambientOrLightmapUV;
	half4 vcolor;
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
	ctx.vcolor = i.vcolor;
	ctx.albedo = tex2D(_MainTex, i.uv.xy);

	#if _COMPOSITE_ON
	{
		half blendWeight = i.vcolor.a;
		blendWeight = blendWeight * blendWeight * (3 - 2 * blendWeight);

		half4 composite = tex2D(_CompositeTex, i.uv.zw);
		#if _COMPOSITE_EROSION_ON
		{
			half noise = saturate(dot(composite.rgba, 0.25));
			half noise2 = saturate(dot(ctx.albedo.rgba, 0.25));
			//noise = smoothstep(noise2 * 0.25, noise2 * 0.5, noise);
			noise = noise - (noise2 * 2 - 1);
			noise = noise * blendWeight;
			blendWeight = saturate(blendWeight + noise * _CompositeErosion);
		}
		#endif
		
		ctx.albedo = lerp(ctx.albedo, composite, blendWeight);
	}
	#endif

	ctx.occlusion = 1.0;
	ctx.ambientOrLightmapUV = i.ambientOrLightmapUV;
	ctx.shadow = 1.0;

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosAndZ.xyz);
	ctx.shadow = atten;

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

UnityLight lightGetMain()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	return l;
}

half3 lightingFwdBaseHQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

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
	half3 spec = 0;
	half shadowTint = 0;

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
			#if UNITY_VERSION < 560
			{
				half3 lmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, d.lightmapUV.xy));
				half lmapShadow = smoothstep(0.25, 0.75, Luminance(lmap));
				d.atten = lmapShadow * d.atten;
			}
			#else
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
		}
		#endif

		UnityGI gi = UnityGI_Base(d, 1.0, ctx.worldNormal);
		diff += gi.indirect.diffuse + light.color * ndotl;

		shadowTint = lerp(1, d.atten, _ShadowColor.a);

		//ctx.occlusion = saturate(Luminance(gi.indirect.diffuse));
	}
	#else // _GI_IRRADIANCE_ON
	{
		diff += ctx.shadow * ndotl * light.color;

		shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);
	}
	#endif

	half3 worldRefl = reflect(-ctx.worldViewDir, ctx.worldNormal);
	worldRefl = normalize(worldRefl);
	half ndotr = saturate(dot(worldRefl, light.dir));
	ndotr = ndotr * ndotr;
	ndotr = ndotr * ndotr;

	spec = ndotr * light.color;

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);
	spec = lerp(0, spec, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
		spec *= ctx.albedo.a;
	}
	#endif

	return diff + spec;
}

half3 lightingFwdBaseMQ(in ShadingContext ctx)
{
	UnityLight light = lightGetMain();

	half ndotl = dot(ctx.worldNormal, light.dir);
	ndotl = saturate(ndotl);

	half3 diff = 0;
	half shadowTint = 0;

	#if defined(LIGHTMAP_ON)
	{
		diff += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ctx.ambientOrLightmapUV));
	}
	#else
	{
		diff += light.color * ndotl;
	}
	#endif

	#if _GI_IRRADIANCE_ON && UNITY_SHOULD_SAMPLE_SH
	{
		diff += ctx.ambientOrLightmapUV.rgb;
	}
	#endif
	
	shadowTint = lerp(1, ctx.shadow, _ShadowColor.a);

	diff = lerp(_ShadowColor.rgb, diff, shadowTint);

	#if !defined(DEBUG_LIGHTING)
	{
		diff *= ctx.albedo.rgb;
	}
	#endif
	
	return diff;
}

void applyLightingFwdBase(inout ShadingContext ctx)
{
	#if _REALTIME_LIGHTING_ON
	{
		#if SHADING_QUALITY >= SHADING_QUALITY_HIGH
		{
			ctx.result.rgb = lightingFwdBaseHQ(ctx);
		}
		#else
		{
			ctx.result.rgb = lightingFwdBaseMQ(ctx);
		}
		#endif
	}
	#else // _REALTIME_LIGHTING_ON
	{
		#if _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow * unity_AmbientSky;
		}
		#else // _GI_IRRADIANCE_ON
		{
			ctx.result.rgb = ctx.shadow;
		}
		#endif
			
		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb *= ctx.albedo.rgb;
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

	#if defined(DEBUG_LIGHTING)
	{
		ctx.result.rgb += ndotl * _LightColor0.rgb;
	}
	#else
	{
		ctx.result.rgb += ctx.albedo * ndotl * _LightColor0.rgb;
	}
	#endif

	#if _DECAL_ON
	{
		ctx.result.rgb *= ctx.albedo.a;
	}
	#endif
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

		#if !defined(DEBUG_LIGHTING)
		{
			ctx.result.rgb += matCap;
		}
		#endif
	}
	#endif
}

void applyReflectionProbes(inout ShadingContext ctx)
{
#if _REFLECTION_PROBES_ON
	{
		UnityGIInput d;
		d.worldPos = ctx.worldPos;
		d.worldViewDir = ctx.worldViewDir;
		
		d.probeHDR[0] = unity_SpecCube0_HDR;
		d.probeHDR[1] = unity_SpecCube1_HDR;
		#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
		#endif
		#if UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
		#endif
		
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(ctx.albedo.a, ctx.worldViewDir, ctx.worldNormal, 1);

		half sfren =  saturate(dot(normalize(g.reflUVW), ctx.worldNormal));
		sfren = (1 - sfren);

		half3 refl = UnityGI_IndirectSpecular(d, ctx.occlusion, g);
		
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = refl;
		}
		#else
		{
			#if !defined(DEBUG_LIGHTING)
			{
				ctx.result.rgb = lerp(ctx.result.rgb, refl, saturate(sfren * _ReflectionIntensity * ctx.albedo.a));
			}
			#endif
		}
		#endif
	}
#else
	{
		#if defined(DEBUG_REFLECTION)
		{
			ctx.result.rgb = 0;
		}
		#endif
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

	#if _REALTIME_LIGHTING_ON
	{
		UNITY_APPLY_FOG(i.fogCoord, ctx.result);
	}
	#endif

	#if defined(DEBUG_VERTEXALPHA)
	{
		ctx.result = half4(ctx.vcolor.aaa, 1);
	}
	#endif
	
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

	#if _REALTIME_LIGHTING_ON
	{
		applyLightingFwdAdd(ctx);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, ctx.result, fixed4(0,0,0,0));
	}
	#endif

	return ctx.result;
}
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma shader_feature _COMPOSITE_ON
			#pragma shader_feature _COMPOSITE_EROSION_ON
			#pragma shader_feature _DECAL_ON
			#pragma shader_feature _REALTIME_LIGHTING_ON
			#pragma shader_feature _NORMAL_MAP_ON
			#pragma shader_feature _DIFFUSE_LUT_ON

			#pragma vertex vert
			#pragma fragment frag_add

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
	// UI
	CustomEditor "MGFX.Rendering.MobileGenericUI"
}