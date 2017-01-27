using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(RenderFeatureHDR))]
	public class RenderFeatureHDRUI : Editor
	{
		Editor m_DataEditor;
		public void OnSceneDataUI(RenderFeatureHDRSceneData _sceneData)
		{
			if (null == _sceneData || !_sceneData)
				return;

			Editor.CreateCachedEditor(_sceneData, null, ref m_DataEditor);
			m_DataEditor.OnInspectorGUI();

			EditorGUILayout.Separator();

			if (GUILayout.Button("From Scene"))
			{
				GuessFromScene(_sceneData, 1.25f);
				SceneView.RepaintAll();
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

			_totalIntensity += RenderSettings.ambientIntensity * 2.0f;
			_totalIntensity = Mathf.Max(0.5f, _totalIntensity);

			float _whitePoint = _totalIntensity * _ratio;
			_sceneData.exposure = 1.0f;
			_sceneData.whitePointBias = _whitePoint;
			_sceneData.bloomThreshold = _whitePoint * 0.5f;
			_sceneData.bloomIntensity = 0.5f;

		}

		public override void OnInspectorGUI()
		{
			OnSceneDataUI((target as RenderFeatureHDR).SceneData);
		}
	}
}