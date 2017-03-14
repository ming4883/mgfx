
float4 animMakeQuat(float3 axis, float angle)
{ 
  float4 qr;
  float half_angle = angle * (0.5 * 3.14159 / 180.0);
  qr.xyz = axis.xyz * sin(half_angle);
  qr.w = cos(half_angle);
  return qr;
}

float3 animRotatePosition(float3 position, float3 axis, float angle)
{ 
  float4 q = animMakeQuat(axis, angle);
  float3 v = position.xyz;
  return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}
