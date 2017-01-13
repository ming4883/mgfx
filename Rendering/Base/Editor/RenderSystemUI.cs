using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(RenderSystem))]
	public class RenderSystemUI : Editor
	{
		public override void OnInspectorGUI()
		{
			var _target = (target as RenderSystem);
			
			EditorGUILayout.HelpBox("Statistics", MessageType.None);
			EditorGUILayout.LabelField("Num of RenderTexture: " + _target.CameraBuffers.Count);
			EditorGUILayout.LabelField("Num of CommandBuffers: " + _target.Commands.Count);

			EditorGUILayout.Separator();
		}
	}
}