Shader "MGFX/FlowDisplay" {
	Properties {
		_FlowMapTex ("FlowMap", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _FlowMapTex;

		struct Input {
			float3 worldPos;
		};

		half4x4 _FlowMapMatrix;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {

			half2 uv_FlowMap = mul(_FlowMapMatrix, half4(IN.worldPos, 1)).xy;
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_FlowMapTex, uv_FlowMap);
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = 0.0f;
			o.Smoothness = 1.0f;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
