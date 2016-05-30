using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX
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

			var _mtl = _editor.target as Material;

			if (_on)
				_mtl.EnableKeyword(_keyword);
			else
				_mtl.DisableKeyword(_keyword);

			return _on;
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

		//private Dictionary<string, bool> m_groups = new Dictionary<string,bool>();

		protected bool BeginGroup(string _name)
		{
			/*
			if (!m_groups.ContainsKey(_name))
				m_groups.Add(_name, true);

			m_groups[_name] = EditorGUILayout.Foldout(m_groups[_name], _name, EditorStyles.helpBox);

			return m_groups[_name];
			*/
			return true;
		}

		protected void EndGroup()
		{
			EditorGUILayout.Space();
		}
	}
}