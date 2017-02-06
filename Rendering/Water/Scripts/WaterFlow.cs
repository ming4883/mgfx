using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlow")]
	public class WaterFlow : MonoBehaviour
	{
		public struct Sample
		{
			public Vector3 position;
			public Vector3 direction;
		}

		[Range(0, 100)]
		public float delta = 0.125f;

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

		public void GatherSamples(List<Sample> _outList)
		{
			if (points.Length == 0)
				return;

			if (points.Length == 1)
			{
				_outList.Add(new Sample {position = points[0], direction = Vector3.zero});
				return;
			}

			for (int _it = 1; _it < points.Length; _it++)
			{
				var _beg = points[_it - 1];
				var _end = points[_it];
				var _dir = (_end - _beg);
				var _sample = new Sample();
				_sample.direction = _dir.normalized;

				_sample.position = _beg + _sample.direction * delta;
				_outList.Add(_sample);

				_sample.position = _end - _sample.direction * delta;
				_outList.Add(_sample);
			}
		}
	}
}