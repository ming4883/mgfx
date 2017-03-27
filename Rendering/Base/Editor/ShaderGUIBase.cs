using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	public class ShaderGUIBase : ShaderGUI
	{
		[System.AttributeUsage (System.AttributeTargets.Field)]
		public class MaterialPropertyAttribute : System.Attribute
		{
			public string Name = null;
			public string Keyword = null;

			public MaterialPropertyAttribute (string _name)
			{
				Name = _name;
			}

			public MaterialPropertyAttribute (string _name, string _keyword)
			{
				Name = _name;
				Keyword = _keyword;
			}
		}

		public Dictionary<string, string> m_Keywords = new Dictionary<string, string>();

		protected bool DoKeyword(MaterialEditor _editor, MaterialProperty _prop, string _desc)
		{
			string _keyword;
			if (!m_Keywords.TryGetValue (_prop.name, out _keyword))
				return false;

			_editor.ShaderProperty(_prop, _desc);

			bool _on = _prop.floatValue > 0;

			if (_on)
			{
				foreach(var _tar in _editor.targets)
				{
					(_tar as Material).EnableKeyword(_keyword);
				}
			}
			else
			{
				foreach(var _tar in _editor.targets)
				{
					(_tar as Material).DisableKeyword(_keyword);
				}
			}

			return _on;
		}

		protected void SetOverrideTag(MaterialEditor _editor, string _tagName, string _tagValue)
		{
			foreach(var _tar in _editor.targets)
			{
				(_tar as Material).SetOverrideTag(_tagName, _tagValue);
			}
		}

		protected void SetRenderQueue(MaterialEditor _editor, int _queue)
		{
			foreach(var _tar in _editor.targets)
			{
				(_tar as Material).renderQueue = _queue;
			}
		}

		protected void SetInt(MaterialEditor _editor, string _propName, int _propValue)
		{
			foreach(var _tar in _editor.targets)
			{
				(_tar as Material).SetInt(_propName, _propValue);
			}
		}

		protected void SetFloat(MaterialEditor _editor, string _propName, float _propValue)
		{
			foreach(var _tar in _editor.targets)
			{
				(_tar as Material).SetFloat(_propName, _propValue);
			}
		}

		public static int FindProperties(ShaderGUIBase _inst, MaterialProperty[] _properties)
		{
			int _cnt = 0;
			var _flags = System.Reflection.BindingFlags.Instance 
				| System.Reflection.BindingFlags.NonPublic
				| System.Reflection.BindingFlags.Public;

			_inst.m_Keywords.Clear ();

			foreach (var _field in _inst.GetType ().GetFields (_flags))
			{
				foreach (var _attr in _field.GetCustomAttributes (true))
				{
					var _propAttr = _attr as MaterialPropertyAttribute;
					if (null != _propAttr && _field.FieldType == typeof(MaterialProperty))
					{
						var _prop = FindProperty (_propAttr.Name, _properties);
						if (null == _prop)
						{
							Log.E ("Material Property {0} not found!", _propAttr.Name);
							continue;
						}

						var _keyword = _propAttr.Keyword;
						if (null != _keyword)
							_inst.m_Keywords.Add (_prop.name, _keyword);

						_field.SetValue (_inst, _prop);

						++_cnt;
					}
				}
			}
			return _cnt;
		}

		private Dictionary<string, bool> m_GroupToggles = new  Dictionary<string, bool>();

		protected bool BeginGroup(string _name)
		{
			bool _toggled;
			if (!m_GroupToggles.TryGetValue(_name, out _toggled))
				_toggled = true;

			_toggled = EditorGUILayout.Foldout(_toggled, _name);
			m_GroupToggles[_name] = _toggled;
			//EditorGUILayout.HelpBox(_name, MessageType.None);
			EditorGUI.indentLevel++;
			if (!_toggled)
			{
				EndGroup();
			}
			return _toggled;
		}

		protected void EndGroup()
		{
			//GUILayout.Box(GUIContent.none, GUILayout.ExpandWidth(true), GUILayout.Height(1.0f));
			EditorGUI.indentLevel--;
			//EditorGUILayout.Space();
			//EditorGUILayout.EndToggleGroup();
		}
	}
}