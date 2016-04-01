
#include "UnityPBSLighting.cginc"

sampler2D _MainTex;
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
};

#if _RIM_ON
half _RimSize;
half _RimIntensity;
#endif
fixed4 _Color;


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


inline half4 LightingCelShading (SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
{
    half4 c;
    half3 worldNrm = s.Normal;
    half3 lightDir = gi.light.dir;
    //half3 refViewDir = normalize (_WorldSpaceCameraPos.xyz - mul (_Object2World, float4 (0, 0, 0, 1)).xyz);
    half3 refViewDir = viewDir;
    
    half DELTA = 1.0 / 64.0;

    
    half3 shadow = gi.light.color;//Luminance(gi.light.color);
    half3 albedo = s.Albedo;
#if _RIM_ON
    //half3 rimDir = normalize(refViewDir + lightDir * 0.0625);
    half3 rimDir = normalize(refViewDir);
    half rim = 1 - smoothstep(_RimSize, _RimSize + 1.0 / 8.0, saturate (dot (rimDir, worldNrm)));
    rim *= _RimIntensity;
    half3 bright = saturate(s.Albedo * (1 + rim * rim));
    albedo = lerp(s.Albedo, bright, rim);
#endif
    half ndotl;
#if _DIFFUSE_LUT_ON
    ndotl = (dot(worldNrm, lightDir) * 0.5 + 0.5);
    ndotl = tex2Dlod(_DiffuseLUTTex, float4(ndotl, 0.0, 0.0, 0.0));
#else
    ndotl = smoothstep(0.4, 0.5, gi.light.ndotl);
#endif
    half3 dark = pow4(min(albedo, 1 - DELTA));
    c.rgb = lerp(dark, albedo, ndotl);
    c.rgb = c.rgb * shadow;

    c.rgb = c.rgb + albedo * gi.indirect.diffuse;
    c.a = s.Alpha;
    return c;
}

inline void LightingCelShading_GI (
     SurfaceOutputStandard s,
     UnityGIInput data,
     inout UnityGI gi)
 {
     gi = UnityGlobalIllumination (data, s.Occlusion, s.Smoothness, s.Normal);
 }

void surf (Input IN, inout SurfaceOutputStandard o) {
    // Albedo comes from a texture tinted by color
    fixed4 albedo = tex2D (_MainTex, IN.uv_MainTex);

#if _OVERLAY_ON
    fixed4 overlay = tex2D (_OverlayTex, IN.uv2_OverlayTex);
    albedo.rgb = lerp (albedo, overlay, overlay.a).rgb;
#endif
    
#if _EDGE_ON
    float3 worldNormal = normalize(o.Normal);
    float3 dfdxn = ddx_fine(worldNormal);
    float3 dfdyn = ddy_fine(worldNormal);
    float ndotv = dot(normalize(IN.viewDir), worldNormal);
    float isedge = length((abs(dfdxn) + abs(dfdyn)) * _EdgeStrengthCurve);
    isedge = saturate((isedge * _EdgeStrengthPlanar) - 1.0);
    //isedge *= pow2(1.0 - saturate(ndotv));
    isedge = smoothstep(0.375, 0.5, isedge);
    albedo = isedge;//lerp(albedo, albedo * albedo * albedo, isedge);
#endif

#if _NORMAL_MAP_ON
    o.Normal = UnpackNormal(tex2D(_NormalMapTex, IN.uv_MainTex));
#else
    o.Normal = float3(0,0,1);
#endif

#if _BACKFACE_ON
    o.Normal *= -1;
#endif

    o.Albedo = albedo.rgb;
    o.Occlusion = 1.0;
    o.Metallic = 0;
    o.Smoothness = 0;
    //o.Alpha = 1;
}