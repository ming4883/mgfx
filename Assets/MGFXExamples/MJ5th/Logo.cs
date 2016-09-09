using UnityEngine;
using System.Collections.Generic;

namespace MGFX
{
    [ExecuteInEditMode]
    public class Logo : MonoBehaviour
    {
        List<Vector3> m_Tessellated = new List<Vector3>();
        public List<Vector3> m_Path = new List<Vector3>();
        public Vector3 m_Dot1;
        public Vector3 m_Dot2;

        public void OnEnable()
        {
            m_Path.Clear();
            m_Path.Add(new Vector3(-0.8f, 0, 0));
            m_Path.Add(new Vector3(-1, 0.75f, 0));
            m_Path.Add(m_Dot1 = new Vector3(-0.8f, 1.75f, 0));
            m_Path.Add(new Vector3(0, 1.5f, 0));
            m_Path.Add(m_Dot2 = new Vector3(1, 2, 0));
            m_Path.Add(new Vector3(1.2f, 0, 0));
            m_Path.Add(new Vector3(1, -1, 0));
            m_Path.Add(new Vector3(0.25f, -1.5f, 0));
            m_Path.Add(new Vector3(-0.25f, -1.0f, 0));
			m_Path.Add(new Vector3(0.25f, 0.0f, 0));
			m_Path.Add(new Vector3(2.0f, 1.0f, 0));

            m_Dot1.y += 0.5f;
            m_Dot2.y += 0.5f;

            m_Tessellated.Clear();
            CurveFitting.CentripetalCatmullRom.Tessellate(m_Tessellated, 8, 0.5f, m_Path);

            if (m_Tessellated.Count > 0)
                CreateVolLines();
        }

        public static Color m_CageColor = new Color(0, 1, 0, 0.5f);
        public static Color m_CurveColor = new Color(0, 1, 1, 0.5f);

        public void FixedUpdate()
        {
            transform.Rotate(new Vector3(0, 1.0f, 0));
        }

        public void OnDrawGizmos()
        {
            var _m = transform.localToWorldMatrix;
            // Draw Cage
            Gizmos.color = m_CageColor;
            var _last = _m.MultiplyPoint(m_Path[0]);
            for (int _i = 1; _i < m_Path.Count; ++_i)
            {
                var _curr = _m.MultiplyPoint(m_Path[_i]);
                Gizmos.DrawLine(_last, _curr);
                _last = _curr;
            }
        }

        public void OnDrawGizmosSelected()
        {
            // Draw tessellated full path
            if (m_Tessellated.Count > 1)
            {
                Gizmos.color = Color.magenta;

                for (int _i = 1; _i < m_Tessellated.Count; ++_i)
                {
                    Gizmos.DrawLine(m_Tessellated[_i], m_Tessellated[_i - 1]);   
                }
            }
        }


        public Color m_VolLineColor = new Color(1.0f, 0.5f, 0.625f, 0.5f);
        public Color m_VolDotColor = new Color(1.0f, 0.5f, 0.625f, 1.0f);

        private void CreateVolLines()
        {
            foreach (var _old in this.GetComponentsInChildren<VolumetricLine>())
            {
                if (!Application.isPlaying)
                    GameObject.DestroyImmediate(_old.gameObject);
                else
                    GameObject.Destroy(_old.gameObject);
            }

            for (int _i = 1; _i < m_Tessellated.Count; ++_i)
            {
                CreateVolLine(_i); 
            }

            CreateVolLine("Dot001", m_Dot1, m_Dot1, m_VolDotColor);
            CreateVolLine("Dot002", m_Dot2, m_Dot2, m_VolDotColor);
        }

        private void CreateVolLine(int _i)
        {
            var _beg = m_Tessellated[_i - 1];
            var _end = m_Tessellated[_i];

            CreateVolLine("Seg" + _i.ToString("D3"), _beg, _end, m_VolLineColor);
        }

        private void CreateVolLine(string _name, Vector3 _beg, Vector3 _end, Color _color)
        {
            var _gobj = new GameObject(_name);
            var _line = _gobj.AddComponent<VolumetricLine>();
            _line.m_Color = _color;
            _line.SetupTransform(_beg, _end, 0.25f);
            _gobj.transform.SetParent(transform);
        }
    }

}
