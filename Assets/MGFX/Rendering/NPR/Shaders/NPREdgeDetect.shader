Shader "Hidden/MGFX/NPREdgeDetect"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "" {}
        //_ScreenTexelSize ("ScreenTexelSize", Vector) = (0, 0, 0, 0)
        _EdgeThreshold ("EdgeThreshold", Vector) = (0, 0, 0, 1)
        _EdgeThickness ("EdgeThickness", Float) = 0.5
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

            //sampler2D _MainTex;
            //float4 _MainTex_TexelSize;
            uniform float4 _ScreenTexelSize; // global properties
            uniform sampler2D _CameraDepthNormalsTexture;
            
            uniform float4 _EdgeThreshold;
            uniform float _EdgeThickness;

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

            // Boundary check for depth sampler
            // (returns a very large value if it lies out of bounds)
            float CheckBounds(float2 uv, float d)
            {
                float ob = any(uv < 0) + any(uv > 1) + (d >= 0.99999);
                return ob * 1e8;
            }

            float SampleDepthNormal(float2 uv, out float3 normal)
            {
                float4 cdn = tex2D(_CameraDepthNormalsTexture, uv);
                normal = DecodeViewNormalStereo(cdn) * float3(1, 1, -1);
                float d = DecodeFloatRG(cdn.zw);
                //d = d * _ProjectionParams.z + CheckBounds(uv, d);
                d = d * _ProjectionParams.z;
                //d -= _ProjectionParams.z / 65536;
                return d;
            }

            half4 Fetch(float2 uv)
            {
                float3 normal;
                float depth = SampleDepthNormal(uv, normal);
                return half4(normal, depth);
            }

            #define TAP_COUNT 5

            // Reconstruct view-space position from UV and depth.
		    // p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
		    // p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
		    float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
		    {
		        return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
		    }

            // https://www.shadertoy.com/view/XsVGW1#
            // http://graphics.cs.cmu.edu/courses/15-463/2005_fall/www/Lectures/convolution.pdf
            fixed4 EdgeDetector(float4 texelSize, float2 uv)
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
                t[0] = Fetch(tuv[0]);
                t[1] = Fetch(tuv[1]);
                t[2] = Fetch(tuv[2]);
                t[3] = Fetch(tuv[3]);
                t[4] = Fetch(tuv[4]);

                half2 d[TAP_COUNT];
                d[4] = half2(0, 0);

                float thresholdZ = _EdgeThreshold.x;

                #if 1

                d[0].x = abs(t[0].w - t[4].w);
                d[1].x = abs(t[1].w - t[4].w);
                d[2].x = abs(t[2].w - t[4].w);
                d[3].x = abs(t[3].w - t[4].w);

                #else

                float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
        		float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

        		float3 p[TAP_COUNT];
        		p[0] = ReconstructViewPos(tuv[0], t[0].w, p11_22, p13_31);
        		p[1] = ReconstructViewPos(tuv[1], t[1].w, p11_22, p13_31);
        		p[2] = ReconstructViewPos(tuv[2], t[2].w, p11_22, p13_31);
        		p[3] = ReconstructViewPos(tuv[3], t[3].w, p11_22, p13_31);
        		p[4] = ReconstructViewPos(tuv[4], t[4].w, p11_22, p13_31);

        		d[0].x = distance(p[0], p[4]);
                d[1].x = distance(p[1], p[4]);
                d[2].x = distance(p[2], p[4]);
                d[3].x = distance(p[3], p[4]);

                #endif

                float thresholdAngle = _EdgeThreshold.y;

                d[0].y = (1 - dot(t[0].xyz, t[4].xyz));
                d[1].y = (1 - dot(t[1].xyz, t[4].xyz));
                d[2].y = (1 - dot(t[2].xyz, t[4].xyz));
                d[3].y = (1 - dot(t[3].xyz, t[4].xyz));

                // blur
                half2 isedge = (d[0] + d[1] + d[2] + d[3]) * 0.25;

                // average with center tap
                isedge += d[4];
                isedge *= 0.5;

                // subtract by the center tap
                isedge -= d[4];

                // fade out depth edges
                //isedge.x *= 1 - smoothstep(_ProjectionParams.z * 0.01, _ProjectionParams.z * 0.02, t[4].w);

                half edge = dot(isedge.xy, _EdgeThreshold.xy);
                return edge;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 edge = EdgeDetector(_ScreenTexelSize * _EdgeThickness, i.uv);
                return edge.rrrr;
            }
            ENDCG
        }
    }
}
