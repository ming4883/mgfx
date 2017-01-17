
Shader "Hidden/MGFX/HDR" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	
	CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;

		uniform half4 _OffsetsA;
		uniform half4 _OffsetsB;
		
		#define ONE_MINUS_THRESHHOLD_TIMES_INTENSITY _BloomParameter.w
		#define THRESHHOLD _BloomParameter.z

		struct v2f_tap
		{
			float4 pos : SV_POSITION;
			half2 uv20 : TEXCOORD0;
			half2 uv21 : TEXCOORD1;
			half2 uv22 : TEXCOORD2;
			half2 uv23 : TEXCOORD3;
		};			

		v2f_tap vertDownsample ( appdata_img v )
		{
			v2f_tap o;

			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv20 = v.texcoord + _MainTex_TexelSize.xy;
			o.uv21 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h,-0.5h);
			o.uv22 = v.texcoord + _MainTex_TexelSize.xy * half2(0.5h,-0.5h);
			o.uv23 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h,0.5h);

			return o; 
		}

		#include "./HDR.cginc"

		half4 fragHDR ( v2f_hdr i ) : SV_Target
		{	
			return fragHDRBase( i );
		}
		
		half4 fragDownsample ( v2f_tap i ) : SV_Target
		{
			half4 color = tex2D (_MainTex, i.uv20);
			color += tex2D (_MainTex, i.uv21);
			color += tex2D (_MainTex, i.uv22);
			color += tex2D (_MainTex, i.uv23);
			color = color * 0.25;

			return half4(max(color - THRESHHOLD, 0).rgb * ONE_MINUS_THRESHHOLD_TIMES_INTENSITY, Luminance(color));
		}

		half4 fragWhitePoint(v2f_hdr i) : SV_Target
		{
			half4 wp = tex2D(_MainTex, half2(0.5, 0.5));
			wp += tex2D(_MainTex, half2(0.25, 0.25));
			wp += tex2D(_MainTex, half2(0.75, 0.25));
			wp += tex2D(_MainTex, half2(0.25, 0.75));
			wp += tex2D(_MainTex, half2(0.75, 0.75));

			return half4(wp.aaa * 0.2, _ToneMappingParameter.z);
		}

		// weight curves
		static const half curve[7] = { 0.0205, 0.0855, 0.232, 0.324, 0.232, 0.0855, 0.0205 };  // gauss'ish blur weights

		static const half4 curve4[7] = { 
			half4(0.0205,0.0205,0.0205,0.0205), 
			half4(0.0855,0.0855,0.0855,0.0855), 
			half4(0.232,0.232,0.232,0.232),
			half4(0.324,0.324,0.324,0.324), 
			half4(0.232,0.232,0.232,0.232), 
			half4(0.0855,0.0855,0.0855,0.0855),
			half4(0.0205,0.0205,0.0205,0.0205) 
		};

		struct v2f_withBlurCoords8 
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
			half2 offs : TEXCOORD1;
		};	
		
		struct v2f_withBlurCoordsSGX 
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half4 offs[3] : TEXCOORD1;
		};

		v2f_withBlurCoords8 vertBlurHorizontal (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _BloomParameter.x;

			return o; 
		}
		
		v2f_withBlurCoords8 vertBlurVertical (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _BloomParameter.x;
			 
			return o; 
		}

		half4 fragBlur8 ( v2f_withBlurCoords8 i ) : SV_Target
		{
			half2 uv = i.uv.xy; 
			half2 netFilterWidth = i.offs;  
			half2 coords = uv - netFilterWidth * 3.0;  
			
			half4 color = 0;
			for( int l = 0; l < 7; l++ )  
			{   
				half4 tap = tex2D(_MainTex, coords);
				color += tap * curve4[l];
				coords += netFilterWidth;
			}
			return color;
		}

		v2f_withBlurCoordsSGX vertBlurHorizontalSGX (appdata_img v)
		{
			v2f_withBlurCoordsSGX o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = v.texcoord.xy;

			half offsetMagnitude = _MainTex_TexelSize.x * _BloomParameter.x;
			o.offs[0] = v.texcoord.xyxy + offsetMagnitude * half4(-3.0h, 0.0h, 3.0h, 0.0h);
			o.offs[1] = v.texcoord.xyxy + offsetMagnitude * half4(-2.0h, 0.0h, 2.0h, 0.0h);
			o.offs[2] = v.texcoord.xyxy + offsetMagnitude * half4(-1.0h, 0.0h, 1.0h, 0.0h);

			return o; 
		}		
		
		v2f_withBlurCoordsSGX vertBlurVerticalSGX (appdata_img v)
		{
			v2f_withBlurCoordsSGX o;
			o.pos = UnityObjectToClipPos (v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);

			half offsetMagnitude = _MainTex_TexelSize.y * _BloomParameter.x;
			o.offs[0] = v.texcoord.xyxy + offsetMagnitude * half4(0.0h, -3.0h, 0.0h, 3.0h);
			o.offs[1] = v.texcoord.xyxy + offsetMagnitude * half4(0.0h, -2.0h, 0.0h, 2.0h);
			o.offs[2] = v.texcoord.xyxy + offsetMagnitude * half4(0.0h, -1.0h, 0.0h, 1.0h);

			return o; 
		}	

		half4 fragBlurSGX ( v2f_withBlurCoordsSGX i ) : SV_Target
		{
			half2 uv = i.uv.xy;
			
			half4 color = tex2D(_MainTex, i.uv) * curve4[3];
			
			for( int l = 0; l < 3; l++ )  
			{   
				half4 tapA = tex2D(_MainTex, i.offs[l].xy);
				half4 tapB = tex2D(_MainTex, i.offs[l].zw); 
				color += (tapA + tapB) * curve4[l];
			}

			return color;

		}

	ENDCG
	
	SubShader {
	  
	// 0
	Pass {
		ZTest Always Cull Off ZWrite Off

		CGPROGRAM
		#pragma vertex vertHDR
		#pragma fragment fragHDR
		
		ENDCG
		 
		}

	// 1
	Pass { 
		ZTest Always Cull Off ZWrite Off

		CGPROGRAM
		
		#pragma vertex vertDownsample
		#pragma fragment fragDownsample
		
		ENDCG
		 
		}

	// 2
	Pass{
		ZTest Always Cull Off ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM

		#pragma vertex vertHDR
		#pragma fragment fragWhitePoint

		ENDCG

	}

	// 3
	Pass {
		ZTest Always Cull Off ZWrite Off
		
		CGPROGRAM 
		
		#pragma vertex vertBlurVertical
		#pragma fragment fragBlur8
		
		ENDCG 
		}	
		
	// 4	
	Pass {
		ZTest Always Cull Off ZWrite Off
				
		CGPROGRAM
		
		#pragma vertex vertBlurHorizontal
		#pragma fragment fragBlur8
		
		ENDCG
		}	

	// alternate blur
	// 5
	Pass {
		ZTest Always Cull Off ZWrite Off

		CGPROGRAM 
		
		#pragma vertex vertBlurVerticalSGX
		#pragma fragment fragBlurSGX
		
		ENDCG
		}	
		
	// 6
	Pass {		
		ZTest Always Cull Off ZWrite Off

		CGPROGRAM
		
		#pragma vertex vertBlurHorizontalSGX
		#pragma fragment fragBlurSGX
		
		ENDCG
		}	
	}

	FallBack Off
}
