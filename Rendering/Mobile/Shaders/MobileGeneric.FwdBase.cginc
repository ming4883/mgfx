#pragma multi_compile_fwdbase LIGHTMAP_OFF DYNAMICLIGHTMAP_OFF
#pragma skip_variants SHADOWS_SOFT

#pragma shader_feature _REALTIME_LIGHTING_ON
#pragma shader_feature _REFLECTION_PROBES_ON
#pragma shader_feature _GI_IRRADIANCE_ON
#pragma shader_feature _NORMAL_MAP_ON
#pragma shader_feature _DIFFUSE_LUT_ON
#pragma shader_feature _MATCAP_ON
#pragma shader_feature _MATCAP_PLANAR_ON
#pragma shader_feature _MATCAP_ALBEDO_ON

#pragma vertex vert
#pragma fragment frag_base