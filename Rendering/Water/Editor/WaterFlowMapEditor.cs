using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(WaterFlowMap))]
	public class WaterFlowMapEditor : Editor
	{
		private GUIContent kShowSampleText = new GUIContent("Show Samples");
		private GUIContent kBakeText = new GUIContent("Bake");
		private static bool m_ShowSamples = false;
		private static Color m_CachedColor = new Color(1.0f, 0.5f, 0.5f, 0.5f);
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
				int _tw = Mathf.NextPowerOfTwo((int)_inst.resolution.x);
				int _th = Mathf.NextPowerOfTwo((int)_inst.resolution.y);

				Vector2 _delta = new Vector2(_inst.size.x / _tw, _inst.size.y / _th);

				List<WaterFlow.Sample> _samples = new List<WaterFlow.Sample>();

				foreach (var _flow in _inst.flows)
				{
					if (null == _flow || !_flow)
						continue;
					
					_flow.GatherSamples(_samples, _delta);
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
			int _tw = Mathf.NextPowerOfTwo((int)_inst.resolution.x);
			int _th = Mathf.NextPowerOfTwo((int)_inst.resolution.y);

			Vector2 _delta = new Vector2(_inst.size.x / _tw, _inst.size.y / _th);

			List<WaterFlow.Sample> _samples = _inst.GatherSamples(_delta);

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

			Texture2D _tex = new Texture2D(_tw, _th, TextureFormat.ARGB32, false);

			var _transform = _inst.transform;
			
			Vector2 _offset = _inst.size * -0.5f +  _delta * 0.5f;

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
					//if (_knn.Length == 1)
					{
						var _sampA = _samples[_knn[0]];
						var _sampB = _samples[_knn[1]];
						var _sampC = _samples[_knn[2]];
						Vector3 _weights;
						Vector3 _dir = _sampA.direction;

						if (Triangle.GetBarycentricCoords(out _weights, _sampA.position, _sampB.position, _sampC.position, _worldPos))
						{
							_dir = (_sampA.direction * _weights.x) + (_sampB.direction * _weights.y) + (_sampC.direction * _weights.z);
							_dir = _dir.normalized;
						}

						_clr.r = -_dir.x * 0.5f + 0.5f;
						_clr.g = -_dir.z * 0.5f + 0.5f;
						_clr.b = 0.0f;// -_dir.y * 0.5f + 0.5f;
						
						_clr.a = 1.0f;

						_inst.cached[_c].direction = _dir;
						
					}
#if false
					// debug uv mapping
					_clr.r = (float)_x / _tw;
					_clr.g = (float)_y / _th;
					_clr.b = 0;
#endif
					_tex.SetPixel(_x, _y, _clr);

					_c++;
				}
			}

			Scene _scene = SceneManager.GetActiveScene();
			string _path = System.IO.Path.GetDirectoryName(_scene.path);
			_path = _path + "/" + _inst.Filename;
			
			System.IO.File.WriteAllBytes(Application.dataPath + _path.Remove(0, 6), _tex.EncodeToPNG());

			AssetDatabase.ImportAsset(_path);

			TextureImporter _imp = TextureImporter.GetAtPath(_path) as TextureImporter;
			_imp.filterMode = FilterMode.Bilinear;
			_imp.wrapMode = TextureWrapMode.Clamp;
			_imp.anisoLevel = 0;
			_imp.mipmapEnabled = false;
			_imp.sRGBTexture = true;
			_imp.textureCompression = TextureImporterCompression.Uncompressed;
			_imp.SaveAndReimport();
		}
	}
}