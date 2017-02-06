using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlowMap")]
	public class WaterFlowMap : MonoBehaviour
	{
		public WaterFlow[] flows = new WaterFlow[] {
			null
		};

		public Vector2 size = new Vector2(10, 10);
		public Vector2 resolution = new Vector2(512, 512);

		public void OnEnable()
		{
		}

		public void Start()
		{
		}

		public void OnDisable()
		{
		}

		private static Color m_LineColor = new Color(0.25f, 1.0f, 1.0f, 0.5f);

		public void OnDrawGizmos()
		{
			Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
			Gizmos.color = m_LineColor;

			Vector2 _halfSize = size * 0.5f;

			Gizmos.DrawLine(new Vector3( _halfSize.x, 0, _halfSize.y), new Vector3(-_halfSize.x, 0, _halfSize.y));
			Gizmos.DrawLine(new Vector3(-_halfSize.x, 0, _halfSize.y), new Vector3(-_halfSize.x, 0,-_halfSize.y));
			Gizmos.DrawLine(new Vector3(-_halfSize.x, 0,-_halfSize.y), new Vector3( _halfSize.x, 0,-_halfSize.y));
			Gizmos.DrawLine(new Vector3( _halfSize.x, 0,-_halfSize.y), new Vector3( _halfSize.x, 0, _halfSize.y));
		}

		public List<WaterFlow.Sample> GatherSamples()
		{
			List<WaterFlow.Sample> _samples = new List<WaterFlow.Sample>();

			foreach (var _flow in flows)
			{
				if (null == _flow || !_flow)
					continue;
				
				_flow.GatherSamples(_samples);
			}

			return _samples;	
		}
	}
}