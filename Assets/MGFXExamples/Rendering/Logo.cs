using UnityEngine;
using System.Collections.Generic;

namespace MGFX
{
    [ExecuteInEditMode]
    public class Logo : MonoBehaviour
    {
        List<Vector3> m_Tessellated = new List<Vector3>();
        public List<Vector3> m_Path = new List<Vector3>();

        public void OnEnable()
        {
            m_Path.Clear();
            m_Path.Add(new Vector3(1, 0, 0));
            m_Path.Add(new Vector3(1, 2, 0));
            m_Path.Add(new Vector3(2, 1.5f, 0));
            m_Path.Add(new Vector3(3, 2, 0));
            m_Path.Add(new Vector3(3,-1, 0));
            m_Path.Add(new Vector3(2.5f,-1, 0));
            m_Path.Add(new Vector3(2, -0.5f, 0));
            m_Path.Add(new Vector3(3.5f, 0.5f, 0));

            m_Tessellated.Clear();
            CurveFitting.CentripetalCatmullRom.Tessellate(m_Tessellated, 4, 0.5f, m_Path);

            if (m_Tessellated.Count > 0)
                CreateVolLines();
        }
        public void OnDrawGizmos()
        {
            var _m = transform.localToWorldMatrix;
            // Draw Cage
            Gizmos.color = new Color(0, 1, 0, 0.5f);
            var _last = _m.MultiplyPoint(m_Path[0]);
            for (int _i = 1; _i < m_Path.Count; ++_i)
            {
                var _curr = _m.MultiplyPoint(m_Path[_i]);
                Gizmos.DrawLine(_last, _curr);
                _last = _curr;
            }
        }
        /*
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
        */

        private void CreateVolLines()
        {
            foreach(var _old in this.GetComponentsInChildren<VolumetricLine>())
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
        }

        Color m_LineColor = new Color(0.25f, 0.25f, 1.0f, 0.5f);

        private void CreateVolLine(int _i)
        {
            var _beg = m_Tessellated[_i - 1];
            var _end = m_Tessellated[_i];

            var _gobj = new GameObject("Seg" + _i.ToString("D3"));
            var _line = _gobj.AddComponent<VolumetricLine>();
            _line.m_Color = m_LineColor;
            _line.transform.position = _beg;
            //_line.transform.LookAt(_end);

            Vector3 _scl = new Vector3(0.1f, 0.1f, (_end - _beg).magnitude * 0.25f);
            _line.transform.localScale = _scl;

            _gobj.transform.SetParent(transform);
        }
    }

}
