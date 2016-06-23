using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX
{
    class ShaderUtils : EditorWindow
    {
        [MenuItem("Window/MGFX/ShaderUtils", false, 3001)]
        public static void MenuItem()
        {
            ShaderUtils _window = EditorWindow.CreateInstance <ShaderUtils>();
            _window.titleContent = new GUIContent("ShaderUtils");
            _window.minSize = new Vector2(450, 180);
            _window.ShowUtility();
        }

        Texture2D m_BayerTex;

        void OnGUI()
        {
            EditorGUILayout.Separator();

            EditorGUILayout.BeginVertical(new GUILayoutOption[0]);
            m_BayerTex = EditorGUILayout.ObjectField("Dither Matrix", m_BayerTex, typeof(Texture2D), true, new GUILayoutOption[0]) as Texture2D;

            if (GUILayout.Button("Apply To All Materials"))
            {
                int _cnt = 0;
                foreach (Material _mtl in Resources.FindObjectsOfTypeAll<Material>())
                {
                    if (_mtl.HasProperty("_BayerTex"))
                    {
                        _mtl.SetTexture("_BayerTex", m_BayerTex);
                        _cnt++;
                    }
                }

                if (_cnt > 0)
                {
                    EditorUtility.DisplayDialog(titleContent.text, string.Format("Applied to {0} Materials", _cnt), "OK");
                }
            }

            EditorGUILayout.EndVertical();
        }
    }
}