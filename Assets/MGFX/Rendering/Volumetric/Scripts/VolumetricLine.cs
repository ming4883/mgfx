using UnityEngine;
using System.Collections.Generic;


namespace MGFX
{
	[ExecuteInEditMode]
	public class VolumetricLine : MonoBehaviour
	{
		public float m_Radius = 0.25f;
		public Vector3 m_BegPt = new Vector3(0, 1, 0);
		public Vector3 m_EndPt = new Vector3(0, -1, 0);
		public Color m_Color = Color.white;
		public float m_Intensity = 1.0f;

		public void OnEnable ()
		{
			VolumetricLineSystem.instance.Add(this);
		}

		public void Start ()
		{
			VolumetricLineSystem.instance.Add(this);
		}

		public void OnDisable ()
		{
			VolumetricLineSystem.instance.Remove(this);
		}

		public Color GetLinearColor ()
		{
			return new Color(
				Mathf.GammaToLinearSpace(m_Color.r * m_Intensity),
				Mathf.GammaToLinearSpace(m_Color.g * m_Intensity),
				Mathf.GammaToLinearSpace(m_Color.b * m_Intensity),
				1.0f
			);
		}

		public void OnDrawGizmos ()
		{
			Gizmos.DrawLine(m_BegPt, m_EndPt);
		}
	}


	public class VolumetricLineSystem
	{
		static VolumetricLineSystem m_Instance;

		static public VolumetricLineSystem instance {
			get
			{
				if(m_Instance == null)
					m_Instance = new VolumetricLineSystem();
				return m_Instance;
			}
		}

		internal HashSet<VolumetricLine> m_Lines = new HashSet<VolumetricLine>();

		public void Add (VolumetricLine o)
		{
			Remove(o);
			m_Lines.Add(o);
		}

		public void Remove (VolumetricLine o)
		{
			m_Lines.Remove(o);
		}
	}
}