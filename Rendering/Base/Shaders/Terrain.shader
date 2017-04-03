Shader "MGFX/Terrain" {
	Properties {
		[HideInInspector] _Control  ("Control (RGB)", 2D) = "white" {}
		_Splat0 ("Splat0 (RGBA)", 2D) = "white" {}
		_Splat1 ("Splat1 (RGBA)", 2D) = "white" {}
		_AutoMapScale ("AutoMapScale", Range(0, 1024)) = 1.0
		_DitherScale ("_DitherScale", Range(0, 1024)) = 1.0
		_DitherStrength ("_DitherStrength", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		uniform sampler2D _Control;
		uniform sampler2D _Splat0;
		uniform sampler2D _Splat1;
		uniform half4 _Splat0_TexelSize;
		uniform half _AutoMapScale;
		uniform half _DitherScale;
		uniform half _DitherStrength;

		struct Input {
			float2 uv_Control;
			float3 worldPos;
			float3 worldNormal; INTERNAL_DATA
		};

		uniform half _Metallic;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		#include "Noise.cginc"

		void vert (inout appdata_full v) {
			//v.texcoord.xy = planarMap(v.vertex * _AutoMapScale, v.normal);
		}

		float getDither(float2 vScreenPos)
		{
			return noiseValue2FBM2(vScreenPos);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {

			float4 control = tex2D(_Control, IN.uv_Control);
			float2 ditherUV = (noisePlanarMap(IN.worldPos, IN.worldNormal)) * _DitherScale;

			if (_DitherStrength > 0)
			{
				float dither = getDither(ditherUV) * _DitherStrength;
				dither *= 1 - pow(1 - control.g, 4);

				control.r -= dither;
				control.g += dither;
				control = saturate(control);
			}
			
			float2 autoUV = frac(noisePlanarMap(IN.worldPos * _AutoMapScale, IN.worldNormal));
			
			fixed4 splat0 = tex2D (_Splat0, autoUV);
			fixed4 splat1 = tex2D (_Splat1, autoUV);

			// Albedo comes from a texture tinted by color
			//fixed4 c = splat0 * control.r + splat1 * control.g;
			fixed4 c = lerp(splat1, splat0, control.r);
			o.Albedo = c.rgb;

			// Metallic and smoothness come from slider variables
			o.Metallic = c.a * _Metallic;
			o.Smoothness = c.a;
			o.Alpha = 1.0;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
