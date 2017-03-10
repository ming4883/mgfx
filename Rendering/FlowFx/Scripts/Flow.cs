using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/Flow")]
	public class Flow : MonoBehaviour
	{
		public struct Sample
		{
			public Vector3 position;
			public Vector3 direction;
		}

		[Range(0, 1)]
		public float strength = 1;

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

		public void GatherSamples(List<Sample> _outList, Vector2 _sampleSize)
		{
			float _delta = Mathf.Min(_sampleSize.x, _sampleSize.y);

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

				_beg = transform.TransformPoint(_beg);
				_end = transform.TransformPoint(_end);

				var _dir = (_end - _beg).normalized * strength;
				var _sample = new Sample();
				_sample.direction = _dir;

				_sample.position = _beg;
				_outList.Add(_sample);

				_sample.position = _end;
				_outList.Add(_sample);

				GatherSamples(_outList, _beg, _end, _dir, _delta * _delta);
			}
		}

		private void GatherSamples(List<Sample> _outList, Vector3 _beg, Vector3 _end, Vector3 _dir, float _maxSqrDist)
		{
			Vector3 _v = _end - _beg;
			Vector3 _mid = _beg + _v * 0.5f;

			if (_v.sqrMagnitude > _maxSqrDist)
			{				
				var _sample = new Sample();
				_sample.direction = _dir;
				_sample.position = _mid;
				_outList.Add(_sample);

				GatherSamples(_outList, _beg, _mid, _dir, _maxSqrDist);
				GatherSamples(_outList, _mid, _end, _dir, _maxSqrDist);
			}
		}
	}
}