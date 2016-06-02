using UnityEngine;
using System.Collections.Generic;


namespace MGFX
{
	[ExecuteInEditMode]
	[AddComponentMenu("Rendering/MGFX/VolumetricLine")]
	public class VolumetricLine : MonoBehaviour
	{
		public Color m_Color = Color.white;

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

        public float GetRenderMatrics(out Matrix4x4 _mesh, out Matrix4x4 _points)
        {
            Quaternion _rot = transform.rotation;
            Vector3 _pos = transform.position;
            Vector3 _scl = transform.lossyScale;
            float _radius = _scl.x;
            float _radius2x = _radius * 2.0f;
            float _meshSize = 0.5f;

            _mesh = Matrix4x4.TRS(_pos, _rot, new Vector3(_radius2x, _scl.y + _radius2x, _radius2x));
            _mesh = _mesh * Matrix4x4.TRS(new Vector3(0, _meshSize - _radius, 0), Quaternion.identity, Vector3.one);
            _points = Matrix4x4.TRS(_pos, _rot, new Vector3(_radius2x, _scl.y, _radius2x));
            return _radius;
        }

        public void GetPoints(Matrix4x4 _mat, out Vector3 _beg, out Vector3 _end)
        {
            _beg = _mat.MultiplyPoint(new Vector3(0, 0.0f, 0));
            _end = _mat.MultiplyPoint(new Vector3(0, 1.0f, 0));
        }

		public Color GetLinearColor ()
		{
			return new Color(
                Mathf.GammaToLinearSpace(m_Color.r),
				Mathf.GammaToLinearSpace(m_Color.g),
				Mathf.GammaToLinearSpace(m_Color.b),
                m_Color.a
			);
		}

        private static Color m_LineColor = new Color(1, 0, 0, 0.25f);
        private static Color m_BoxColor = new Color(1, 1, 1, 0.5f);
        public void OnDrawGizmos ()
        {
            Matrix4x4 _m, _p;
            GetRenderMatrics(out _m, out _p);
            float _r = 0.5f;

            Vector3 _beg, _end;
            GetPoints(_p, out _beg, out _end);

            Gizmos.matrix = Matrix4x4.identity;
            Gizmos.color = m_LineColor;
            Gizmos.DrawLine(_beg, _end);
            Gizmos.DrawLine(_beg, _beg + _p.MultiplyVector(Vector3.right) * _r);
            Gizmos.DrawLine(_beg, _beg + _p.MultiplyVector(Vector3.forward) * _r);
        }

        public void OnDrawGizmosSelected ()
        {
            Matrix4x4 _m, _p;
            GetRenderMatrics(out _m, out _p);

            Gizmos.matrix = _m;
            Gizmos.color = m_BoxColor;
            Gizmos.DrawWireCube(Vector3.zero, new Vector3(1, 1, 1));
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