// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "MGFXAutoLight.cginc"
#include "MGFXNoise.cginc"

///
/// Vertex
///
struct v2f
{
    float2 uv : TEXCOORD0;
    SHADOW_COORDS(1) // put shadows data into TEXCOORD1
    float3 worldNormal : TEXCOORD2;
    float4 worldPosAndZ : TEXCOORD3;
    float4 pos : SV_POSITION;
};

v2f vert (appdata_base v)
{
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = v.texcoord;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPosAndZ.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
    COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
    // compute shadows data
    TRANSFER_SHADOW(o)
    return o;
}

///
/// Fragment
///
sampler2D _MainTex;
sampler2D _DiffuseLUTTex;

half dither(in v2f i)
{
	half d1 = Bayer(i.pos.xy);
	half d2 = InterleavedGradientNoise(i.pos.xy);

	//return clamp(d2 + d1 * 0.5, -1, 1);
	return clamp(d1 + d2 * 0.0625, -1, 1);
	//return (d1 + d2) * 0.5;
	//return d1;
}

half shadowTerm(in v2f i)
{
	half s = SHADOW_ATTENUATION(i);
	fixed d = dither(i);
	//s = s * (s + (1 - s) * d);
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

half4 frag_base (v2f i, fixed vface : VFACE) : SV_Target
{
    half4 col = tex2D(_MainTex, i.uv);

   	fade(i, vface);

    fixed shadow = shadowTerm(i);

    half3 worldNormal = normalize(i.worldNormal) * vface;

    half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);
    ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * shadow).r;

    col.rgb = lerp(pow(col * 0.9, 2.0), col, ndotl) * _LightColor0.rgb;

    if (vface < 0)
    	col.rgb = lerp(0, col.rgb, 0.25);
    return col;
}


half4 frag_add (v2f i, fixed vface : VFACE) : SV_Target
{
    half4 col = tex2D(_MainTex, i.uv);

    fade(i, vface);

    MGFX_LIGHT_ATTENUATION(lightAtten, i, i.worldPosAndZ.xyz);
    fixed shadow = shadowTerm(i);

    half3 worldNormal = normalize(i.worldNormal) * vface;

    half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);
    ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * shadow).r;

    col.rgb = lerp(pow(col * 0.9, 2.0), col, ndotl) * _LightColor0.rgb;
    col.rgb *= lightAtten;

    if (vface < 0)
    	col.rgb = lerp(0, col.rgb, 0.25);
    return col;
}