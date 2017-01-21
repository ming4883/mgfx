
sampler2D _MudBloomTex;
sampler2D _MudWhitePointTex;

uniform half4 _BloomParameter;
uniform half4 _ToneMappingParameter;

#define ONE_MINUS_THRESHHOLD_TIMES_INTENSITY _BloomParameter.w
#define THRESHHOLD _BloomParameter.z

struct v2f_hdr
{
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD0;

#if UNITY_UV_STARTS_AT_TOP
    half2 uv2 : TEXCOORD1;
#endif
};

v2f_hdr vertHDR(appdata_img v)
{
    v2f_hdr o;
    
    o.pos = UnityObjectToClipPos (v.vertex);
    o.uv = v.texcoord;

#if UNITY_UV_STARTS_AT_TOP
    o.uv2 = v.texcoord;
    if (_MainTex_TexelSize.y < 0.0)
        o.uv.y = 1.0 - o.uv.y;
#endif

    return o;
}

float3 Uncharted2ToneMapping(float3 color, float w)
{
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;

    float4 mapped = float4(color, w);
    mapped = ((mapped * (A * mapped + C * B) + D * E) / (mapped * (A * mapped + B) + D * F)) - E / F;

    return saturate(mapped.rgb / mapped.w);
}

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float3 ACESFilmicToneMapping(float3 x, float w)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;

    float4 mapped = float4(x, w);

    mapped = (mapped*(a*mapped + b)) / (mapped*(c*mapped + d) + e);
    mapped = saturate(mapped);

    return saturate(mapped.rgb / mapped.a);
}

float3 ToneMapping(float3 x, float w)
{
    return Uncharted2ToneMapping(x, w);
    //return ACESFilmicToneMapping(x, w);
}

half4 fragHDRBase(v2f_hdr i) : SV_Target
{
    float2 uv1, uv2;

    #if UNITY_UV_STARTS_AT_TOP
    {
        uv1 = i.uv2;
        uv2 = i.uv;
    }
    #else
    {
        uv1 = i.uv;
        uv2 = i.uv;
    }
    #endif

    half4 color = tex2D(_MainTex, uv1);
    half4 bloom = tex2D(_MudBloomTex, uv2);
    half4 center = tex2D(_MudWhitePointTex, half2(0.0, 0.0));

    half e = _ToneMappingParameter.x;
    half w = (_ToneMappingParameter.y * max(center.r, 0.5)) / (bloom.a + 1);
    color.rgb = ToneMapping(color.rgb * e, w);
    color.rgb += ToneMapping(bloom.rgb * e, w);

    color.rgb = saturate(color.rgb);

    return color;
}
