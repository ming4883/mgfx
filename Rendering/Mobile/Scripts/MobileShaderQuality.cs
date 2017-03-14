using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX.Rendering
{
	public enum MobileShaderQuality
	{
		High = 300,
		Medium = 200,
		Low = 100,
	}

	public class MobileShader
	{
		public static void SetQuality(MobileShaderQuality _quality)
		{
			Shader.globalMaximumLOD = (int)_quality;
		}

		public static bool IsUsingQuality(MobileShaderQuality _quality)
		{
			return Shader.globalMaximumLOD == (int)_quality;
		}
		public static int PID_VertexAnimRotateAxis = Shader.PropertyToID("_VertexAnimRotateAxis");
		public static int PID_VertexAnimRotateAngle = Shader.PropertyToID("_VertexAnimRotateAngle");
	}
}
