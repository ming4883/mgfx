Shader "Hidden/Minverse/NPREdgeDilate"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            fixed4 deilate(sampler2D tex, float2 uv)
            {
                //uv = uv - _MainTex_TexelSize.xy * 0.5;
                fixed4 t[9];
                
                t[0] = fetch(tex, uv + float2(-1,-1) * _MainTex_TexelSize.xy);
                t[1] = fetch(tex, uv + float2(-1, 0) * _MainTex_TexelSize.xy);
                t[2] = fetch(tex, uv + float2(-1, 1) * _MainTex_TexelSize.xy);

                t[3] = fetch(tex, uv + float2( 0,-1) * _MainTex_TexelSize.xy);
                t[4] = fetch(tex, uv + float2( 0, 0) * _MainTex_TexelSize.xy) * 24;
                t[5] = fetch(tex, uv + float2( 0, 1) * _MainTex_TexelSize.xy);

                t[6] = fetch(tex, uv + float2( 1,-1) * _MainTex_TexelSize.xy);
                t[7] = fetch(tex, uv + float2( 1, 0) * _MainTex_TexelSize.xy);
                t[8] = fetch(tex, uv + float2( 1, 1) * _MainTex_TexelSize.xy);

                half4 sum = 
                    t[0] +
                    t[1] +
                    t[2] +
                    
                    t[3] +
                    t[4] +
                    t[5] +
                    
                    t[6] +
                    t[7] +
                    t[8] ;
                return 1.0 - pow2(1.0 - sum / 32.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 tap = deilate(_MainTex, i.uv);

                return tap;
            }
            ENDCG
        }
    }
}
