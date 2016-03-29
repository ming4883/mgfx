Shader "Hidden/Mud/NPREdgeApply"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        _EdgeColor ("EdgeColor", Color) = (0, 0, 0, 1)
        _EdgeAutoColorize ("EdgeAutoColorize", Float) = 0
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
            sampler2D _AlbedoCopyTex; // global property
            float4 _EdgeColor;
            float _EdgeAutoColorize;
            //sampler2D _CameraGBufferTexture0;

            half4 frag (v2f i) : SV_Target
            {
                half4 base = tex2D(_AlbedoCopyTex, i.uv);
                half4 edge = pow(base - 1 / 16.0, 2);
                edge.rgb = lerp(_EdgeColor.rgb, edge.rgb, _EdgeAutoColorize);
                edge.a = tex2D(_MainTex, i.uv).r * _EdgeColor.a;
                
                return edge;
            }
            ENDCG
        }
    }
}
