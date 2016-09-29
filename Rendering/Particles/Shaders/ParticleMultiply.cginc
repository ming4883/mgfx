fixed4 frag(v2f i) : SV_Target
{
#ifdef SOFTPARTICLES_ON
#if _SOFT_PARTICLE_SUPPORT
    float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
    float partZ = i.projPos.z;
    float fade = saturate(_InvFade * (sceneZ - partZ));
    i.color.a *= fade;
#endif
#endif

    half4 prev = i.color * tex2D(_MainTex, i.texcoord);
    fixed4 col = lerp(half4(1,1,1,1), prev, prev.a);
    UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(1,1,1,1)); // fog towards white due to our blend mode
    return col;
}