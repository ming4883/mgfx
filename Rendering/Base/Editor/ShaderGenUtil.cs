using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using DL = DotLiquid;

namespace MGFX.Rendering
{
	internal class CodeDRYer
	{
		private class TagUnityAsset : DL.Tag
		{
			public string m_Content;
			public DL.Template m_Template;

			public static string WorkingDir = "";

			public override void Initialize(string _tagName, string _markup, List<string> _tokens)
			{
				base.Initialize(_tagName, _markup, _tokens);
				string _path = _markup.Trim();

				if (_path.StartsWith("."))
				{
					_path = System.IO.Path.Combine(WorkingDir, _path);
					_path = System.IO.Path.GetFullPath(_path);
				}
				else
				{
					_path = System.IO.Path.Combine(Application.dataPath, _path);
				}

				ReadContentFromPath(_path);

				if (null == m_Content)
				{
					Log.E("Failed to load TagUnityAsset {0}", _markup);
					return;
				}
				else
				{
					//Log.I("Loaded {0}", _markup);
				}
			}

			public override void Render(DL.Context _context, System.IO.TextWriter _result)
			{
				if (null != m_Template)
				{
					try
					{
						var _renderParams = DL.RenderParameters.FromContext(_context);
						_result.Write(m_Template.Render(_renderParams));
					}
					catch(Exception _err)
					{
						Log.E(_err);
						_result.Write("(error)");
					}
				}
				else if (null != m_Content)
				{
					_result.Write(m_Content);
				}
				else
				{
					_result.Write("(null)");
				}
			}

			private void ReadContentFromPath(string _path)
			{
				try
				{
					using (var _f = new System.IO.StreamReader(_path))
					{
						m_Content = _f.ReadToEnd();

						if (m_Content.Contains("{%") || m_Content.Contains("{{"))
						{
							//Log.I("Processing Template " + _path);
							// Backup WorkingDir
							string _lastWorkDir = TagUnityAsset.WorkingDir;

							// Modify the WorkingDir
							TagUnityAsset.WorkingDir = System.IO.Path.GetDirectoryName(_path);

							try
							{
								m_Template = DL.Template.Parse(m_Content);
							}
							catch(Exception _errTemplate)
							{
								Log.E(_errTemplate);
								m_Content = null;
							}
							
							// Restore WorkingDir
							TagUnityAsset.WorkingDir = _lastWorkDir;
						}
					}
				}
				catch (Exception _err)
				{
					Log.E(_err);
					m_Content = null;
				}
			}
		}

		static CodeDRYer()
		{
			DL.Template.RegisterTag<TagUnityAsset>("unityasset");
		}

		public CodeDRYer(TextAsset _asset)
		{
			var _workdir = AssetDatabase.GetAssetPath(_asset).Remove(0, 6); // "Remove 'Assets'"
			_workdir = System.IO.Path.GetFullPath(Application.dataPath + _workdir);
			_workdir = System.IO.Path.GetDirectoryName(_workdir);
			CreateTemplate(_asset.text, _workdir);
		}
		
		private DL.Template m_Template = null;

		private void CreateTemplate(string _text, string _workingDir)
		{
			try
			{
				//Log.I("working dir {0}", _workingDir);
				TagUnityAsset.WorkingDir = _workingDir;

				var _template = DL.Template.Parse(_text);
				m_Template = _template;
			}
			catch (Exception _err)
			{
				Log.E(_err);
			}
		}

		public bool Render(string _outputPath)
		{
			if (null == m_Template)
				return false;

			var _ret = m_Template.Render();

			if (null == _outputPath)
			{
				Log.I(_ret);
			}
			else
			{
				try
				{
					using (var _f = new System.IO.StreamWriter(_outputPath))
					{
						_f.Write(_ret);
					}
				}
				catch (Exception _err)
				{
					Log.E(_err);
					return false;
				}
			}

			return true;
		}
	}

	internal struct ShaderGenData
	{
		public string[] Templates;

		public static string ToJson(ShaderGenData _io)
		{
			return JsonUtility.ToJson(_io);
		}

		public static ShaderGenData FromJson(string _js)
		{
			return JsonUtility.FromJson<ShaderGenData>(_js);
		}

		public void SetTemplates(TextAsset[] _templates)
		{
			int _cnt = _templates == null ? 0 : _templates.Length;

			Templates = new string[_cnt];

			for (int _i = 0; _i < _cnt; ++_i)
			{
				Templates[_i] = AssetDatabase.GetAssetPath(_templates[_i]);
			}
		}

		public TextAsset[] GetTemplates()
		{
			int _cnt = Templates == null ? 0 : Templates.Length;

			TextAsset[] _templates = new TextAsset[_cnt];

			for (int _i = 0; _i < _cnt; ++_i)
			{
				_templates[_i] = AssetDatabase.LoadAssetAtPath<TextAsset>(Templates[_i]);
			}

			return _templates;
		}
	}

	internal class ShaderGenProp : ScriptableObject
	{
		public TextAsset[] LastAssets = new TextAsset[] { null };

		public void CopyFrom(ref ShaderGenData _data)
		{
			this.LastAssets = _data.GetTemplates();
		}

		public void CopyTo(ref ShaderGenData _data)
		{
			_data.SetTemplates(this.LastAssets);
		}

		public static ShaderGenProp Acquire()
		{
			return CreateInstance<ShaderGenProp>();
		}

		public static void Release(ShaderGenProp _data)
		{
			DestroyImmediate(_data);
		}
	}

	internal class ShaderGenUtil : RenderUtils.IUtil
	{
		public ShaderGenData Data = new ShaderGenData();
		public TextAsset ListFile = null;

		public override string Name()
		{
			return "Shader Generator";
		}

		public override void OnEnable()
		{
			try
			{
				Data = ShaderGenData.FromJson(LoadSettings());
			}
			catch (Exception)
			{
			}
		}

		public override void OnDisable()
		{
			SaveSettings(ShaderGenData.ToJson(Data));
		}

		public override void OnGUI()
		{
			ShaderGenProp _prop = ShaderGenProp.Acquire();
			_prop.CopyFrom(ref Data);

			OnGUIListFile(_prop);

			OnGUITemplates(_prop);

			OnGUIHelp();

			ShaderGenProp.Release(_prop);
		}

		private void OnGUIListFile(ShaderGenProp _data)
		{
			EditorGUILayout.Separator();

			EditorGUILayout.BeginHorizontal();

			EditorGUI.BeginChangeCheck();

			ListFile = EditorGUILayout.ObjectField("ListFile.txt", ListFile, typeof(TextAsset), false) as TextAsset;

			if (EditorGUI.EndChangeCheck())
			{
				DoLoadListFile();
			}

			if (GUILayout.Button("Clear", GUILayout.Width(50)))
			{
				ListFile = null;
				Data.Templates = new string[1];
			}

			EditorGUILayout.EndHorizontal();
		}

		private void OnGUITemplates(ShaderGenProp _prop)
		{
			EditorGUILayout.Separator();

			var _ser = new SerializedObject(_prop);
			var _field = _ser.FindProperty("LastAssets");
			if (null != _field)
			{
				EditorGUI.BeginChangeCheck();
				EditorGUILayout.PropertyField(_field, new GUIContent("Templates"), true, UI.LAYOUT_DEFAULT);
				if (_ser.ApplyModifiedProperties())
				{
					_prop.CopyTo(ref Data);
				}
			}

			EditorGUILayout.Separator();

			if (GUILayout.Button("Render", UI.LAYOUT_DEFAULT))
			{
				UI.ClearConsole();
				if (Data.Templates.Length > 0 && Data.Templates[0] != null)
				{
					DoRender();
					DoSaveListFile();
				}
			}

			EditorGUILayout.Separator();
		}

		private void OnGUIHelp()
		{
			EditorGUILayout.Separator();

			EditorGUILayout.TextArea("Templates should be named in AssetName.type.txt\n" +
				"For example:\n" +
				"MYUBER.Shader.txt -> MYUBER.shader",
				EditorStyles.helpBox, UI.LAYOUT_DEFAULT);

			EditorGUILayout.Separator();
			EditorGUILayout.Separator();

			EditorGUILayout.TextArea("DO NOT REPEAT YOURSELF!\n" +
				"CodeDRYer use the DotLiquid template engine.\n" +
				"For more information, click the following buttons.",
				EditorStyles.helpBox, UI.LAYOUT_DEFAULT);

			if (GUILayout.Button("DotLiquid References", UI.LAYOUT_DEFAULT))
			{
				Application.OpenURL("https://github.com/dotliquid/dotliquid");
			}
			if (GUILayout.Button("Liquid References", UI.LAYOUT_DEFAULT))
			{
				Application.OpenURL("https://github.com/Shopify/liquid/wiki/Liquid-for-Designers");
			}

			EditorGUILayout.Separator();
		}

		private void DoSaveListFile()
		{
			string _js = ShaderGenData.ToJson(Data);

			if (null == ListFile || !ListFile)
			{
				string _assetPath = System.IO.Path.GetDirectoryName(Data.Templates[0]) + "/ListFile.txt";
				ListFile = CreateAsset<TextAsset>(_assetPath);
			}

			WriteAsset(ListFile, _js);
		}

		private void DoLoadListFile()
		{
			if (null == ListFile || !ListFile)
				return;

			Data = ShaderGenData.FromJson(ListFile.text);
		}

		private void DoRender()
		{
			List<string> _refresh = new List<string>();
			foreach (var _template in Data.Templates)
			{
				string _path = System.IO.Path.ChangeExtension(_template, null);
				string _ext = System.IO.Path.GetExtension(_path);
				//Log.I("p:{0}, e:{1}", _path, _ext);

				if (_ext.CompareTo(_path) != 0)
					_path = System.IO.Path.ChangeExtension(_path, _ext.ToLower());

				TextAsset _asset = AssetDatabase.LoadAssetAtPath<TextAsset>(_template);
				if (new CodeDRYer(_asset).Render(_path))
				{
					Log.I("Rendered to {0}", _path);
					_refresh.Add(_path);
				}
			}

			EditorUtility.DisplayDialog(GetType().Name, string.Format("Rendered {0} assets, press OK to refresh.", _refresh.Count), "OK");

			foreach (var _path in _refresh)
			{
				AssetDatabase.ImportAsset(_path);
			}
		}
	}
}