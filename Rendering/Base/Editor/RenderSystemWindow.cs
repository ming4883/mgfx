using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	internal class RenderSystemWindow : EditorWindow
	{
		private Vector2 m_ScrollPos = Vector2.zero;
		private List<bool> m_Toggle = new List<bool>();

		private bool m_BakingToggle = true;
		private bool m_RenderSystemToggle = true;

		//GUIContent m_txtUseLinear = new GUIContent("Use Linear Color Space");
		private string kColorSpaceWarningString = "This project is using Gamma color space, please consider switching to Linear color space";

		private ColorPickerHDRConfig kHdrConfig = new ColorPickerHDRConfig(0, 5, 0, 2);

		public static readonly GUIContent[] kAmbientModeStrings = new GUIContent[]
		{
			new GUIContent("Skybox"),
			new GUIContent("Gradient"),
			new GUIContent("Color")
		};

		public static readonly int[] kAmbientModeValues = new int[]
		{
			0,
			1,
			3
		};

		private GUIContent[] kMaxAtlasSizeStrings = new GUIContent[]
		{
			new GUIContent("32"),
			new GUIContent("64"),
			new GUIContent("128"),
			new GUIContent("256"),
			new GUIContent("512"),
			new GUIContent("1024"),
			new GUIContent("2048"),
			new GUIContent("4096")
		};

		private int[] kMaxAtlasSizeValues = new int[]
		{
			32,
			64,
			128,
			256,
			512,
			1024,
			2048,
			4096
		};

		private GUIContent[] kBakeModeStrings = new GUIContent[]
		{
			new GUIContent("Non-Directional"),
			new GUIContent("Directional"),
		};

		private int[] kBakeModeValues = new int[]
		{
			0,
			1,
		};

		public GUIContent[] kRuntimeCPUUsageStrings = new GUIContent[]
		{
			new GUIContent("Low (default)"),
			new GUIContent("Medium"),
			new GUIContent("High"),
			new GUIContent("Unlimited")
		};

		public int[] kRuntimeCPUUsageValues = new int[]
		{
			25,
			50,
			75,
			100
		};

		private void OnEnable()
		{
		}

		private void OnDisable()
		{
		}

		private void OnInspectorUpdate()
		{
			Repaint();
		}

		private void Line()
		{
			GUILayout.Box(GUIContent.none, GUILayout.ExpandWidth(true), GUILayout.Height(1.0f));
		}

		private bool Toggle(SerializedProperty _spBool, GUIContent _label)
		{
			bool _boolValue = _spBool.boolValue;
			EditorGUI.BeginChangeCheck();

			_boolValue = EditorGUILayout.ToggleLeft(_label, _boolValue);
			if (EditorGUI.EndChangeCheck())
			{
				_spBool.boolValue = _boolValue;
			}

			return _boolValue;
		}

		private void OnGUIRenderSystem()
		{
			var _renderSys = GameObject.FindObjectOfType<RenderSystem>();

			if (null == _renderSys || !_renderSys)
			{
				EditorGUILayout.HelpBox("RenderSystem not found!", MessageType.Warning);
				return;
			}
			else
			{
				if (m_RenderSystemToggle = EditorGUILayout.BeginToggleGroup("RenderSystem", m_RenderSystemToggle))
				{
					EditorGUI.indentLevel += 1;

					var _syseditor = Editor.CreateEditor(_renderSys);
					_syseditor.OnInspectorGUI();
					DestroyImmediate(_syseditor);

					EditorGUI.indentLevel -= 1;
				}

				EditorGUILayout.EndToggleGroup();
				Line();

				var _features = _renderSys.GetComponentsInChildren<RenderFeatureBase>();
				if (m_Toggle.Count < _features.Length)
				{
					var _next = new List<bool>(_features.Length);
					_next.AddRange(m_Toggle);
					for (int _it = m_Toggle.Count; _it < _features.Length; ++_it)
						_next.Add(_features[_it].enabled);
					m_Toggle = _next;
				}

				if (_features.Length == 0)
					return;

				for (int _it = 0; _it < _features.Length; ++_it)
				{
					var _f = _features[_it];

					// toggle group
					m_Toggle[_it] = EditorGUILayout.BeginToggleGroup(_f.GetType().Name, m_Toggle[_it]);

					if (m_Toggle[_it])
					{
						EditorGUI.indentLevel += 1;
						EditorGUI.BeginDisabledGroup(!_f.enabled);
						var _feditor = Editor.CreateEditor(_f);
						_feditor.OnInspectorGUI();
						EditorGUI.EndDisabledGroup();
						DestroyImmediate(_feditor);

						EditorGUI.indentLevel -= 1;
					}

					EditorGUILayout.EndToggleGroup();
					// separator
					Line();
				}
			}
		}

		private static SerializedObject GetLighmapSettings()
		{
			var _method = typeof(LightmapEditorSettings).GetMethod("GetLightmapSettings", BindingFlags.Static | BindingFlags.NonPublic);
			var _inst = _method.Invoke(null, null) as UnityEngine.Object;
			return new SerializedObject(_inst);
		}

		private static SerializedObject GetRenderSettings()
		{
			var _method = typeof(RenderSettings).GetMethod("GetRenderSettings", BindingFlags.Static | BindingFlags.NonPublic);
			var _inst = _method.Invoke(null, null) as UnityEngine.Object;
			return new SerializedObject(_inst);
		}

		private void OnGUILighting()
		{
			if (m_BakingToggle = EditorGUILayout.BeginToggleGroup("Lighting And Baking", m_BakingToggle))
			{
				EditorGUI.indentLevel++;

				if (PlayerSettings.colorSpace != ColorSpace.Linear)
				{
					EditorGUILayout.HelpBox("Color Space", MessageType.None);

					EditorGUILayout.HelpBox(kColorSpaceWarningString, MessageType.Warning);

					if (GUILayout.Button("Fix color space Settings"))
					{
						EditorApplication.ExecuteMenuItem("Edit/Project Settings/Player");
					}
				}

				EditorGUILayout.Separator();

				SerializedObject _soRend = GetRenderSettings();

				//
				EditorGUILayout.HelpBox("Lighting", MessageType.None);
				SerializedProperty _spAmbientSkyColor = _soRend.FindProperty("m_AmbientSkyColor");
				SerializedProperty _spAmbientIntensity = _soRend.FindProperty("m_AmbientIntensity");
				SerializedProperty _spAmbientMode = _soRend.FindProperty("m_AmbientMode");
				SerializedProperty _spSkybox = _soRend.FindProperty("m_SkyboxMaterial");

				EditorGUI.BeginChangeCheck();
				var _skyColor = EditorGUILayout.ColorField(new GUIContent("Ambient color"), _spAmbientSkyColor.colorValue, true, false, true, kHdrConfig);
				if (EditorGUI.EndChangeCheck())
				{
					_spAmbientSkyColor.colorValue = _skyColor;
				}

				EditorGUILayout.IntPopup(_spAmbientMode, kAmbientModeStrings, kAmbientModeValues, new GUIContent("Ambient Source"));

				EditorGUILayout.Slider(_spAmbientIntensity, 0f, 8f, new GUIContent("Ambient intensity"));

				EditorGUILayout.PropertyField(_spSkybox, new GUIContent("Skybox Material"));

				EditorGUILayout.Separator();

				SerializedObject _soLmap = GetLighmapSettings();

				SerializedProperty _spRealTime = _soLmap.FindProperty("m_GISettings.m_EnableRealtimeLightmaps");
				SerializedProperty _spBaked = _soLmap.FindProperty("m_GISettings.m_EnableBakedLightmaps");

				if (Toggle(_spRealTime, new GUIContent("Pre-Realtime GI")))
				{
					EditorGUI.indentLevel++;

					SerializedProperty _spResolution = _soLmap.FindProperty("m_LightmapEditorSettings.m_Resolution");

					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(_spResolution, new GUIContent("Realtime Resolution"));
					EditorGUILayout.LabelField("texels per unit");
					EditorGUILayout.EndHorizontal();

					SerializedProperty _spCPU = _soLmap.FindProperty("m_RuntimeCPUUsage");
					EditorGUILayout.IntPopup(_spCPU, kRuntimeCPUUsageStrings, kRuntimeCPUUsageValues, new GUIContent("CPU Usage"));

					EditorGUILayout.Separator();

					EditorGUI.indentLevel--;
				}

				if (Toggle(_spBaked, new GUIContent("Baked GI")))
				{
					EditorGUI.indentLevel++;

					EditorGUI.BeginDisabledGroup(Lightmapping.isRunning);

					SerializedProperty _spBakeMode = _soLmap.FindProperty("m_LightmapEditorSettings.m_LightmapsBakeMode");
					SerializedProperty _spCompress = _soLmap.FindProperty("m_LightmapEditorSettings.m_TextureCompression");

					EditorGUILayout.IntPopup(_spBakeMode, kBakeModeStrings, kBakeModeValues, new GUIContent("Baking Mode"));
					EditorGUILayout.PropertyField(_spCompress, new GUIContent("Compressed"));

					EditorGUILayout.Separator();

					SerializedProperty _spDirectRes = _soLmap.FindProperty("m_LightmapEditorSettings.m_BakeResolution");
					SerializedProperty _spIndirectRes = _soLmap.FindProperty("m_LightmapEditorSettings.m_Resolution");
					SerializedProperty _spPadding = _soLmap.FindProperty("m_LightmapEditorSettings.m_Padding");
					SerializedProperty _spAtlasSize = _soLmap.FindProperty("m_LightmapEditorSettings.m_TextureWidth");

					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(_spDirectRes, new GUIContent("Direct Resolution"));
					EditorGUILayout.LabelField("texels per unit");
					EditorGUILayout.EndHorizontal();

					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(_spIndirectRes, new GUIContent("Indirect Resolution"));
					EditorGUILayout.LabelField("texels per unit");
					EditorGUILayout.EndHorizontal();

					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(_spPadding, new GUIContent("Padding"));
					EditorGUILayout.LabelField("texels");
					EditorGUILayout.EndHorizontal();

					EditorGUILayout.IntPopup(
						_spAtlasSize,
						kMaxAtlasSizeStrings,
						kMaxAtlasSizeValues,
						new GUIContent("Atlas Size"));

					//LightmapEditorSettings.maxAtlasHeight = LightmapEditorSettings.maxAtlasWidth;

					EditorGUILayout.Separator();

					SerializedProperty _spAO = _soLmap.FindProperty("m_LightmapEditorSettings.m_AO");
					SerializedProperty _spAODist = _soLmap.FindProperty("m_LightmapEditorSettings.m_AOMaxDistance");
					SerializedProperty _spAOExpIndirect = _soLmap.FindProperty("m_LightmapEditorSettings.m_CompAOExponent");
					SerializedProperty _spAOExpDirect = _soLmap.FindProperty("m_LightmapEditorSettings.m_CompAOExponentDirect");

					if (Toggle(_spAO, new GUIContent("Ambient Occlusion")))
					{
						EditorGUI.indentLevel++;
						EditorGUILayout.PropertyField(_spAODist, new GUIContent("Max Distance"));
						EditorGUILayout.Slider(_spAOExpIndirect, 0, 10, new GUIContent("Indirect"));
						EditorGUILayout.Slider(_spAOExpDirect, 0, 10, new GUIContent("Direct"));
						EditorGUI.indentLevel--;
					}

					EditorGUILayout.Separator();

					SerializedProperty _spFinalGather = _soLmap.FindProperty("m_LightmapEditorSettings.m_FinalGather");
					SerializedProperty _spFinalGatherRayCnt = _soLmap.FindProperty("m_LightmapEditorSettings.m_FinalGatherRayCount");
					SerializedProperty _spFinalGatherFilter = _soLmap.FindProperty("m_LightmapEditorSettings.m_FinalGatherFiltering");

					if (Toggle(_spFinalGather, new GUIContent("Final Gather")))
					{
						EditorGUI.indentLevel++;
						EditorGUILayout.PropertyField(_spFinalGatherRayCnt, new GUIContent("Ray Count"));
						EditorGUILayout.PropertyField(_spFinalGatherFilter, new GUIContent("Filter"));
						EditorGUI.indentLevel--;
					}

					EditorGUI.indentLevel--;
				}

				SerializedProperty _spAlbedoBoost = _soLmap.FindProperty("m_GISettings.m_AlbedoBoost");
				SerializedProperty _spIndirectOuputScale = _soLmap.FindProperty("m_GISettings.m_IndirectOutputScale");
				SerializedProperty _spParams = _soLmap.FindProperty("m_LightmapEditorSettings.m_LightmapParameters");

				EditorGUILayout.Slider(_spAlbedoBoost, 1, 10, new GUIContent("Bounce Boost"));
				EditorGUILayout.Slider(_spIndirectOuputScale, 0, 5, new GUIContent("Indirect Intensity"));
				EditorGUILayout.PropertyField(_spParams, new GUIContent("Default Parameters"));

				_soLmap.ApplyModifiedProperties();
				_soRend.ApplyModifiedProperties();

				EditorGUILayout.Separator();
				EditorGUILayout.Separator();

				if (GUILayout.Button("Bake All"))
				{
					Lightmapping.BakeAsync();
				}

				if (GUILayout.Button("Bake (Preview)"))
				{
					m_LastDirRes = LightmapEditorSettings.bakeResolution;
					m_LasrIndRes = LightmapEditorSettings.realtimeResolution;

					LightmapEditorSettings.bakeResolution = m_LastDirRes * 0.5f;
					LightmapEditorSettings.realtimeResolution = m_LasrIndRes * 0.5f;

					Lightmapping.completed += OnBakeCompleted;

					Lightmapping.BakeAsync();
				}

				if (GUILayout.Button("Bake Light Probes Only"))
				{
					Lightmapping.BakeAsync();
				}

				EditorGUI.EndDisabledGroup();

				EditorGUI.BeginDisabledGroup(!Lightmapping.isRunning);

				if (GUILayout.Button("Cancel"))
				{
					Lightmapping.Cancel();
				}

				EditorGUI.EndDisabledGroup();

				EditorGUILayout.Separator();
				EditorGUILayout.Separator();

				EditorGUI.indentLevel--;
			}

			EditorGUILayout.EndToggleGroup();
			Line();
		}

		private float m_LastDirRes;
		private float m_LasrIndRes;

		private void OnBakeCompleted()
		{
			LightmapEditorSettings.bakeResolution = m_LastDirRes;
			LightmapEditorSettings.realtimeResolution = m_LasrIndRes;

			Lightmapping.completed -= OnBakeCompleted;

			Log.I("Settings Restored.");
		}

		private void OnGUI()
		{
			m_ScrollPos = EditorGUILayout.BeginScrollView(m_ScrollPos);

			OnGUILighting();
			OnGUIRenderSystem();

			EditorGUILayout.EndScrollView();
		}

		[MenuItem("MGFX/RenderSystem", false, 3001)]
		public static void MenuItem()
		{
			RenderSystemWindow _window = EditorWindow.CreateInstance<RenderSystemWindow>();
			_window.titleContent = new GUIContent("RenderSystem");
			_window.minSize = new Vector2(350, 500);
			_window.Show();
		}
	}
}