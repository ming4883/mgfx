Shader "Hidden/Mud/NPREdgeApply"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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
            sampler2D _AlbedoCopyTex; // global property

            half4 frag (v2f i) : SV_Target
            {
                half4 base = tex2D(_AlbedoCopyTex, i.uv);
                half4 dark = ((1.0 - base) * (1.0 - base) + base * base) * 0.5;//pow(min(base, 1.0 - 1.0 / 16.0), 3);
                half4 edge = tex2D(_MainTex, i.uv);
                return half4(lerp(base, dark, edge.r).rgb, base.a);
            }
            ENDCG
        }
    }
}
