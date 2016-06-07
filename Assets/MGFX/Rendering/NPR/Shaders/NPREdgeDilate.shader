Shader "Hidden/MGFX/NPREdgeDilate"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        //Blend SrcAlpha OneMinusSrcAlpha

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
            float4 _MainTex_TexelSize;
            float4 _ScreenTexelSize; // global properties

            fixed4 fetch(sampler2D tex, float2 uv)
            {
                return tex2D(tex, uv);
            }

            float4 pow2(float4 _v)
            {
                return _v * _v;
            }

            float4 pow4(float4 _v)
            {
                return _v * _v * _v * _v;
            }

            fixed4 deilate(sampler2D tex, float2 uv, float4 texelSize, float s)
            {
                fixed4 t[9];
                
                t[0] = fetch(tex, uv + float2(-s,-s) * texelSize.xy);
                t[1] = fetch(tex, uv + float2(-s, 0) * texelSize.xy);
                t[2] = fetch(tex, uv + float2(-s, s) * texelSize.xy);

                t[3] = fetch(tex, uv + float2( 0,-s) * texelSize.xy);
                t[4] = fetch(tex, uv + float2( 0, 0) * texelSize.xy);
                t[5] = fetch(tex, uv + float2( 0, s) * texelSize.xy);

                t[6] = fetch(tex, uv + float2( s,-s) * texelSize.xy);
                t[7] = fetch(tex, uv + float2( s, 0) * texelSize.xy);
                t[8] = fetch(tex, uv + float2( s, s) * texelSize.xy);

                half4 ret = max(t[0], t[1]);
                ret = max(ret, t[2]);
                ret = max(ret, t[3]);
                ret = max(ret, t[4]);
                ret = max(ret, t[5]);
                ret = max(ret, t[6]);
                ret = max(ret, t[7]);
                ret = max(ret, t[8]);
                return ret;
            }

            #define TAP_COUNT 5

            // deilation by detecting the edge of edges
            fixed4 deilate2(sampler2D tex, float2 uv, float4 texelSize)
            {
                //           x x
                // fetch the  o  patterns
                //           x x
            	half2 tuv[TAP_COUNT];
            	tuv[0] = uv + float2( 1, 1) * texelSize.xy;
            	tuv[1] = uv + float2(-1,-1) * texelSize.xy;
            	tuv[2] = uv + float2(-1, 1) * texelSize.xy;
            	tuv[3] = uv + float2( 1,-1) * texelSize.xy;
            	tuv[4] = uv + float2( 0, 0) * texelSize.xy;

                half4 t[TAP_COUNT];
                t[0] = fetch(tex, tuv[0]);
                t[1] = fetch(tex, tuv[1]);
                t[2] = fetch(tex, tuv[2]);
                t[3] = fetch(tex, tuv[3]);
                t[4] = fetch(tex, tuv[4]);

                // blur
                half4 isedge = (t[0] + t[1] + t[2] + t[3]) * 0.25;

                // average with center tap
                isedge += t[4];
                isedge *= 0.5;

                // subtract by the center tap
                isedge -= t[4];

                half edge = saturate(isedge.r > 0.01);

                // combine with the original edge
                return edge + t[4].r;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 ret = deilate2(_MainTex, i.uv, _ScreenTexelSize * 0.5);

                return ret;
            }
            ENDCG
        }
    }
}
