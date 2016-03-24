Shader "Hidden/Minverse/NPRNormalDepth"
{
	Properties
	{
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
			
			sampler2D _CameraDepthNormalsTexture;

			half4 frag (v2f i) : SV_Target
			{
				half4 depthNrm = tex2D(_CameraDepthNormalsTexture, i.uv);

				half viewDepth;
                half3 viewNormal;
                DecodeDepthNormal(depthNrm, viewDepth, viewNormal);

                if (viewDepth > 1 - 1 / 65536.0) // skybox
                	return half4(0, 0, 0, 0);
				//return half4(OctEncode(viewNormal), viewDepth, 1);
                return half4(depthNrm.xy, viewDepth, 1);
			}
			ENDCG
		}
	}
}
