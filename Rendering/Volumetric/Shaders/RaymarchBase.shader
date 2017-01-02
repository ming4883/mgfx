Shader "Unlit/RaymarchBase"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            //ZTest Always Cull Off ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }


            struct Ray
            {
                float3 org;
                float3 dir;
            };

            float SDSphere(float3 p, float s)
            {
                return length(p)-s;
            }

            float2 Scene(float3 pos)
            {
                float2 dRet;
                dRet.x = SDSphere(pos, 0.5);
                dRet.y = 0;
                return dRet;
            }

            bool Raymarch(Ray ray, out float3 hitPos, out float2 hitInfo)
            {
                const float hitThreshold = 0.0001;

                bool hit = false;
                hitPos = ray.org;
    
                float3 pos = ray.org;

                for (int i = 0; i < 128; i++)
                {
                    float2 s = Scene(pos);

                    if (s.x < hitThreshold)
                    {
                        hit = true;
                        hitPos = pos;
                        hitInfo = s;
                        break;
                    }
                    pos += s.x * ray.dir;
                }
    
                return hit;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                Ray ray;
                ray.org = _WorldSpaceCameraPos.xyz;
                ray.dir = i.worldPos - _WorldSpaceCameraPos.xyz;

                ray.dir = normalize(ray.dir);

                float3 hitPos;
                float2 hitInfo;
                if (Raymarch(ray, hitPos, hitInfo))
                {
                    return float4(-ray.dir * 0.5 + 0.5, 0.5);
                }

                clip(-1);
                return 0;
            }
            ENDCG
        }
    }
}
