#include "Lighting.cginc"
#include "AutoLight.cginc"

#ifdef POINT
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
	fixed destName = (tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL);
#endif

#ifdef SPOT
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)); \
	fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif

#ifdef DIRECTIONAL
	#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos)	fixed destName = 1;
#endif


#ifdef POINT_COOKIE
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
	fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w;
#endif

#ifdef DIRECTIONAL_COOKIE
#define MGFX_LIGHT_ATTENUATION(destName, input, worldPos) \
	unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy; \
	fixed destName = tex2D(_LightTexture0, lightCoord).w;
#endif

// global
uniform float3 _MGFXAutoLightDir;


half3 autoLightDir()
{
    half3 camRight = UNITY_MATRIX_V[0].xyz;
    half3 camUp = UNITY_MATRIX_V[1].xyz;
    half3 camFwd = UNITY_MATRIX_V[2].xyz;
    
    return normalize(_MGFXAutoLightDir.x * camRight + _MGFXAutoLightDir.y * camUp + _MGFXAutoLightDir.z * camFwd);
}