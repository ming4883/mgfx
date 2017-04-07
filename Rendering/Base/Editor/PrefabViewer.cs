using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Animations;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	public class PrefabViewer : EditorWindow
	{
		private GameObject m_Prefab;
		
		// Animations
		private int m_SelectedState = -1;
		private float m_TimeScale = 1.0f;
		private List<string> m_StateNames = new List<string>();
		private List<System.Object> m_StateObjects = new List<System.Object>();
		private List<int> m_StateValues = new List<int>();

		// Environment
		private SceneAsset m_BgScene;
		private Material m_Skybox;

		public void OnGUI()
		{
			if (EditorApplication.isPlaying)
			{
				EditorGUILayout.HelpBox("Stop Playback to Change.", MessageType.Warning);
			}
			else
			{
				m_Prefab = EditorGUILayout.ObjectField("Prefab", m_Prefab, typeof(GameObject), false) as GameObject;

				if (null == m_Prefab)
				{
					EditorGUILayout.HelpBox("Please select a Prefab.", MessageType.Warning);
					return;
				}
					
				// Animation UI
				Animation _anim = m_Prefab.GetComponentInChildren<Animation>();
				Animator _anim2 = m_Prefab.GetComponentInChildren<Animator>();

				if (!_anim && !_anim2)
				{
					EditorGUILayout.HelpBox("Animation not found.", MessageType.Warning);
				}
				else
				{
					EditorGUILayout.HelpBox("Animation", MessageType.None);
					EditorGUI.indentLevel++;

					m_StateNames.Clear();
					m_StateObjects.Clear();
					m_StateValues.Clear();

					if (_anim)
					{
						foreach (AnimationState _state in _anim)
						{
							m_StateNames.Add(_state.name);
							m_StateObjects.Add(_state);
							m_StateValues.Add(m_StateValues.Count);
						}
					}
					else if (_anim2)
					{
						foreach(var _clip in _anim2.runtimeAnimatorController.animationClips)
						{
							m_StateNames.Add(_clip.name);
							m_StateObjects.Add(_clip);
							m_StateValues.Add(m_StateValues.Count);
						}

						if (m_SelectedState > -1 && m_SelectedState < m_StateObjects.Count)
						{
							AnimationClip _clip = (AnimationClip)m_StateObjects[m_SelectedState];
							if (!AnimationUtility.GetAnimationClipSettings(_clip).loopTime)
							{
								EditorGUILayout.HelpBox(string.Format("Animation Clip '{0}' is not looping!\nPlease ensure 'Loop Time' is enabled!", _clip.name), MessageType.Warning);
							}
						}
					}
					
					m_SelectedState = EditorGUILayout.IntPopup("State", m_SelectedState, m_StateNames.ToArray(), m_StateValues.ToArray());

					m_TimeScale = EditorGUILayout.Slider("Time Scale", m_TimeScale, 0.25f, 4.0f);

					EditorGUI.indentLevel--;
				}

				// Environment UI
				{
					EditorGUILayout.HelpBox("Environment", MessageType.None);
					EditorGUI.indentLevel++;

					m_Skybox = EditorGUILayout.ObjectField("Skybox", m_Skybox, typeof(Material), false) as Material;

					EditorGUI.indentLevel--;
				}

				EditorGUILayout.Separator();
				EditorGUILayout.Separator();

				if (GUILayout.Button("View"))
				{
					ViewPrefab();
				}
			}
		}

		private void ViewPrefab()
		{
			EditorUtility.DisplayProgressBar("Prefab Viewer", "Preparing for preview", 0);

			var _scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
			var _inst = PrefabUtility.InstantiatePrefab(m_Prefab) as GameObject;

			Camera _cam = null;
			foreach(var _rootObj in _scene.GetRootGameObjects())
			{
				_cam = _rootObj.GetComponent<Camera>();
				if (_cam)
					break;
			}
			Light _light = null;
			foreach (var _rootObj in _scene.GetRootGameObjects())
			{
				_light = _rootObj.GetComponent<Light>();
				if (_light)
					break;
			}

			GameObject _target = null;

			List<Vector3> _lightProbes = new List<Vector3>();
			// Zoom extends
			if (_cam)
			{
				Bounds _bounds;

				if (Geometry.GetBounds(_inst, out _bounds))
				{
					Log.I("zoom extends {0}", _bounds);
					var _ext = _bounds.extents.magnitude;
					
					_target = new GameObject("Camera Target");
					_target.transform.position = _bounds.center + new Vector3(0, 0, 0);

					_cam.transform.position = _bounds.center + new Vector3(0, 0, _ext * 2);
					_cam.transform.LookAt(_bounds.center);
					_cam.nearClipPlane = _ext /256.0f;
					_cam.farClipPlane = Mathf.Max(_ext * 5, 2.0f);

					var _min = _bounds.min;
					var _max = _bounds.max;

					_lightProbes.Add(new Vector3(_min.x, _min.y, _min.z));
					_lightProbes.Add(new Vector3(_min.x, _min.y, _max.z));
					_lightProbes.Add(new Vector3(_min.x, _max.y, _min.z));
					_lightProbes.Add(new Vector3(_min.x, _max.y, _max.z));
					
					_lightProbes.Add(new Vector3(_max.x, _min.y, _min.z));
					_lightProbes.Add(new Vector3(_max.x, _min.y, _max.z));
					_lightProbes.Add(new Vector3(_max.x, _max.y, _min.z));
					_lightProbes.Add(new Vector3(_max.x, _max.y, _max.z));
				}
			}

			// Add 3rd person control
			if (_target)
			{
				var _control = _cam.gameObject.AddComponent<ControlWithInput>();
				_control.target = _target.transform;
				_control.style = ControlWithInput.ControlStyles.ThirdPerson;
			}

			// Set current state
			Animation _anim = _inst.GetComponent<Animation>();
			Animator _anim2 = _inst.GetComponent<Animator>();
			bool _indexValid = m_SelectedState >= 0 && m_SelectedState < m_StateNames.Count;
			if ((_anim || _anim2) && _indexValid)
			{
				var _selectedName = m_StateNames[m_SelectedState];
				if (_anim)
				{
					_anim.wrapMode = WrapMode.Loop;
					_anim.clip = _anim.GetClip(_selectedName);
				}
				else if (_anim2)
				{
					var _controller = new UnityEditor.Animations.AnimatorController();
					_controller.name = "PREVIEW";
					var _layer = new UnityEditor.Animations.AnimatorControllerLayer();
					_layer.stateMachine = new UnityEditor.Animations.AnimatorStateMachine();

					var _state = _layer.stateMachine.AddState(_selectedName);
					_state.motion = (AnimationClip)m_StateObjects[m_SelectedState];
					
					_controller.AddLayer(_layer);

					_anim2.runtimeAnimatorController = _controller;
				}
				
				Time.timeScale = m_TimeScale;
			}

			if (m_Skybox)
				RenderSettings.skybox = m_Skybox;
			
			// Setup Lighting
			if (_light)
			{
				_light.transform.eulerAngles = new Vector3(50, 180, 0);
			}

			if (_lightProbes.Count > 0)
			{
				var _lightProbesGroup = new GameObject("LightProbes").AddComponent<LightProbeGroup>();

				_lightProbesGroup.probePositions = _lightProbes.ToArray();
			}

			RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Skybox;
			RenderSettings.ambientIntensity = 1.5f;
			RenderSettings.ambientSkyColor = Color.white;
			RenderSettings.defaultReflectionResolution = 256;
			LightmapEditorSettings.realtimeResolution = 0.2f;
			Lightmapping.bakedGI = false;
			Lightmapping.realtimeGI = true;

			Lightmapping.completed += () =>
			{
				EditorUtility.ClearProgressBar();
				EditorApplication.isPlaying = true;
			};
		}

		[MenuItem("MGFX/PrefabViewer", false, 3003)]
		public static void MenuItem()
		{
			PrefabViewer _window = EditorWindow.CreateInstance<PrefabViewer>();
			_window.titleContent = new GUIContent("Prefab Viewer");
			_window.minSize = new Vector2(360, 240);
			_window.Show();
		}
	}
}