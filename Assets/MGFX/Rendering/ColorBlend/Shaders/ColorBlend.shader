Shader "Hidden/MGFXerse/ColorBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        _BlendColor ("BlendColor", Color) = (0, 0, 0, 0.5)
    }
	
	CGINCLUDE
	#include "UnityCG.cginc"

	struct v2f
	{
		float4 vertex : SV_POSITION;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	uniform sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	uniform float4 _BlendColor;
	uniform float _Flip;

	v2f vert (appdata_img v)
	{
		//float vflip = sign(_MainTex_TexelSize.y);

		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv0 = v.texcoord.xy;
		o.uv1 = (v.texcoord.xy - 0.5) * float2(1, _Flip) + 0.5;
		return o;
	}
	
	half4 frag_lerp (v2f i) : SV_Target
	{
		half4 c = tex2D(_MainTex, i.uv1);
		
		c.rgb = lerp(c.rgb, _BlendColor.rgb, _BlendColor.a);
		
		return c;
	}
	
	half4 frag_add (v2f i) : SV_Target
	{
		half4 c = tex2D(_MainTex, i.uv1);
		
		c.rgb = c.rgb + (_BlendColor.rgb * _BlendColor.a);
		
		return c;
	}

	half4 frag_sub (v2f i) : SV_Target
	{
		half4 c = tex2D(_MainTex, i.uv1);
		
		c.rgb = c.rgb - (_BlendColor.rgb * _BlendColor.a);
		
		return c;
	}


	half4 frag_revsub (v2f i) : SV_Target
	{
		half4 c = tex2D(_MainTex, i.uv1);
		
		c.rgb = (_BlendColor.rgb * _BlendColor.a) - c.rgb;
		
		return c;
	}

	half4 frag_mult (v2f i) : SV_Target
	{
		half4 c = tex2D(_MainTex, i.uv1);
		
		c.rgb = c.rgb * (_BlendColor.rgb * _BlendColor.a);
		
		return c;
	}

	ENDCG
	
    SubShader
    {        
        Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_lerp
            ENDCG
        }
		
		Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_add
            ENDCG
        }

        Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_sub
            ENDCG
        }


        Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_revsub
            ENDCG
        }

        Pass
        {
			Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_mult
            ENDCG
        }
    }
}
