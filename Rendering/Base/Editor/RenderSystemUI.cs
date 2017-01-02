using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(RenderSystem))]
	public class RenderSystemUI : Editor
	{
		GUIContent m_txtFixColorSpace = new GUIContent("Fix color space Settings");
		//GUIContent m_txtUseLinear = new GUIContent("Use Linear Color Space");
		string m_strColorSpaceWarning = "This project is using Gamma color space, please consider switching to Linear color space";
		public override void OnInspectorGUI()
		{
			var _target = (target as RenderSystem);

			EditorGUILayout.Separator();

			if (PlayerSettings.colorSpace != ColorSpace.Linear)
			{
				EditorGUILayout.HelpBox("Color Space", MessageType.None);

				EditorGUILayout.HelpBox(m_strColorSpaceWarning, MessageType.Warning);

				if (GUILayout.Button(m_txtFixColorSpace))
				{
					EditorApplication.ExecuteMenuItem("Edit/Project Settings/Player");
				}
			}


			EditorGUILayout.Separator();

			var _hdrConfig = new ColorPickerHDRConfig(0, 5, 0, 2);

			EditorGUILayout.HelpBox("Lighting", MessageType.None);
			RenderSettings.ambientSkyColor = EditorGUILayout.ColorField(new GUIContent("Ambient color"), RenderSettings.ambientSkyColor, true, false, true, _hdrConfig);

			RenderSettings.ambientMode = (UnityEngine.Rendering.AmbientMode) EditorGUILayout.EnumPopup(new GUIContent("Ambient Source"), RenderSettings.ambientMode);

			RenderSettings.ambientIntensity = EditorGUILayout.FloatField(new GUIContent("Ambient intensity"), RenderSettings.ambientIntensity);

			EditorGUILayout.Separator();
			EditorGUILayout.HelpBox("Skybox", MessageType.None);
			RenderSettings.skybox = (Material)EditorGUILayout.ObjectField(new GUIContent("Material"), RenderSettings.skybox, typeof(Material), false);

			EditorGUILayout.Separator();

			EditorGUILayout.HelpBox("Statistics", MessageType.None);
			EditorGUILayout.LabelField("Num of RenderTexture: " + _target.CameraBuffers.Count);
			EditorGUILayout.LabelField("Num of CommandBuffers: " + _target.Commands.Count);

			EditorGUILayout.Separator();
		}
	}
}