Shader "Hidden/MGFX/VertexColorDisplay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        //Blend SrcAlpha OneMinusSrcAlpha
		
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
        uniform float _Flip;

        v2f vert (appdata_img v)
        {
            //float vflip = sign(_MainTex_TexelSize.y);

            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv0 = v.texcoord.xy;
            o.uv1 = (v.texcoord.xy - 0.5) * float2(1, _Flip) + 0.5;
            return o;
        }
        
        half4 fragRGB (v2f i) : SV_Target
        {
			return float4(tex2D(_MainTex, i.uv0).rgb, 1);
        }
		
		half4 fragAlpha (v2f i) : SV_Target
        {
			return float4(tex2D(_MainTex, i.uv0).aaa, 1);
        }
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            
            ENDCG
        }
		
		Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragAlpha
            
            ENDCG
        }
    }
}
