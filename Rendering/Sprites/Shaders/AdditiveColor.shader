Shader "MGFX/Sprites/AdditiveColor"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Mixin ("Additive Color", Color) = (1,0,0,0.5)
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		[Toggle(_IMPROVED_FILTERING)] _ImprovedFiltering("Sharp Filtering", Int) = 1
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

		Pass
		{
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile _ PIXELSNAP_ON
				#pragma shader_feature _IMPROVED_FILTERING

				#include "SpriteBase.cginc"

				fixed4 frag(v2f IN) : SV_Target
				{
					fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;
					c.rgb = c.rgb + (_Mixin.rgb * _Mixin.a);
					return c;
				}
			ENDCG
		}
	}
}
