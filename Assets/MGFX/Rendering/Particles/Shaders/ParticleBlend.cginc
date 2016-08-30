fixed4 frag(v2f i) : SV_Target
{
#ifdef SOFTPARTICLES_ON
#if _SOFT_PARTICLE_SUPPORT
    float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
    float partZ = i.projPos.z;
    float fade = saturate(_InvFade * (sceneZ - partZ));
    i.color *= fade;
#endif
#endif

    fixed4 col = i.color * tex2D(_MainTex, i.texcoord);
    UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0)); // fog towards black due to our blend mode
    return col;
}