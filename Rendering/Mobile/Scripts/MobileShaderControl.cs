using UnityEngine;

namespace MGFX.Rendering
{
	public enum MobileShaderQuality
	{
		High = 300,
		Medium = 200,
		Low = 100,
		DebugVertexAlpha = 30,
		DebugReflection = 20,
		DebugLighting = 10,
	}

	public class MobileShaderContol : MonoBehaviour
	{
		private MaterialPropertyBlock m_MatProps = new MaterialPropertyBlock();

		public Renderer[] m_Renderers = new Renderer[]{};
		
		public bool m_PauseAnimTime = false;

		private Vector4 m_AnimTime = Vector4.zero;

		public void Start()
		{
			foreach(Renderer _rend in m_Renderers)
			{
				_rend.SetPropertyBlock(m_MatProps);
			}

			m_AnimTime = Vector4.zero;
		}

		public void Update()
		{
			if (!m_PauseAnimTime)
			{
				m_AnimTime.y += Time.smoothDeltaTime;
			}

			m_MatProps.SetVector(PID_VertexAnimTime, m_AnimTime);
		}

		public static void SetQuality(MobileShaderQuality _quality)
		{
			Shader.globalMaximumLOD = (int)_quality;
		}

		public static bool IsUsingQuality(MobileShaderQuality _quality)
		{
			return Shader.globalMaximumLOD == (int)_quality;
		}

		public static int PID_VertexAnimRotateAxis = Shader.PropertyToID("_VertexAnimRotateAxis");
		public static int PID_VertexAnimTime = Shader.PropertyToID("_VertexAnimTime");
	}
}
