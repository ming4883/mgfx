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
            /*
            struct v2f_multitex
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            v2f_multitex vert_multitex(appdata_img v)
            {
                // Handles vertically-flipped case.
                float vflip = sign(_MainTex_TexelSize.y);

                v2f_multitex o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv0 = v.texcoord.xy;
                o.uv1 = (v.texcoord.xy - 0.5) * float2(1, vflip) + 0.5;
                return o;
            }
            */
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            
            sampler2D _MainTex;
            sampler2D _MudAlbedoBuffer; // global property
            float4 _MudAlbedoBuffer_TexelSize;
            float4 _EdgeColor;
            float _EdgeAutoColoring;

            v2f vert (appdata_img v)
            {
                float vflip = sign(_MudAlbedoBuffer_TexelSize.y);

                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv0 = v.texcoord.xy;
                o.uv1 = (v.texcoord.xy - 0.5) * float2(1, vflip) + 0.5;
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half4 base = tex2D(_MudAlbedoBuffer, i.uv1);
                base.rgb = base.rgb - 1.0 / 32.0;
                base.rgb = base.rgb * base.rgb;

                half4 edge;
                edge.rgb = _EdgeColor.rgb;
                edge.rgb = lerp(edge.rgb, base.rgb, _EdgeAutoColoring);
                edge.a = tex2D(_MainTex, i.uv0).r * _EdgeColor.a;
                
                return edge;
            }
            ENDCG
        }
    }
}
