
half2 matCapUV(half3 worldNormal, half3 worldViewDir)
{
	half3 rx = half3(1, 0, 0);
	half3 ry = half3(0, 1, 0);
	half3 rz = UNITY_MATRIX_V[2].xyz;

	rx = cross(ry, rz);
	ry = cross(rz, rx);

	half3x3 m;
	m[0] = rx;
	m[1] = -ry;
	m[2] = rz;

	half2 uv;
	#if _MATCAP_PLANAR_ON
	{
		half3 dir = reflect(worldViewDir, worldNormal);
		dir = normalize(mul(m, dir));
		uv = saturate(dir.xy * 0.5 + 0.5);
	}
	#else
	{
		half3 viewNormal = mul(m, worldNormal);
		uv = saturate(viewNormal.xy * 0.5 + 0.5);
	}
	#endif

	return uv;
}
