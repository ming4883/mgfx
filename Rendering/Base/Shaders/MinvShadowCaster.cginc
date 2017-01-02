#pragma vertex vert_shadowcaster
#pragma fragment frag_shadowcaster
#pragma target 2.0
#pragma multi_compile_shadowcaster
#include "UnityCG.cginc"

struct v2f_shadowcaster { 
	V2F_SHADOW_CASTER;
};

v2f_shadowcaster vert_shadowcaster( appdata_base v )
{
	v2f_shadowcaster o;
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}

float4 frag_shadowcaster( v2f_shadowcaster i ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}