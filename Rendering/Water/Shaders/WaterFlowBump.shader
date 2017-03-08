Shader "MGFX/WaterFlowBump" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMapTex ("NormalMap", 2D) = "bump" {}
		_NoiseTex ("Noise", 2D) = "white" {}
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_TexParams ("Scale, Speed, Cycle, Reserved", Vector) = (20.0, 2.0, 0, 0)
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

		uniform sampler2D _NormalMapTex;
		uniform half4 _NormalMapTex_TexelSize;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMapTex;
			float3 worldPos;
			float3 worldNormal; INTERNAL_DATA
		};

		uniform half _Glossiness;
		uniform half _Metallic;
		uniform fixed4 _Color;

		uniform sampler2D _FlowMapTex;
		uniform half4x4 _FlowMapMatrix;
		uniform half4 _FlowMapParams;

		uniform sampler2D _NoiseTex;

		uniform half4 _TexParams;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		half noise(sampler2D samp, half2 x)
		{
			half2 f = frac(x);
			half2 rg = tex2D(samp, f.xy).yx;
			return rg.x;
		}

		half noiseFBM3(sampler2D samp, half2 x)
		{
			half2x2 noiseRot = half2x2( 1.6,  1.2, -1.2,  1.6 );

			half noiseVal = 0;
			noiseVal += 0.500 * noise(samp, x); x = mul(noiseRot, x * 2.01);
			noiseVal += 0.250 * noise(samp, x); x = mul(noiseRot, x * 2.02);
			noiseVal += 0.250 * noise(samp, x); x = mul(noiseRot, x * 2.03);

			return noiseVal;
		}

		#define _Cycle _FlowMapParams.x
		#define _CycleRcp _FlowMapParams.y
		#define _HalfCycle _FlowMapParams.z

		void surf (Input IN, inout SurfaceOutputStandard o) {

			half2 uv_FlowMap = mul(_FlowMapMatrix, half4(IN.worldPos, 1)).xy;
			half4 flow = tex2D(_FlowMapTex, uv_FlowMap);
			flow.xy = (flow.xy * 2.0 - 1.0);

			half3 noiseVal = noiseFBM3(_NoiseTex, (IN.worldPos.xz / _TexParams.xx) * 0.125) * 2.0;
			//half offset0 = frac((_Time.y + 0.0) * _CycleRcp) * _Cycle;
			//half offset1 = frac((_Time.y + _HalfCycle) * _CycleRcp) * _Cycle;
			half offset0 = _FlowMapParams.x;
			half offset1 = _FlowMapParams.y;
			offset0 += noiseVal;
			offset1 -= noiseVal;
			half flowLerp = (abs(_HalfCycle - offset0) / _HalfCycle);
			
			half2 uv_Offset0 = flow.xy * offset0 * _TexParams.yy * _NormalMapTex_TexelSize.xy;
			half2 uv_Offset1 = flow.xy * offset1 * _TexParams.yy * _NormalMapTex_TexelSize.xy;

			half2 uv_NormalMap = (IN.worldPos.xz / _TexParams.xx);

			half3 normal0 = UnpackNormal(tex2D(_NormalMapTex, uv_NormalMap + uv_Offset0));
			half3 normal1 = UnpackNormal(tex2D(_NormalMapTex, uv_NormalMap + uv_Offset1));

#if 0
			// Whiteout Blending
			normal0.xy *= 1.0 - flowLerp;
			normal1.xy *= flowLerp;

			normal0 = normalize(normal0);
			normal1 = normalize(normal1);
			o.Normal = normalize(half3(normal0.xy + normal1.xy, normal0.z * normal1.z));
#else
			// Linear Blending
			o.Normal = normalize(lerp(normal0, normal1, flowLerp));
#endif			
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			//o.Albedo = noiseVal;
			
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
