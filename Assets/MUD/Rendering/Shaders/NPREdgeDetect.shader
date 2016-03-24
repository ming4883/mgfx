Shader "Hidden/Minverse/NPREdgeDetect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeThreshold ("EdgeThreshold", Vector) = (0, 0, 0, 0)
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
            #include "OctEncode.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            
            sampler2D _CameraDepthNormalsTexture;
            float4 _CameraDepthNormalsTexture_TexelSize;

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

            fixed4 edgeDetect(sampler2D tex, float4 texelSize, float2 uv)
            {
                // fetch the 3x3 taps
                half4 t[9];
                t[0] = fetch(tex, uv + float2(-1,-1) * texelSize.xy);
                t[1] = fetch(tex, uv + float2(-1, 0) * texelSize.xy);
                t[2] = fetch(tex, uv + float2(-1, 1) * texelSize.xy);

                t[3] = fetch(tex, uv + float2( 0,-1) * texelSize.xy);
                t[4] = fetch(tex, uv + float2( 0, 0) * texelSize.xy);
                t[5] = fetch(tex, uv + float2( 0, 1) * texelSize.xy);

                t[6] = fetch(tex, uv + float2( 1,-1) * texelSize.xy);
                t[7] = fetch(tex, uv + float2( 1, 0) * texelSize.xy);
                t[8] = fetch(tex, uv + float2( 1, 1) * texelSize.xy);

                half4 hedge = 0;

                hedge -= t[0] * 1.0;
                hedge -= t[1] * 2.0;
                hedge -= t[2] * 1.0;
                hedge += t[6] * 1.0;
                hedge += t[7] * 2.0;
                hedge += t[8] * 1.0;

                half4 vedge = 0;

                vedge -= t[0] * 1.0;
                vedge -= t[3] * 2.0;
                vedge -= t[6] * 1.0;
                vedge += t[2] * 1.0;
                vedge += t[5] * 2.0;
                vedge += t[8] * 1.0;

                half4 cnt = t[4];
                
                half3 viewNorm = OctDecode(cnt.xy);
                float ndotv = saturate( dot(viewNorm, float3(0, 0, 1)) );
                

                half depth = cnt.z;
                half n_threshold = _EdgeThreshold.x;
                half d_threshold = _EdgeThreshold.y * (1-ndotv);

                half4 isedge = ((hedge * hedge) + (vedge * vedge)) > float4(n_threshold, n_threshold, d_threshold, 0);

                half innerMask = 0.5;
                half outerMask = 0.0;

                return saturate (dot(isedge, float4(innerMask, innerMask, outerMask, 0)));
                
            }

#if _LARGE_KERNEL
#define TAP_COUNT 9
#else
#define TAP_COUNT 5
#endif

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
#if _LARGE_KERNEL
                t[5] = fetch(tex, uv + float2( 2, 2) * texelSize.xy);
                t[6] = fetch(tex, uv + float2(-2,-2) * texelSize.xy);
                t[7] = fetch(tex, uv + float2(-2, 2) * texelSize.xy);
                t[8] = fetch(tex, uv + float2( 2,-2) * texelSize.xy);
#endif
                // blur
#if _LARGE_KERNEL
                half4 isedge = (t[0] + t[1] + t[2] + t[3] + t[5] + t[6] + t[7] + t[8]) * 0.125;
#else
                half4 isedge = (t[0] + t[1] + t[2] + t[3]) * 0.25;
#endif
                // average with center tap
                isedge += t[4];
                isedge *= 0.5;

                // subtract by the center tap
                isedge -= t[4];

                half innerMask = 20.0 * _EdgeThreshold.w;
                half outerMask = 0.0 * _EdgeThreshold.w;

                return saturate (dot(isedge, float4(innerMask, innerMask, outerMask, 0)));
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 edge = edgeDetect2(_CameraDepthNormalsTexture, _CameraDepthNormalsTexture_TexelSize, i.uv);
                
                return edge.rrrr;
            }
            ENDCG
        }
    }
}
