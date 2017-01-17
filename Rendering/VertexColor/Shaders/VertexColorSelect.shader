
Shader "Hidden/MGFX/VertexColorSelect" {
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
				float4 vcolor : COLOR;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float4 vcolor : TEXCOORD0;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vcolor = v.vcolor;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				return i.vcolor;
			}
		ENDCG
	}
}

}
