Shader "Hidden/Mud/NPREdgeApply"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        _EdgeColor ("EdgeColor", Color) = (0, 0, 0, 1)
        _EdgeAutoColoring ("EdgeAutoColoring", Float) = 0
        _EdgeAutoColorFactor ("EdgeAutoColorFactor", Float) = 0
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

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;

            uniform sampler2D _EdgeTex; // global property
            uniform float4 _EdgeColor;
            uniform float _EdgeAutoColoring;
            uniform float _EdgeAutoColorFactor;

            v2f vert (appdata_img v)
            {
                float vflip = -1;//sign(_MainTex_TexelSize.y);

                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv0 = v.texcoord.xy;
                o.uv1 = (v.texcoord.xy - 0.5) * float2(1, vflip) + 0.5;
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half4 base = tex2D(_MainTex, i.uv1);
                base.rgb = pow(base.rgb, _EdgeAutoColorFactor);

                half4 edge;
                edge.rgb = _EdgeColor.rgb;
                edge.rgb = lerp(edge.rgb, base.rgb, _EdgeAutoColoring);
                edge.a = tex2D(_EdgeTex, i.uv0).r * _EdgeColor.a;
                
                return edge;
            }
            ENDCG
        }
    }
}
