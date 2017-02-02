using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(WaterFlowMap))]
	public class WaterFlowMapEditor : Editor
	{
		private GUIContent kBakeText = new GUIContent("Bake");
		public override void OnInspectorGUI()
		{
			base.DrawDefaultInspector();

			EditorGUILayout.Separator();

			if (GUILayout.Button(kBakeText))
			{
				
			}
		}
	}
}