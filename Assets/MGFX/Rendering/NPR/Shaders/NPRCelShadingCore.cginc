
#include "UnityPBSLighting.cginc"

sampler2D _MainTex;

#if _DIM_ON
sampler2D _DimTex;
#endif

#if _NORMAL_MAP_ON
sampler2D _NormalMapTex;
#endif

#if _OVERLAY_ON
sampler2D _OverlayTex;
#endif

#if _DIFFUSE_LUT_ON
sampler2D _DiffuseLUTTex;
#endif

float _EdgeStrengthCurve;
float _EdgeStrengthPlanar;

struct Input {
    float2 uv_MainTex;
#if _OVERLAY_ON
    float2 uv2_OverlayTex;
#endif
    float3 viewDir;
    float4 screenPos;
};

#if _RIM_ON
half _RimSize;
half _RimIntensity;
#endif
fixed4 _Color;


#if _EDGE_ON
uniform sampler2D _MudNPREdgeTex; // global property
uniform float4 _MudNPREdgeTex_TexelSize;
uniform float4 _EdgeColor;
uniform float _EdgeAutoColor;
uniform float _EdgeAutoColorFactor;
#endif

#if _SSAO_ON
uniform sampler2D _MudSSAOTex; // global property
uniform float4 _MudSSAOTex_TexelSize;
uniform float _SsaoShapness;
#endif

float pow2(float val) { return val * val; }
half pow2(half val) { return val * val; }
half2 pow2(half2 val) { return val * val; }
half3 pow2(half3 val) { return val * val; }
half4 pow2(half4 val) { return val * val; }

float pow4(float val) { val = val * val; val = val * val; return val; }
half pow4(half val) { val = val * val; val = val * val; return val; }
half2 pow4(half2 val) { val = val * val; val = val * val; return val; }
half3 pow4(half3 val) { val = val * val; val = val * val; return val; }
half4 pow4(half4 val) { val = val * val; val = val * val; return val; }


struct SurfaceOutputCel
{
	fixed3 Albedo;		// base (diffuse or specular) color
#if _DIM_ON
	fixed3 Albedo2;
#endif
	fixed3 Normal;		// tangent space normal, if written
	half3 Emission;
	half Metallic;		// 0=non-metal, 1=metal
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;		// occlusion (default 1)
	fixed Alpha;		// alpha for transparencies
};

inline half4 LightingCelShading (SurfaceOutputCel s, half3 viewDir, UnityGI gi)
{
    half4 c;
    half3 worldNrm = s.Normal;
    half3 lightDir = gi.light.dir;
    //half3 refViewDir = normalize (_WorldSpaceCameraPos.xyz - mul (_Object2World, float4 (0, 0, 0, 1)).xyz);
    half3 refViewDir = viewDir;
    
    half DELTA = 1.0 / 64.0;

    
    half3 shadow = gi.light.color;//Luminance(gi.light.color);
    half3 albedo = s.Albedo;

    half ndotl;
#if _DIFFUSE_LUT_ON
    ndotl = (dot(worldNrm, lightDir) * 0.5 + 0.5);
    ndotl = tex2Dlod(_DiffuseLUTTex, float4(ndotl, 0.0, 0.0, 0.0));
#else
    ndotl = smoothstep(0.1, 0.2, gi.light.ndotl);
#endif

#if _RIM_ON
    //half3 rimDir = normalize(refViewDir + lightDir * 0.0625);
    half3 rimDir = normalize(refViewDir);
    half rim = 1 - smoothstep(_RimSize, _RimSize + 1.0 / 8.0, saturate (dot (rimDir, worldNrm)));
    rim *= _RimIntensity;
    half3 bright = saturate(albedo * (1 + rim * rim));
    albedo = lerp(albedo, bright, rim);
#endif

	half3 dim;
#if _DIM_ON
	dim = s.Albedo2;
#else
	dim = s.Albedo * s.Albedo;
	dim = dim * dim;
#endif
	albedo = lerp(dim, albedo, ndotl * s.Occlusion);

    c.rgb = albedo;
    c.rgb *= shadow;

    c.rgb += albedo * gi.indirect.diffuse;
    c.a = s.Alpha;
    return c;
}

inline void LightingCelShading_GI (
     SurfaceOutputCel s,
     UnityGIInput data,
     inout UnityGI gi)
{
	gi = UnityGlobalIllumination (data, 1.0, s.Smoothness, s.Normal);
}

float4 GetTexel(sampler2D tex, float4 texelSize, float2 p)
{
	p = p * texelSize.zw + 0.5;

	float2 i = floor(p);
	float2 f = p - i;
	f = f*f*f*(f*(f*6.0-15.0)+10.0);
	p = i + f;

	p = (p - 0.5) * texelSize.xy;

	return tex2D (tex, p);
}

void surf (Input IN, inout SurfaceOutputCel o) {
    // Albedo comes from a texture tinted by color
    fixed4 albedo = tex2D (_MainTex, IN.uv_MainTex);

#if _DIM_ON
    fixed4 albedo2 = tex2D (_DimTex, IN.uv_MainTex);
#endif

#if _OVERLAY_ON
    fixed4 overlay = tex2D (_OverlayTex, IN.uv2_OverlayTex);
    albedo.rgb = lerp (albedo, overlay, overlay.a).rgb;

#	if _DIM_ON
    albedo2.rgb = lerp (albedo2, overlay, overlay.a).rgb;
#	endif
#endif
    
#if _NORMAL_MAP_ON
    o.Normal = UnpackNormal(tex2D(_NormalMapTex, IN.uv_MainTex));
#else
    o.Normal = float3(0,0,1);
#endif

#if _BACKFACE_ON
    o.Normal *= -1;
#endif

#if _EDGE_ON || _SSAO_ON
	float2 screenUV = IN.screenPos.xy / IN.screenPos.ww;
#endif

#if _EDGE_ON
	float isedge = GetTexel(_MudNPREdgeTex, _MudNPREdgeTex_TexelSize, screenUV).r;

	half3 edgeColor = pow(albedo.rgb, _EdgeAutoColorFactor);
	edgeColor = lerp(_EdgeColor, edgeColor, _EdgeAutoColor);

	albedo.rgb = lerp(albedo.rgb, edgeColor, saturate(isedge * _EdgeColor.a * 4));
#endif

    o.Albedo = albedo.rgb;
#if _DIM_ON
    o.Albedo2 = albedo2.rgb;
#endif
    o.Occlusion = 1.0;
    o.Metallic = 0;
    o.Smoothness = 0;

#if _SSAO_ON
	float beg = _SsaoShapness * 0.5;
	float end = 1.0 - beg;
	float ssao = 1.0 - GetTexel(_MudSSAOTex, _MudSSAOTex_TexelSize, screenUV).r;
	o.Occlusion = smoothstep(beg, end, ssao);
#endif
    //o.Alpha = 1;
}