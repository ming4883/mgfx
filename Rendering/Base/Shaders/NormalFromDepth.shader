
Shader "Hidden/MGFX.Rendering/NormalFromDepth"
{
	Properties
	{
	}

	CGINCLUDE
	#define UNITY_SHADER_NO_UPGRADE

	#include "UnityCG.cginc"

	uniform sampler2D_float _CameraDepthTexture;
	uniform float4 _CameraDepthTexture_TexelSize;

	// Reconstruct view-space position from UV and depth.
	// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
	// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
	float3 ReconstructViewPosFromDepth(float2 uv, float depth, float2 p11_22, float2 p13_31)
	{
		return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
	}

	float3 ReconstructViewPos(float2 uv, float2 p11_22, float2 p13_31)
	{
		float viewDepth = LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(uv, 0, 0)));
		return ReconstructViewPosFromDepth(uv, viewDepth, p11_22, p13_31);
	}
	
	// Obscurance estimator function
	float3 EstimateViewNormal(float2 uv)
	{
		float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
		float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

		float3 orig = ReconstructViewPos(uv, p11_22, p13_31);
		float3 dirxp = ReconstructViewPos(uv + float2(_CameraDepthTexture_TexelSize.x, 0), p11_22, p13_31);
		float3 diryp = ReconstructViewPos(uv + float2(0, _CameraDepthTexture_TexelSize.y), p11_22, p13_31);

		//float3 dirxn = ReconstructViewPos(uv - r * float2(_CameraDepthTexture_TexelSize.x, 0), p11_22, p13_31);
		//float3 diryn = ReconstructViewPos(uv - r * float2(0, _CameraDepthTexture_TexelSize.y), p11_22, p13_31);
		
		return normalize(cross(dirxp - orig, diryp - orig));
		//return normalize(float3(0, 0, -1));
	}

	// Pass 0: Obscurance estimation
	float4 frag_viewnormal(v2f_img i) : SV_Target
	{
		float3 nrm = EstimateViewNormal(i.uv);
		
		nrm.z *= -1;

		return float4(nrm * 0.5 + 0.5, 0);
	}

	ENDCG

	SubShader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
				#pragma vertex vert_img
				#pragma fragment frag_viewnormal
				#pragma target 3.0
			ENDCG
		}
	}
}
