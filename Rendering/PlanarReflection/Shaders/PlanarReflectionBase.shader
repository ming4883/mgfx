Shader "MGFX/PlanarReflection/Base"
{
	Properties
	{
		_ReflectionTex("_ReflectionTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags{ 
			"PreviewType"="Plane"
			"RenderType" = "Opaque"
		}
		LOD 100
		Cull Off
		Lighting Off

		Pass{

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 refl : TEXCOORD1;
			float4 pos : SV_POSITION;
		};
		v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(pos);
			o.uv = uv;
			o.refl = ComputeScreenPos(o.pos);
			return o;
		}

		sampler2D _ReflectionTex;
		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
			return refl;
		}

		ENDCG
		}
	}

}