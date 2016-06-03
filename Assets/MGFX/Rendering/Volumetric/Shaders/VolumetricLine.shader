Shader "MGFX/VolumetricLine"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            ZTest Off Cull Off ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv = v.texcoord;
                o.worldPos = mul(_Object2World, v.vertex);
                return o;
            }

            uniform float _VolLineRadius;
            uniform float4 _VolLineColor;
            uniform float3 _VolLinePoint0;
            uniform float3 _VolLinePoint1;

            struct Ray
            {
                float3 org;
                float3 dir;
            };

            // http://geomalgorithms.com/a07-_distance.html
            float3 DistanceLine(Ray r,  float3 a, float3 b)
            {
                float3 ba = b - a;		// U
                                 		// V = d
                float3 oa = r.org - a;	// W
    
                float baba = dot( ba, ba ); 	// A
                float dba  = dot( r.dir, ba ); 	// B
                                            	// C = dot(V, V) = 1
                float oaba = dot( oa, ba ); 	// D
                float oad  = dot( oa,  r.dir );	// E
                
                float denom = (baba - dba*dba); // AC - B^2
    
                float2 th = float2( -oad*baba + dba*oaba, oaba - oad*dba ) / denom;
                th.x = max(   th.x, 0.0 );
                th.y = clamp( th.y, 0.0, 1.0 );
    
                float3 p = a + ba*th.y;
                float3 q = r.org + r.dir*th.x;
    
                return float3( length( p-q ), th );
            }

            // http://geomalgorithms.com/a02-_lines.html
            float3 DistancePoint(Ray r,  float3 p)
            {
            	float3 po = p - r.org;

            	float t = dot(po, r.dir);
            	t = max(t, 0);
            	float3 q = r.org + t * r.dir;

            	return float3( length( p-q ), t, 0 );
            }

            fixed4 frag (v2f i) : SV_Target
            {
                Ray ray;
                ray.org = _WorldSpaceCameraPos.xyz;
                ray.dir = i.worldPos - _WorldSpaceCameraPos.xyz;
                ray.dir = normalize(ray.dir);

                float3 a = _VolLinePoint0;
                float3 b = _VolLinePoint1;

                float3 d1 = DistanceLine(ray, a, b);
                float3 d2 = DistancePoint(ray, a);
                float3 d3 = DistancePoint(ray, b);

                float dm = min(min(d1.x, d2.x), d3.x);
                float s = 1 - saturate(dm / _VolLineRadius);
                return float4(_VolLineColor.rgb * s * _VolLineColor.a, s);
            }
            ENDCG
        }
    }
}
