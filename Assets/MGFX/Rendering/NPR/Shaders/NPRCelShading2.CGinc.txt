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