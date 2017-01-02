#include "UnityCG.cginc"

#if UNITY_VERSION < 540
#define UNITY_SHADER_NO_UPGRADE
#define unity_ObjectToWorld _Object2World 
#define unity_WorldToObject _World2Object
#define unity_WorldToLight _LightMatrix0
#define unity_WorldToCamera _WorldToCamera
#define unity_CameraToWorld _CameraToWorld
#define unity_Projector _Projector
#define unity_ProjectorDistance _ProjectorDistance
#define unity_ProjectorClip _ProjectorClip
#define unity_GUIClipTextureMatrix _GUIClipTextureMatrix 
#endif


#define SHADING_QUALITY_LOW		0
#define SHADING_QUALITY_MEDIUM	1
#define SHADING_QUALITY_HIGH	2
