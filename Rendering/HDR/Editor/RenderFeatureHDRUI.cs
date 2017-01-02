using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
    [CustomEditor(typeof(RenderFeatureHDR))]
    public class RenderFeatureHDRUI : Editor
    {
        public override void OnInspectorGUI()
        {
			var _sceneData = (target as RenderFeatureHDR).SceneData;
			var _s = new SerializedObject(_sceneData);
			_s.Update();
			DrawPropertiesExcluding(_s);
			_s.ApplyModifiedProperties();

        }
    }
}