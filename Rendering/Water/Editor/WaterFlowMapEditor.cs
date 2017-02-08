using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(WaterFlowMap))]
	public class WaterFlowMapEditor : Editor
	{
		private GUIContent kShowSampleText = new GUIContent("Show Samples");
		private GUIContent kBakeText = new GUIContent("Bake");
		private static bool m_ShowSamples = false;
		private static Color m_CachedColor = new Color(0, 0, 1, 0.5f);
		private static Color m_SampleColor = new Color(1, 1, 1, 0.5f);
		private static Color m_OffsetUColor = new Color(1, 0, 0, 0.5f);
		private static Color m_OffsetVColor = new Color(0, 1, 0, 0.5f);

		public override void OnInspectorGUI()
		{
			base.DrawDefaultInspector();

			EditorGUILayout.Separator();
			EditorGUI.BeginChangeCheck();
			m_ShowSamples = EditorGUILayout.Toggle(kShowSampleText, m_ShowSamples);
			if (EditorGUI.EndChangeCheck())
			{
				SceneView.RepaintAll();
			}

			EditorGUILayout.Separator();

			if (GUILayout.Button(kBakeText))
			{
				Bake(target as WaterFlowMap);
			}
		}

		public void OnSceneGUI()
		{
			var _inst = target as WaterFlowMap;

			Vector2 _offset = _inst.size * -0.5f;

			{
				Vector3 _pt = new Vector3(_offset.x, 0, _offset.y);
				_pt = _inst.transform.TransformPoint(_pt);
				float _scale = HandleUtility.GetHandleSize(_pt) * 0.125f;

				Vector3 _du = Vector3.right;
				Vector3 _dv = Vector3.forward;

				_du = _inst.transform.TransformVector(_du);
				_dv = _inst.transform.TransformVector(_dv);

				Handles.color = m_OffsetUColor;
				Handles.ConeCap(0, _pt + _du * _scale, Quaternion.FromToRotation(Vector3.forward, _du), _scale);

				Handles.color = m_OffsetVColor;
				Handles.ConeCap(0, _pt + _dv * _scale, Quaternion.FromToRotation(Vector3.forward, _dv), _scale);
			}

			if (_inst.cached != null)
			{
				Handles.color = m_CachedColor;
				foreach (var _samp in _inst.cached)
				{
					float _scale = HandleUtility.GetHandleSize(_samp.position) * 0.0625f;

					if (_samp.direction.sqrMagnitude > 0)
						Handles.ConeCap(0, _samp.position, Quaternion.FromToRotation(Vector3.forward, _samp.direction), _scale);
				}
			}

			if (m_ShowSamples)
			{
				List<WaterFlow.Sample> _samples = new List<WaterFlow.Sample>();

				foreach (var _flow in _inst.flows)
				{
					if (null == _flow || !_flow)
						continue;
					
					_flow.GatherSamples(_samples);
				}

				if (_samples.Count == 0)
					return;

				Handles.color = m_SampleColor;

				for(int _it = 0; _it < _samples.Count; ++_it)
				{
					var _samp = _samples[_it];
					float _scale = HandleUtility.GetHandleSize(_samp.position) * 0.0625f;

					if (_samp.direction.sqrMagnitude > 0)
						Handles.ConeCap(0, _samp.position, Quaternion.FromToRotation(Vector3.forward, _samp.direction), _scale);
				}
			} // if (m_ShowSamples)

		} // OnSceneGUI

		private void Bake(WaterFlowMap _inst)
		{
			List<WaterFlow.Sample> _samples = _inst.GatherSamples();

			if (_samples.Count == 0)
				return;

			KdTree.Entry[] _kdEnt = new KdTree.Entry[_samples.Count];
			for (int _it = 0; _it < _samples.Count; ++_it)
			{
				_kdEnt[_it] = new KdTree.Entry(_samples[_it].position, _it);
			}

			KdTree _kdTree = new KdTree();
			_kdTree.build(_kdEnt);

			var _kqueue = new KdTree.KQueue(3);

			int _tw = Mathf.NextPowerOfTwo((int)_inst.resolution.x);
			int _th = Mathf.NextPowerOfTwo((int)_inst.resolution.y);
			Texture2D _tex = new Texture2D(_tw, _th, TextureFormat.ARGB32, false);

			Vector2 _offset = _inst.size * -0.5f;
			Vector2 _delta = new Vector2(_inst.size.x / _tw, _inst.size.y / _th);
			_offset += _delta * 0.5f;
			var _transform = _inst.transform;

			_inst.cached = new WaterFlow.Sample[_tw * _th];
			int _c = 0;

			for(int _y = 0; _y < _th; ++_y)
			{
				for(int _x = 0; _x < _tw; ++_x)
				{
					Vector2 _pos = _offset + Vector2.Scale(_delta, new Vector2(_x, _y));
					Vector3 _worldPos = new Vector3(_pos.x, 0, _pos.y);

					_worldPos = _transform.TransformPoint(_worldPos);

					_inst.cached[_c] = new WaterFlow.Sample() {
						position = _worldPos,
						direction = Vector3.zero,
					};

					Color _clr = new Color(0.5f, 0.5f, 0.5f, 0.0f);

					int[] _knn = _kdTree.knearest(_kqueue, _worldPos, 3);
					if (_knn.Length > 1)
					{
						var _samp = _samples[_knn[0]];
						_clr.r = _samp.direction.x * 0.5f + 0.5f;
						_clr.g = _samp.direction.y * 0.5f + 0.5f;
						_clr.b = _samp.direction.z * 0.5f + 0.5f;
						_clr.a = 1.0f;

						_inst.cached[_c].direction = _samp.direction;
					}

					_tex.SetPixel(_x, _y, _clr);

					_c++;
				}
			}

			string _path = Application.dataPath + "/-WaterFlowMap.png";

			System.IO.File.WriteAllBytes(_path, _tex.EncodeToPNG());

			_path = "Assets/-WaterFlowMap.png";

			AssetDatabase.ImportAsset(_path);

			TextureImporter _imp = TextureImporter.GetAtPath(_path) as TextureImporter;
			_imp.filterMode = FilterMode.Bilinear;
			_imp.wrapMode = TextureWrapMode.Clamp;
			_imp.anisoLevel = 0;
			_imp.mipmapEnabled = false;
			_imp.sRGBTexture = true;
			_imp.textureCompression = TextureImporterCompression.Uncompressed;
			_imp.SaveAndReimport();
			
			//Texture2D.DestroyImmediate(_tex);

		}
	}
}