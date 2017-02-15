Shader "MGFX/WaterFlowBump" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMapTex ("NormalMap", 2D) = "bump" {}
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

		sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;

		sampler2D _NormalMapTex;
		uniform half4 _NormalMapTex_TexelSize;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMapTex;
			float3 worldPos;
			float3 worldNormal; INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		sampler2D _FlowMapTex;
		half4x4 _FlowMapMatrix;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {

			half2 uv_FlowMap = mul(_FlowMapMatrix, half4(IN.worldPos, 1)).xy;
			half4 flow = tex2D(_FlowMapTex, uv_FlowMap);
			half2 uv_Offset = (flow.xy * 2.0 - 1.0) * _Time.yy * 8;
			half2 uv_NormalMap = (IN.worldPos.xz / 20.0) + uv_Offset * _NormalMapTex_TexelSize.xy;

			o.Normal = UnpackNormal (tex2D (_NormalMapTex, uv_NormalMap));
			
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
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
