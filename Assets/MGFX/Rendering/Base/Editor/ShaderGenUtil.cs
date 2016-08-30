using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using DL = DotLiquid;

namespace MGFX.Rendering
{
    class CodeDRYer
    {
        private class TagUnityAsset : DL.Tag
        {
            public string m_Content;

            public override void Initialize(string _tagName, string _markup, List<string> _tokens)
            {
                base.Initialize(_tagName, _markup, _tokens);
                string _path = System.IO.Path.Combine(Application.dataPath, _markup.Trim());
                try
                {
                    using (var _f = new System.IO.StreamReader(_path))
                    {
                        m_Content = _f.ReadToEnd();
                    }
                }
                catch (Exception _err)
                {
                    Log.E(_err);
                    m_Content = null;
                }

                if (null == m_Content)
                {
                    Log.E("failed to load TextAsset {0}", _markup);
                    return;
                }
                else
                {
                    //Log.I("Loaded {0}", _markup);
                }
            }

            public override void Render(DL.Context context, System.IO.TextWriter result)
            {
                if (null != m_Content)
                    result.Write(m_Content);
                else
                    result.Write("(null)");
            }
        }

        static CodeDRYer()
        {
            DL.Template.RegisterTag<TagUnityAsset>("unityasset");
        }

        public CodeDRYer(TextAsset _asset)
        {
            CreateTemplate(_asset.text);
        }

        public CodeDRYer()
        {
            CreateTemplate("#{% unityasset Assets/MGFX/Rendering/Common/Shaders/OctEncode.cginc %}##");
        }

        private DL.Template m_Template = null;

        private void CreateTemplate(string _text)
        {
            try
            {
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


	struct ShaderGenData
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
			
			for(int _i = 0; _i < _cnt; ++_i)
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

	class ShaderGenProp : ScriptableObject
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


	class ShaderGenUtil : RenderUtils.IUtil
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
			catch(Exception)
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

		void OnGUIListFile(ShaderGenProp _data)
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

        void OnGUITemplates(ShaderGenProp _prop)
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
				else
				{
					DoTest();
				}
					
			}

			EditorGUILayout.Separator();
		}

        void OnGUIHelp()
        {
            EditorGUILayout.Separator();

            EditorGUILayout.TextArea("Templates should be named in AssetName.type.txt\n"+
                "For example:\n"+
                "MYUBER.Shader.txt -> MYUBER.shader", 
                EditorStyles.helpBox, UI.LAYOUT_DEFAULT);
            
            EditorGUILayout.Separator();
            EditorGUILayout.Separator();

            EditorGUILayout.TextArea("DO NOT REPEAT YOURSELF!\n"+
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
		
		void DoSaveListFile()
		{
			string _js = ShaderGenData.ToJson(Data);

			if (null == ListFile || !ListFile)
			{
				string _assetPath = System.IO.Path.GetDirectoryName(Data.Templates[0]) + "/ListFile.txt";
				ListFile = CreateAsset<TextAsset>(_assetPath);
			}
			
			WriteAsset(ListFile, _js);
		}

		void DoLoadListFile()
		{
			if (null == ListFile || !ListFile)
				return;

			Data = ShaderGenData.FromJson(ListFile.text);
		}

        void DoRender()
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

        void DoTest()
        {
            new CodeDRYer().Render(null);
        }
    }

}