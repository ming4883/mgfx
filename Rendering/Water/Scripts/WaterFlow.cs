using UnityEngine;
using System.Collections.Generic;


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

        public void GetRenderMatrics(out Matrix4x4 _mesh, out Matrix4x4 _points)
        {
            Quaternion _rot = transform.rotation;
            Vector3 _pos = transform.position;

            _mesh = Matrix4x4.TRS(_pos, _rot, new Vector3(1, 1, 1));
            _points = Matrix4x4.TRS(_pos, _rot, new Vector3(1, 1, 1));
        }

        public void GetPoints(Matrix4x4 _mat, out Vector3 _beg, out Vector3 _end)
        {
            _beg = _mat.MultiplyPoint(new Vector3(0, 0, 0.0f));
            _end = _mat.MultiplyPoint(new Vector3(0, 0, 1.0f));
        }

        private static Color m_LineColor = new Color(1, 0, 0, 0.5f);
        //private static Color m_BoxColor = new Color(1, 1, 1, 0.5f);

        public void OnDrawGizmos()
        {
            int _numOfPts = points.Length;

			if (_numOfPts < 2)
				return;

            Gizmos.matrix = Matrix4x4.identity;
            Gizmos.color = m_LineColor;
            
            for(int _it = 1; _it < _numOfPts; _it++)
			{
				var _beg = points[_it-1];
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