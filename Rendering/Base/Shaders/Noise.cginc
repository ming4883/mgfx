
void noiseOrthoNormalize(inout float3 n, inout float3 t)
{
    n = normalize(n);
    t = t - (n * dot(t, n));
    t = normalize(t);
}

float2 noisePlanarMap(float3 p, float3 n)
{
    float3 absn = abs(n);
    if (absn.x > absn.y)
    {
        if (absn.x > absn.z)
            n = float3(1, 0, 0);
        else
            n = float3(0, 0, 1);
    }
    else
    {
        if (absn.y > absn.z)
            n = float3(0, 1, 0);
        else
            n = float3(0, 0, 1);
    }
    
    float3 s = float3(1,0,0);//normalize(pow(abs(n.yzx), 1.0 / 16.0));
    
    if (abs(dot(s, n)) > 0.99)
    {
        s = s.yzx;
    }

    float3 t = normalize(cross(n, s));
    //noiseOrthoNormalize(n, t);
    float3 b = normalize(cross(t, n));
    t = normalize(cross(n, b));

    // Ax + By + Cz + D = 0 (D = 0)
    float3 pOnPlane = p + dot(p, n) * n;

    return float2(dot(pOnPlane, t), dot(pOnPlane, b));
}

// https://www.shadertoy.com/view/lsf3WH
// Return a [-1, 1] hash value 
float noiseHash2(float2 p)
{
    p  = 50.0*frac( p*0.3183099 + float2(0.71,0.113));
    return -1.0+2.0*frac( p.x*p.y*(p.x+p.y) );
}

// 2d value noise [-1, 1]
float noiseValue2( in float2 p )
{
    float2 i = floor( p );
    float2 f = frac( p );
	
	float2 u = f*f*(3.0-2.0*f);

    return lerp(lerp(noiseHash2( i + float2(0.0,0.0) ), 
                     noiseHash2( i + float2(1.0,0.0) ), u.x),
                lerp(noiseHash2( i + float2(0.0,1.0) ), 
                     noiseHash2( i + float2(1.0,1.0) ), u.x), u.y);
}

float noiseValue2FBM2( in float2 p )
{
    float2x2 noiseRot = float2x2( 1.6,  1.2, -1.2,  1.6 );

    float noiseVal = 0;
    noiseVal += 0.500 * noiseValue2(p); p = mul(noiseRot, p * 2.01);
    noiseVal += 0.500 * noiseValue2(p);

    return noiseVal;
}