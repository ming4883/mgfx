using UnityEngine;
using UnityEditor;
using System;

namespace MGFX
{
    [CustomEditor(typeof(RenderSystem))]
    public class RenderSystemUI : Editor
    {
        GUIContent m_txtFixColorSpace = new GUIContent("Fix color space Settings");
        //GUIContent m_txtUseLinear = new GUIContent("Use Linear Color Space");
        string m_strColorSpaceWarning = "This project is using Gamma color space, please consider switching to Linear color space";
        public override void OnInspectorGUI()
        {
            
            EditorGUILayout.Separator();

            if (PlayerSettings.colorSpace != ColorSpace.Linear)
            {
                EditorGUILayout.HelpBox(m_strColorSpaceWarning, MessageType.Warning);

                if (GUILayout.Button(m_txtFixColorSpace))
                {
                    EditorApplication.ExecuteMenuItem("Edit/Project Settings/Player");
                }
            }

            EditorGUILayout.Separator();
        }
    }
}