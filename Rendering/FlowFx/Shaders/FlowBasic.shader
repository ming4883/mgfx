Shader "MGFX/FlowBasic" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_FlowMapTex("FlowMap", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		uniform sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float3 worldNormal; INTERNAL_DATA
		};

		uniform half _Glossiness;
		uniform half _Metallic;
		uniform fixed4 _Color;

		uniform sampler2D _FlowMapTex;
		uniform half4x4 _FlowMapMatrix;
		uniform half4 _FlowMapParams;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {

			half2 uv_FlowMap = mul(_FlowMapMatrix, half4(IN.worldPos, 1)).xy;
			half4 flow = tex2D(_FlowMapTex, uv_FlowMap);
			flow.xyz = (flow.xyz * 2.0 - 1.0);

			half flowStrength = length(flow.xyz);
			
			half2 offsets = _FlowMapParams.xy;
			offsets *= flowStrength * _FlowMapParams.z;

			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex + flow.xz * offsets.x) * _Color;
			o.Albedo = c.rgb;
			
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
