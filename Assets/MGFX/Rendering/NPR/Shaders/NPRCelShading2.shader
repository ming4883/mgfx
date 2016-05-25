Shader "MGFX/NPRCelShading2"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _DiffuseLUTTex ("Diffuse LUT (R)", 2D) = "white" {}
        [NoScaleOffset] _BayerTex ("Bayer Matrix", 2D) = "white" {}
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "Lighting.cginc"
    #include "MGFXAutoLight.cginc"
    #include "MGFXNoise.cginc"

    struct v2f
    {
        float2 uv : TEXCOORD0;
        SHADOW_COORDS(1) // put shadows data into TEXCOORD1
        float3 worldNormal : TEXCOORD2;
        float4 worldPosAndZ : TEXCOORD3;
        float4 pos : SV_POSITION;
    };
    v2f vert (appdata_base v)
    {
        v2f o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.texcoord;
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
        o.worldPosAndZ.xyz = mul(_Object2World, v.vertex).xyz;
        COMPUTE_EYEDEPTH(o.worldPosAndZ.w);
        // compute shadows data
        TRANSFER_SHADOW(o)
        return o;
    }

    sampler2D _MainTex;
    sampler2D _DiffuseLUTTex;

    half dither(in v2f i)
    {
    	half d1 = Bayer(i.pos.xy);
    	half d2 = InterleavedGradientNoise(i.pos.xy);

    	return (d1 + d2) * 0.5;
    }

    half shadowTerm(in v2f i)
    {
    	half s = SHADOW_ATTENUATION(i);
    	//fixed d = dither(i);
    	//s = s * (s + (1 - s) * d);
    	return s;
    }

    void fade(in v2f i, fixed facing)
    {

    	half viewZ = i.worldPosAndZ.w;
    	half d = dither(i);

    	half f = 1 - smoothstep(_ProjectionParams.y * 2, _ProjectionParams.y * 4, viewZ);
    	f = f * (f + (1 - f) * d);
    	clip(-(f - 0.5));
    }

    ENDCG

    SubShader
    {
    	Tags
    	{ 
        	"RenderType"="Opaque"
        }

        //Cull Off

        Pass
        {
            Tags
            {
            	"LightMode"="ForwardBase"
            }

            //Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodynlightmap novertexlight
            #pragma target 3.0

            half4 frag (v2f i, fixed facing : VFACE) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);

               	fade(i, facing);

                fixed shadow = shadowTerm(i);

                half3 worldNormal = normalize(i.worldNormal);

                half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);
                ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * shadow).r;

                col.rgb = lerp(pow(col * 0.9, 2.0), col, ndotl) * _LightColor0.rgb;
                return col;
            }
            ENDCG
        }

        Pass
        {
            Tags
            {
            	"LightMode"="ForwardAdd"
            }

            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma target 3.0

            half4 frag (v2f i, fixed facing : VFACE) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);

                fade(i, facing);

                MGFX_LIGHT_ATTENUATION(lightAtten, i, i.worldPosAndZ.xyz);
                fixed shadow = shadowTerm(i);

                half3 worldNormal = normalize(i.worldNormal);

                half ndotl = dot(worldNormal, _WorldSpaceLightPos0.xyz);
                ndotl = tex2D(_DiffuseLUTTex, saturate(ndotl * 0.5 + 0.5) * shadow).r;

                col.rgb = lerp(pow(col * 0.9, 2.0), col, ndotl) * _LightColor0.rgb;
                col.rgb *= lightAtten;
                return col;
            }
            ENDCG
        }

        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}