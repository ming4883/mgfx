using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
using DL = DotLiquid;

namespace MGFX
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
                    Log.E("failed to load TextAsset {0}", _path);
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

    class CodeDRYerWindow : EditorWindow
    {
        [MenuItem("Window/MGFX/CodeDRYer", false, 1000)]
        public static void MenuItem()
        {
            CodeDRYerWindow _window = EditorWindow.CreateInstance <CodeDRYerWindow>();
            _window.titleContent = new GUIContent("CodeDRYer");
            _window.minSize = new Vector2(450, 180);
            _window.ShowUtility();
        }

        public TextAsset[] m_LastAssets = new TextAsset[]{ null };

        void OnGUI()
        {
            OnGUITemplates();

            OnGUIHelp();
        }

        void OnGUITemplates()
        {
            EditorGUILayout.Separator();

            var _ser = new SerializedObject(this);
            var _prop = _ser.FindProperty("m_LastAssets");
            if (null != _prop)
            {
                EditorGUILayout.PropertyField(_prop, new GUIContent("Templates"), true, UI.LAYOUT_DEFAULT);
                _ser.ApplyModifiedProperties();
            }

            EditorGUILayout.Separator();
            if (GUILayout.Button("Render", UI.LAYOUT_DEFAULT))
            {
                UI.ClearConsole();
                if (m_LastAssets.Length > 0 && m_LastAssets[0] != null)
                    DoRender();
                else
                    DoTest();
            }

            EditorGUILayout.Separator();
        }

        void OnGUIHelp()
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

        void DoRender()
        {
            List<string> _refresh = new List<string>();
            foreach (var _asset in m_LastAssets)
            {
                string _path = AssetDatabase.GetAssetPath(_asset);
                _path = System.IO.Path.ChangeExtension(_path, null);
                string _ext = System.IO.Path.GetExtension(_path);
                //Log.I("p:{0}, e:{1}", _path, _ext);

                if (_ext.CompareTo(_path) != 0)
                    _path = System.IO.Path.ChangeExtension(_path, _ext.ToLower());
                
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