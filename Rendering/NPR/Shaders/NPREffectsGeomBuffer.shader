Shader "Hidden/MGFX/NPREffectsGeomBuffer" {
Properties {
	//_MainTex ("", 2D) = "white" {}
}

SubShader {
	Tags {"RenderType"="Opaque"}
	LOD 100
	
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				//float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 vcolor : COLOR;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				//half2 texcoord : TEXCOORD0;
				float3 normal : TEXCOORD0;
				float4 vcolor : COLOR;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				//o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

				o.normal.xyz = mul((float3x3)unity_WorldToCamera, UnityObjectToWorldNormal(v.normal));
				//o.normal.xyz = UnityObjectToWorldNormal(v.normal);
				o.vcolor = v.vcolor;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				return float4(normalize(i.normal.xyz) * 0.5 + 0.5, i.vcolor.a);
			}
		ENDCG
	}
}

}
