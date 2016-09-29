using UnityEngine;
using System.Collections.Generic;

namespace MGFX
{
    [ExecuteInEditMode]
    public class TestCentripetalCatmullRom : MonoBehaviour
    {
        List<Vector3> m_Tessellated = new List<Vector3>();
        public List<Vector3> m_Path = new List<Vector3>();

        public void OnEnable()
        {
            m_Path.Clear();
            m_Path.Add(new Vector3(0, 1, 0));
            m_Path.Add(new Vector3(1, 0, 0));
            m_Path.Add(new Vector3(2, 0, 0));
            m_Path.Add(new Vector3(3, 2, 0));
        }

        public void OnDrawGizmos()
        {
            // Draw Cage
            Gizmos.color = Color.green;
            Gizmos.DrawLine(m_Path[0], m_Path[1]);
            Gizmos.DrawLine(m_Path[1], m_Path[2]);
            Gizmos.DrawLine(m_Path[2], m_Path[3]);

            // Draw tessellated full path
            m_Tessellated.Clear();
            CurveFitting.CentripetalCatmullRom.Tessellate(m_Tessellated, 8, 0.5f, m_Path);

            if (m_Tessellated.Count > 1)
            {
                Gizmos.color = Color.magenta;

                for (int _i = 1; _i < m_Tessellated.Count; ++_i)
                {
                    Gizmos.DrawLine(m_Tessellated[_i], m_Tessellated[_i - 1]);   
                }
            }

            // Draw tessellated m_Path[1] to m_Path[2]
            m_Tessellated.Clear();
            CurveFitting.CentripetalCatmullRom.Tessellate(m_Tessellated, 8, 0.5f, m_Path[0], m_Path[1], m_Path[2], m_Path[3]);

            if (m_Tessellated.Count > 1)
            {
                // m_Tessellated should not include m_Path[1] and m_Path[2]
                Gizmos.color = Color.cyan;

                for (int _i = 1; _i < m_Tessellated.Count; ++_i)
                {
                    Gizmos.DrawLine(m_Tessellated[_i], m_Tessellated[_i - 1]);   
                }
            }
        }
    }

}
