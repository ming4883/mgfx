using UnityEngine;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlow")]
	public class WaterFlow : MonoBehaviour
	{
		public Vector3[] points = new Vector3[] {
			new Vector3(0, 0, 0),
			new Vector3(0, 0, 1),
		};

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
			int _numOfPts = points.Length;

			if (_numOfPts < 2)
				return;

			Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
			Gizmos.color = m_LineColor;

			for (int _it = 1; _it < _numOfPts; _it++)
			{
				var _beg = points[_it - 1];
				var _end = points[_it];
				Gizmos.DrawLine(_beg, _end);
			}
		}

		public void OnDrawGizmosSelected()
		{
		}

		public void SetupTransform(Vector3 _beg, Vector3 _end)
		{
			transform.localScale = new Vector3(1, 1, 1);
			transform.position = _beg;
			transform.LookAt(_end);
		}
	}
}