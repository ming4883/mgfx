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
    sampler2D _BayerTex;

    half dither(in v2f i)
    {
    	return tex2D(_BayerTex, ComputeScreenPos(i.pos).xy / 8.0).r;
    }

    half shadowTerm(in v2f i)
    {
    	fixed d = dither(i);
    	half s = SHADOW_ATTENUATION(i); 
    	s = s * (s + (1 - s) * d);
    	return s;
    }

    void fade(in v2f i, fixed facing)
    {
    	half viewZ = i.worldPosAndZ.w;
    	//half viewZ = -mul( UNITY_MATRIX_V, float4(i.worldPosAndZ.xyz, 1.0) ).z;
    	half d = dither(i);

    	half f = 1 - smoothstep(_ProjectionParams.y, _ProjectionParams.y * 4, viewZ);

    	if((facing < 1))
    		f = max(f, 0.75);
    	clip(d - f);

    }

    ENDCG

    SubShader
    {
    	Tags
    	{ 
        	"RenderType"="Opaque"
        }

        Cull Off

        Pass
        {
            Tags
            {
            	"LightMode"="ForwardBase"
            }

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

                col.rgb = lerp(pow(col, 4.0), col, ndotl) * _LightColor0.rgb;
                //col.rgb = float3(facing, facing, facing);
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

                col.rgb = lerp(pow(col, 4.0), col, ndotl) * _LightColor0.rgb;
                col.rgb *= lightAtten;

                return col;
            }
            ENDCG
        }

        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}