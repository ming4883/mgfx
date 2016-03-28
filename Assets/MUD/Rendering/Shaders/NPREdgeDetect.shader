Shader "Hidden/Mud/NPREdgeDetect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        //_ScreenTexelSize ("ScreenTexelSize", Vector) = (0, 0, 0, 0)
        _EdgeThreshold ("EdgeThreshold", Vector) = (0, 0, 0, 1)
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

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _ScreenTexelSize; // global properties
            
            //sampler2D _CameraDepthNormalsTexture;
            //float4 _CameraDepthNormalsTexture_TexelSize;

            float4 _EdgeThreshold;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
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
                o.uv = v.texcoord.xy;
                //
#if UNITY_UV_STARTS_AT_TOP
                //
                //if (_MainTex_TexelSize.y < 0)
                //   o.uv.y = 1 - o.uv.y;
#endif
                
                return o;
            }

            fixed4 fetch(sampler2D tex, float2 uv)
            {
                return tex2D(tex, uv);
            }

            half hasContent(half4 tap)
            {
                return (tap.w  > 0);
            }

#define TAP_COUNT 5

            // https://www.shadertoy.com/view/XsVGW1#
            // http://graphics.cs.cmu.edu/courses/15-463/2005_fall/www/Lectures/convolution.pdf
            fixed4 edgeDetect2(sampler2D tex, float4 texelSize, float2 uv)
            {
                //           x x
                // fetch the  o  patterns
                //           x x
                half4 t[TAP_COUNT];
                t[0] = fetch(tex, uv + float2( 1, 1) * texelSize.xy);
                t[1] = fetch(tex, uv + float2(-1,-1) * texelSize.xy);
                t[2] = fetch(tex, uv + float2(-1, 1) * texelSize.xy);
                t[3] = fetch(tex, uv + float2( 1,-1) * texelSize.xy);

                t[4] = fetch(tex, uv + float2( 0, 0) * texelSize.xy);

                // blur
                half4 isedge = (t[0] + t[1] + t[2] + t[3]) * 0.25;
                // average with center tap
                isedge += t[4];
                isedge *= 0.5;

                // subtract by the center tap
                isedge -= t[4];

                half innerMask = 50.0;// * _EdgeThreshold.w;

                return saturate (dot(isedge, float4(innerMask, innerMask, innerMask, 0)));
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 edge = edgeDetect2(_MainTex, _ScreenTexelSize, i.uv);
                
                return edge.rrrr;

                //return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}
