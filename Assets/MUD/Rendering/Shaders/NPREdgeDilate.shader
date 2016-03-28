Shader "Hidden/Mud/NPREdgeDilate"
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

            fixed4 deilate(sampler2D tex, float2 uv, float4 texelSize)
            {
                fixed4 t[9];
                
                t[0] = fetch(tex, uv + float2(-1,-1) * texelSize.xy);
                t[1] = fetch(tex, uv + float2(-1, 0) * texelSize.xy);
                t[2] = fetch(tex, uv + float2(-1, 1) * texelSize.xy);

                t[3] = fetch(tex, uv + float2( 0,-1) * texelSize.xy);
                t[4] = fetch(tex, uv + float2( 0, 0) * texelSize.xy);
                t[5] = fetch(tex, uv + float2( 0, 1) * texelSize.xy);

                t[6] = fetch(tex, uv + float2( 1,-1) * texelSize.xy);
                t[7] = fetch(tex, uv + float2( 1, 0) * texelSize.xy);
                t[8] = fetch(tex, uv + float2( 1, 1) * texelSize.xy);

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

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 ret = deilate(_MainTex, i.uv, _ScreenTexelSize);

                return ret;
            }
            ENDCG
        }
    }
}
