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
            //sampler2D _CameraGBufferTexture0;

            half4 frag (v2f i) : SV_Target
            {
                half4 base = tex2D(_AlbedoCopyTex, i.uv);
                half4 dark = pow(base - 1 / 32.0, 2);
                half4 edge = tex2D(_MainTex, i.uv);
                return half4(dark.rgb, edge.a);
            }
            ENDCG
        }
    }
}
