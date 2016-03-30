Shader "Hidden/Mud/NPREdgeApply"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        _EdgeColor ("EdgeColor", Color) = (0, 0, 0, 1)
        _EdgeAutoColoring ("EdgeAutoColoring", Float) = 0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            sampler2D _MainTex;
            sampler2D _NPREdgeAlbedoTex; // global property
            float4 _EdgeColor;
            float _EdgeAutoColoring;

            half3 rgb2yuv(half3 c)
            {
                half y = dot(c, half3(0.299, 0.587, 0.114));
                half u = dot(c, half3(-0.14713, -0.2886, 0.436));
                half v = dot(c, half3(0.615,-0.51499, -0.10001));
                return (half3(y, u, v));
            }

            half3 yuv2rgb(half3 c)
            {
                half r = dot(c, half3(1, 0, 1.13983));
                half g = dot(c, half3(1, -0.39465, -0.58060));
                half b = dot(c, half3(1, 2.03211, 0));
                return saturate(half3(r, g, b));
            }


            half4 frag (v2f i) : SV_Target
            {
                half3 base = tex2D(_NPREdgeAlbedoTex, i.uv).rgb;

                base = rgb2yuv(base);
                base.r = 1.0 - base.r;
                base = yuv2rgb(base);

                half4 edge;
                edge.rgb = lerp(_EdgeColor.rgb, base, _EdgeAutoColoring);
                edge.a = tex2D(_MainTex, i.uv).r * _EdgeColor.a;
                
                return edge;
            }
            ENDCG
        }
    }
}
