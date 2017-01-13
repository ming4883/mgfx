using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(RenderFeatureHDR))]
	public class RenderFeatureHDRUI : Editor
	{
		public static void DoAutoUI(RenderFeatureHDRSceneData _sceneData)
		{
			if (null == _sceneData || !_sceneData)
				return;

			var _s = new SerializedObject(_sceneData);
			_s.Update();
			DrawPropertiesExcluding(_s);
			_s.ApplyModifiedProperties();

			EditorGUILayout.Separator();

			//GUILayout.Space(EditorGUI.indentLevel * 20);
			if (GUILayout.Button("From Scene"))
			{
				GuessFromScene(_sceneData, 1.5f);
			}

			EditorGUILayout.Separator();
		}

		public static void GuessFromScene(RenderFeatureHDRSceneData _sceneData, float _ratio)
		{
			if (null == _sceneData || !_sceneData)
				return;

			float _totalIntensity = 0.0f;
			foreach (var _light in GameObject.FindObjectsOfType<Light>())
			{
				if (_light.type == LightType.Directional)
					_totalIntensity += _light.intensity;
			}

			_totalIntensity += RenderSettings.ambientIntensity;
			_totalIntensity = Mathf.Max(0.5f, _totalIntensity);

			_sceneData.exposure = 1.0f;
			_sceneData.whitePointBias = _totalIntensity * _ratio;
			_sceneData.bloomThreshold = _totalIntensity * 0.5f;
			_sceneData.bloomIntensity = 0.5f;

		}

		public override void OnInspectorGUI()
		{
			DoAutoUI((target as RenderFeatureHDR).SceneData);
		}
	}
}