float2 OctWrap (float2 v) {
    return (1.0 - abs (v.yx)) * sign (v.xy);
}
 
float2 OctEncode (float3 n) {
    //float2 encN = n / (abs (n.x) + abs (n.y) + abs (n.z));
    float2 encN = n / dot (float3 (1.0, 1.0, 1.0), abs (n));
    encN.xy = n.z >= 0.0 ? encN.xy : OctWrap (encN.xy);
    encN.xy = encN.xy * 0.5 + 0.5;
    return encN.xy;
}
 
float3 OctDecode (float2 encN) {
    encN = encN * 2.0 - 1.0;
 
    float3 n;
    n.z = 1.0 - abs (encN.x) - abs (encN.y);
    n.xy = n.z >= 0.0 ? encN.xy : OctWrap (encN.xy);
    n = normalize (n);
    return n;
}