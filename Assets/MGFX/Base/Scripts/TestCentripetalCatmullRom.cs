using UnityEngine;
using System.Collections.Generic;

namespace MGFX
{
    [ExecuteInEditMode]
    public class TestCentripetalCatmullRom : MonoBehaviour
    {
        List<Vector3> m_Points = new List<Vector3>();
        public Vector3 _p0 = new Vector3(0, 1, 0);
        public Vector3 _p1 = new Vector3(1, 0, 0);
        public Vector3 _p2 = new Vector3(2, 0, 0);
        public Vector3 _p3 = new Vector3(3, 2, 0);

        public void OnEnable()
        {
            
        }

        public void OnDrawGizmos ()
        {
            
            Gizmos.color = Color.green;
            Gizmos.DrawLine(_p0, _p1);
            Gizmos.DrawLine(_p1, _p2);
            Gizmos.DrawLine(_p2, _p3);

            m_Points.Clear();
            CurveFitting.CentripetalCatmullRom.Intrpl(m_Points, 16, 0.5f, _p0, _p1, _p2, _p3);
            //Log.I("Generated {0} points", m_Points.Count);

            if (m_Points != null && m_Points.Count > 1)
            {
                Gizmos.color = Color.cyan;
                Gizmos.DrawLine(_p1, m_Points[0]);

                for (int _i = 1; _i < m_Points.Count; ++_i)
                {
                    Gizmos.DrawLine(m_Points[_i], m_Points[_i - 1]);   
                }

                Gizmos.DrawLine(m_Points[m_Points.Count - 1], _p2);
            }
        }
    }

}
