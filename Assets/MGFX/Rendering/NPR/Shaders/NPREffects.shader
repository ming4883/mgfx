//
// Kino/Obscurance - SSAO (screen-space ambient obscurance) effect for Unity
//
// Copyright (C) 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
Shader "Hidden/MGFX/NPREffects"
{
    Properties
    {
        _MainTex("", 2D) = ""{}
    }
    CGINCLUDE
    #define UNITY_SHADER_NO_UPGRADE

    // --------
    // Additional options for further customization
    // --------

    // By default, a fixed sampling pattern is used in the AO estimator.
    // Although this gives preferable results in most cases, a completely
    // random sampling pattern could give aesthetically good results in some
    // cases. Comment out the line below to use the random pattern instead of
    // the fixed one.
    #define FIX_SAMPLING_PATTERN 1

    // The constant below determines the contrast of occlusion. Altough this
    // allows intentional over/under occlusion, currently is not exposed to the
    // editor, because it is thought to be rarely useful.
    static const float kContrast = 0.6;

    // The constant below controls the geometry-awareness of the blur filter.
    // The higher value, the more sensitive it is.
    static const float kGeometry = 50;

    // The constants below are used in the AO estimator. Beta is mainly used
    // for suppressing self-shadowing noise, and Epsilon is used to prevent
    // calculation underflow. See the paper (Morgan 2011 http://goo.gl/2iz3P)
    // for further details of these constants.
    static const float kBeta = 0.03;
    static const float kEpsilon = 1e-4;

    // --------

    #include "UnityCG.cginc"

    // Source texture type (CameraDepthNormals or G-buffer)
    //#pragma multi_compile _SOURCE_DEPTHNORMALS _SOURCE_GBUFFER

    // Sample count; given-via-uniform (default) or lowest
    #pragma multi_compile _ _SAMPLECOUNT_LOWEST

    #if _SAMPLECOUNT_LOWEST
    static const int _SampleCount = 3;
    #else
    int _SampleCount;
    #endif

    // Global shader properties
    uniform sampler2D _MudGeomTex;
    uniform float4 _MudGeomTex_TexelSize;
    uniform sampler2D_float _CameraDepthTexture;

    uniform sampler2D _MainTex;
    uniform float4 _MainTex_TexelSize;
    uniform float _Flip;

    uniform sampler2D _MudSSAOTex;

    // Material shader properties
    uniform float _OcclusionIntensity;
    uniform float _OcclusionRadius;
    uniform float _OcclusionSelfShadowing;
    uniform float3 _ShadowTraceDir;
    uniform float _EdgeIntensity;
    uniform float _EdgeRadius;
    uniform float _TargetScale;
    uniform float2 _BlurVector;

    // Utility for sin/cos
    float2 CosSin(float theta)
    {
        float sn, cs;
        sincos(theta, sn, cs);
        return float2(cs, sn);
    }

    // Gamma encoding function for AO value
    // (do nothing if in the linear mode)
    half EncodeAO(half x)
    {
        // Gamma encoding
        half x_g = 1 - pow(1 - x, 1 / 2.2);
        // ColorSpaceLuminance.w is 0 (gamma) or 1 (linear).
        return lerp(x_g, x, unity_ColorSpaceLuminance.w);
    }

    // Pseudo random number generator with 2D argument
    float UVRandom(float u, float v)
    {
        float f = dot(float2(12.9898, 78.233), float2(u, v));
        return frac(43758.5453 * sin(f));
    }

    // Interleaved gradient function from Jimenez 2014 http://goo.gl/eomGso
    float GradientNoise(float2 uv)
    {
        uv = floor(uv * _ScreenParams.xy);
        float f = dot(float2(0.06711056f, 0.00583715f), uv);
        return frac(52.9829189f * frac(f));
    }

    // Boundary check for depth sampler
    // (returns a very large value if it lies out of bounds)
    float CheckBounds(float2 uv, float d)
    {
        float ob = any(uv < 0) + any(uv > 1) + (d >= 0.99999);
        return ob * 1e8;
    }

    // Depth/normal sampling functions
    float SampleDepth(float4 uv)
    {
        //float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv.xy);
        //return LinearEyeDepth(d) + CheckBounds(uv.xy, d);
        float d = tex2Dlod(_CameraDepthTexture, uv);
        return LinearEyeDepth(d);
    }

    float3 SampleNormal(float4 uv)
    {
        float3 norm = tex2Dlod(_MudGeomTex, uv).xyz * 2 - 1;
        return norm;
    }

    float SampleDepthNormal(float4 uv, out float3 normal)
    {
        normal = SampleNormal(uv);
        return SampleDepth(uv);
    }

    // Reconstruct view-space position from UV and depth.
    // p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
    // p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
    float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
    {
        return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
    }

    // Normal vector comparer (for geometry-aware weighting)
    half CompareNormal(half3 d1, half3 d2)
    {
        return pow((dot(d1, d2) + 1) * 0.5, kGeometry);
    }

    // Sample point picker
    float3 PickSamplePoint(float2 uv, float index, float radius, int sampleCnt)
    {
        // Uniformaly distributed points on a unit sphere http://goo.gl/X2F1Ho
    #if FIX_SAMPLING_PATTERN
        float gn = GradientNoise(uv * _TargetScale);
        float u = frac(UVRandom(0, index) + gn) * 2 - 1;
        float theta = (UVRandom(1, index) + gn) * UNITY_PI * 2;
    #else
        float u = UVRandom(uv.x + _Time.x, uv.y + index) * 2 - 1;
        float theta = UVRandom(-uv.x - _Time.x, uv.y + index) * UNITY_PI * 2;
    #endif
        float3 v = float3(CosSin(theta) * sqrt(1 - u * u), u);
        // Make them distributed between [0, _OcclusionRadius]
        float l = sqrt((index + 1) / sampleCnt) * radius;
        return v * l;
    }

    struct EstimateState
    {
        int sampleCnt;
        float radius;
        float2 uv_o;
        float3 norm_o;
        float depth_o;
        float3 vpos_o;
        
        float3x3 proj;
        float2 p11_22;
        float2 p13_31;
    };

    int EstimateObscuranceLoop(
        inout float ao, int s_off, EstimateState state)
    {
        int s_beg = s_off;
        int s_end = s_off + state.sampleCnt;
        for (int s = s_beg; s < s_end; s++)
        {
            // Sample point
            float3 v_s1 = PickSamplePoint(state.uv_o, s, state.radius, state.sampleCnt);
            v_s1 = faceforward(v_s1, -state.norm_o, v_s1);
            float3 vpos_s1 = state.vpos_o + v_s1;

            // Reproject the sample point
            float3 spos_s1 = mul(state.proj, vpos_s1);
            float2 uv_s1 = (spos_s1.xy / vpos_s1.z + 1) * 0.5;

            // Depth at the sample point
            float depth_s1 = SampleDepth(float4(uv_s1, 0, 0));

            // Relative position of the sample point
            float3 vpos_s2 = ReconstructViewPos(uv_s1, depth_s1, state.p11_22, state.p13_31);
            float3 v_s2 = vpos_s2 - state.vpos_o;

            // Estimate the obscurance value
            float a1 = max(dot(v_s2, state.norm_o) - kBeta * state.depth_o, 0);
            float a2 = dot(v_s2, v_s2) + kEpsilon;
            ao += a1 / a2;
        }

        return state.sampleCnt;
    }

    // Obscurance estimator function
    float EstimateObscurance(float2 uv)
    {
        EstimateState state;

        state.uv_o = uv;
        state.sampleCnt = _SampleCount;

        // Parameters used in coordinate conversion
        state.proj = (float3x3)unity_CameraProjection;
        state.p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
        state.p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
        
        // View space normal and depth
        state.depth_o = SampleDepthNormal(float4(state.uv_o, 0, 0), state.norm_o);

        // Reconstruct the view-space position.
        state.vpos_o = ReconstructViewPos(state.uv_o, state.depth_o, state.p11_22, state.p13_31);

        // Distance-based AO estimator based on Morgan 2011 http://goo.gl/2iz3P
        float ao = 0.0;
        float ao_norm = 0.0;

        state.radius = _OcclusionRadius;
        
        ao_norm += EstimateObscuranceLoop(ao, 0, state);

        state.radius = _OcclusionRadius * 0.5;
        if (state.depth_o < 0.5 * _ProjectionParams.z)
            ao_norm += EstimateObscuranceLoop(ao, state.sampleCnt, state);

        state.radius = _OcclusionRadius * 0.25;
        if (state.depth_o < 0.25 * _ProjectionParams.z)
            ao_norm += EstimateObscuranceLoop(ao, state.sampleCnt * 2, state);

        state.radius = _OcclusionRadius * 0.125;
        if (state.depth_o < 0.125 * _ProjectionParams.z)
            ao_norm += EstimateObscuranceLoop(ao, state.sampleCnt * 3, state);

        // intensity normalization
        ao *= _OcclusionRadius;

        // Apply other parameters.
        return pow(ao * _OcclusionIntensity / ao_norm, kContrast);
    }


    // Sample point picker
    float3 PickSamplePointShadow(float2 uv, float index, float radius, int sampleCnt)
    {
        // Uniformaly distributed points on a unit sphere http://goo.gl/X2F1Ho
#if FIX_SAMPLING_PATTERN
        float gn = GradientNoise(uv * _TargetScale);
        float u = frac(UVRandom(0, index) + gn) * 2 - 1;
#else
        float u = UVRandom(uv.x + _Time.x, uv.y + index) * 2 - 1;
#endif
        float3 v = _ShadowTraceDir * radius * (index + u);
        return v;
    }

    int EstimateShadowLoop(
        inout float ao, int s_off, EstimateState state)
    {
        int s_beg = s_off;
        int s_end = s_off + state.sampleCnt;
        float beta = _OcclusionSelfShadowing * max(1e-3, 1.0 / (state.depth_o * 2));
        
        for (int s = s_beg; s < s_end; s++)
        {
            // Sample point
            float3 v_s1 = PickSamplePointShadow(state.uv_o, s, state.radius, state.sampleCnt); 
            float3 vpos_s1 = state.vpos_o + v_s1;

            // Reproject the sample point
            float3 spos_s1 = mul(state.proj, vpos_s1);
            float2 uv_s1 = (spos_s1.xy / vpos_s1.z + 1) * 0.5;

            // Depth at the sample point
            float depth_s1 = SampleDepth(float4(uv_s1, 0, 0));

            // Relative position of the sample point
            float3 vpos_s2 = ReconstructViewPos(uv_s1, depth_s1, state.p11_22, state.p13_31);
            float3 v_s2 = vpos_s2 - state.vpos_o;

            // Estimate the obscurance value
            float a1 = max(dot(v_s2, state.norm_o) - beta * state.depth_o, 0);
            float a2 = dot(v_s2, v_s2) + kEpsilon;
            ao += a1 / a2;
        }

        return state.sampleCnt;
    }

    // Obscurance estimator function
    float EstimateShadow(float2 uv)
    {
        EstimateState state;

        state.uv_o = uv;
        state.sampleCnt = _SampleCount;

        // Parameters used in coordinate conversion
        state.proj = (float3x3)unity_CameraProjection;
        state.p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
        state.p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

        // View space normal and depth
        state.depth_o = SampleDepthNormal(float4(state.uv_o, 0, 0), state.norm_o);

        // Reconstruct the view-space position.
        state.vpos_o = ReconstructViewPos(state.uv_o, state.depth_o, state.p11_22, state.p13_31);

        // Distance-based AO estimator based on Morgan 2011 http://goo.gl/2iz3P
        float ao = 0.0;
        float ao_norm = 0.0;

        state.radius = _OcclusionRadius / (float)_SampleCount;
        ao_norm += EstimateShadowLoop(ao, 0, state);

        // intensity normalization
        ao *= _OcclusionRadius;

        // Apply other parameters.
        return pow(ao * _OcclusionIntensity / ao_norm, kContrast);
    }

    int EstimateEdgeLoop(
        inout float2 edge, int s_off, EstimateState state)
    {
        int s_beg = s_off;
        int s_end = s_off + state.sampleCnt;

        float3 vnrm_avg = 0;
        //float3 vpos_avg = 0;
        float vdep_avg = 0;

        for (int s = s_beg; s < s_end; s++)
        {
            // Sample point
            float3 v_s1 = PickSamplePoint(state.uv_o, s, state.radius, state.sampleCnt);
            v_s1 = faceforward(v_s1, -state.norm_o, v_s1);
            float3 vpos_s1 = state.vpos_o + v_s1;

            // Reproject the sample point
            float3 spos_s1 = mul(state.proj, vpos_s1);
            float2 uv_s1 = (spos_s1.xy / vpos_s1.z + 1) * 0.5;

            // Depth at the sample point
            float3 normal_s1;
            float depth_s1 = SampleDepthNormal(float4(uv_s1, 0, 0), normal_s1);

            // Relative position of the sample point
            //float3 vpos_s2 = ReconstructViewPos(uv_s1, depth_s1, state.p11_22, state.p13_31);

            vnrm_avg += normal_s1;
            //vpos_avg += vpos_s2;
            vdep_avg += depth_s1;
        }

        vnrm_avg /= state.sampleCnt;
        //vpos_avg /= state.sampleCnt;
        vdep_avg /= state.sampleCnt;

        // average with center tap
        vnrm_avg = (vnrm_avg + state.norm_o) * 0.5;
        //vpos_avg = (vpos_avg + state.vpos_o) * 0.5;
        vdep_avg = (vdep_avg + state.depth_o) * 0.5;

        // subtract by the center tap
        vnrm_avg -= state.norm_o;
		//vpos_avg -= state.vpos_o;
		vdep_avg -= state.depth_o;

		edge = 0;
		edge.x = max(0, dot(vnrm_avg, vnrm_avg) * 8.0);
		//edge.y = max(0, dot(vpos_avg, vpos_avg) - 3.0f);
		edge.y = max(0, vdep_avg - state.depth_o);

        return state.sampleCnt;
    }

    float2 EstimateEdge(float2 uv)
    {
    	EstimateState state;

        state.uv_o = uv;
        state.sampleCnt = 16;

        // Parameters used in coordinate conversion
        state.proj = (float3x3)unity_CameraProjection;
        state.p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
        state.p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);
        
        // View space normal and depth
        state.depth_o = SampleDepthNormal(float4(state.uv_o, 0, 0), state.norm_o);

        // Reconstruct the view-space position.
        state.vpos_o = ReconstructViewPos(state.uv_o, state.depth_o, state.p11_22, state.p13_31);

        float2 edge0 = 0.0;
        float2 edge1 = 0.0;
        float edge_norm = 0.0;
        float w = saturate(max(0, state.depth_o - 2) / 20);

        state.radius = _EdgeRadius * 0.5 + _EdgeRadius * 0.5 * w;
        edge_norm += EstimateEdgeLoop(edge0, 0, state);

        edge0 *= (1 - w);

        //state.radius = _EdgeRadius * w;
        //edge_norm += EstimateEdgeLoop(edge1, state.sampleCnt * 2, state);
        //edge1 *= 0;
        return (edge0 + edge1);
    }

    // Geometry-aware separable blur filter
    half4 SeparableBlur(sampler2D tex, float2 uv, float2 delta)
    {
        half3 n0 = SampleNormal(half4(uv, 0, 0));

        half4 uv1 = half4(uv - delta, 0, 0);
        half4 uv2 = half4(uv + delta, 0, 0);
        half4 uv3 = half4(uv - delta * 2, 0, 0);
        half4 uv4 = half4(uv + delta * 2, 0, 0);

        half w0 = 3;
        half w1 = CompareNormal(n0, SampleNormal(uv1)) * 2;
        half w2 = CompareNormal(n0, SampleNormal(uv2)) * 2;
        half w3 = CompareNormal(n0, SampleNormal(uv3));
        half w4 = CompareNormal(n0, SampleNormal(uv4));

        half4 s = tex2Dlod(tex, half4(uv, 0, 0));
        half4 o = s;
        s *= w0;
        s += tex2Dlod(tex, uv1) * w1;
        s += tex2Dlod(tex, uv2) * w2;
        s += tex2Dlod(tex, uv3) * w3;
        s += tex2Dlod(tex, uv4) * w4;
        s = s / (w0 + w1 + w2 + w3 + w4);
        return half4(s.r, o.gba);
    }

    // Pass 0: Obscurance estimation
    half4 frag_ao(v2f_img i) : SV_Target
    {
    	float ao = EstimateShadow(i.uv);
    	float2 edge0 = EstimateEdge(i.uv + _MudGeomTex_TexelSize.xy * float2(0.0, 0.0));
    	float2 edge1 = EstimateEdge(i.uv + _MudGeomTex_TexelSize.xy * float2(0.0, 0.5));
    	float2 edge2 = EstimateEdge(i.uv + _MudGeomTex_TexelSize.xy * float2(0.5, 0.0));
    	float2 edge3 = EstimateEdge(i.uv + _MudGeomTex_TexelSize.xy * float2(0.5, 0.5));
    	float2 edge = saturate((edge0 + edge1 + edge2 + edge3) * 0.25);
    	return half4(ao, edge, 0);
    }

    // Pass1: Geometry-aware separable blur
    half4 frag_blur(v2f_img i) : SV_Target
    {
        //float2 delta = _MainTex_TexelSize.xy * _BlurVector;
        float2 delta = _BlurVector;
        return SeparableBlur(_MainTex, i.uv, delta);
    }

    struct v2f_aa {
        float4 pos : SV_POSITION;
        float2 uv[5] : TEXCOORD0;
    };

    v2f_aa vert_aa( appdata_img v ) {
        v2f_aa o;
        o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
        
        float2 uv = v.texcoord.xy;
        
        float w = 1.75;
                
        float2 up = float2(0.0, _MainTex_TexelSize.y) * w;
        float2 right = float2(_MainTex_TexelSize.x, 0.0) * w;	
            
        o.uv[0].xy = uv - up;
        o.uv[1].xy = uv - right;
        o.uv[2].xy = uv + right;
        o.uv[3].xy = uv + up;

        o.uv[4].xy = uv;
        
        return o;
    }

    half4 frag_aa (v2f_aa f) : SV_Target
    {		 	 
        half4 outColor = 0;
        
        float4 t = tex2D( _MainTex, f.uv[0] );
        float4 l = tex2D( _MainTex, f.uv[1] );
        float4 r = tex2D( _MainTex, f.uv[2] );
        float4 b = tex2D( _MainTex, f.uv[3] );
        float4 o = tex2D( _MainTex, f.uv[4] );

        for (int i = 0; i < 4; ++i)
        {
	        half2 n = half2( -( t[i] - b[i] ), r[i] - l[i] );
	        float nl = length( n );
	     
	        if ( nl < (1.0 / 16.0) )
	        {
	            outColor[i] = o[i];
	        }
	        else
	        {
	            n *= _MainTex_TexelSize.xy / nl;

	            half4 t0 = tex2D( _MainTex, f.uv[4] + n * 0.5) * 0.9;
	            half4 t1 = tex2D( _MainTex, f.uv[4] - n * 0.5) * 0.9;
	            half4 t2 = tex2D( _MainTex, f.uv[4] + n) * 0.75;
	            half4 t3 = tex2D( _MainTex, f.uv[4] - n) * 0.75;
	     
	            outColor[i] = saturate((o + t0 + t1 + t2 + t3) / 4.3)[i];
	        }
	    }

        return outColor;
    }

    // Pass 2: Combiner for the forward mode
    struct v2f_multitex
    {
        float4 pos : SV_POSITION;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
    };

    v2f_multitex vert_multitex(appdata_img v)
    {
        // Handles vertically-flipped case.
        //float vflip = sign(_MainTex_TexelSize.y);

        v2f_multitex o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv0 = v.texcoord.xy;
        o.uv1 = (v.texcoord.xy - 0.5) * float2(1, _Flip) + 0.5;
        return o;
    }

    half4 frag_combine(v2f_multitex i) : SV_Target
    {
        half2 edge = tex2D(_MudSSAOTex, i.uv0).gb;
        edge = edge * edge * 9.0;

        half4 src = tex2D(_MainTex, i.uv1);
        src = src * src * 0.125;
        half isedge = saturate(dot(edge, 1.0));

        return half4(src.rgb, isedge * _EdgeIntensity);
        //return half4(edge, 0, 0.5);
    }


    ENDCG

    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_ao
            #pragma target 3.0
            ENDCG
        }

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_blur
            #pragma target 3.0
            ENDCG
        }

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_aa
            #pragma fragment frag_aa
            #pragma target 3.0
            ENDCG
        }

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert_multitex
            #pragma fragment frag_combine
            #pragma target 3.0
            ENDCG
        }
    }
}
