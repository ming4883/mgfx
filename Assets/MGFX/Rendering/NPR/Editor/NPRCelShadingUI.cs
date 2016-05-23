using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX
{

	public class NPRCelShadingUI : ShaderGUI
	{
		MaterialEditor materialEditor;
		MaterialProperty m_MainTex;
		MaterialProperty m_DimOn;
		MaterialProperty m_DimTex;
		MaterialProperty m_NormalMapOn;
		MaterialProperty m_NormalMapTex;
		MaterialProperty m_RimOn;
		MaterialProperty m_RimSize;
		MaterialProperty m_RimIntensity;
		MaterialProperty m_OverlayOn;
		MaterialProperty m_OverlayTex;
		MaterialProperty m_DiffuseLUTOn;
		MaterialProperty m_DiffuseLUTTex;
		MaterialProperty m_EdgeOn;
		MaterialProperty m_EdgeColor;
		MaterialProperty m_EdgeAutoColor;
		MaterialProperty m_EdgeAutoColorFactor;
		MaterialProperty m_SsaoOn;
		MaterialProperty m_SsaoShapness;


		const string KEYWORD_DIM_ON = "_DIM_ON";
		const string KEYWORD_NORMAL_MAP_ON = "_NORMAL_MAP_ON";
		const string KEYWORD_OVERLAY_ON = "_OVERLAY_ON";
		const string KEYWORD_RIM_ON = "_RIM_ON";
		const string KEYWORD_DIFFUSE_LUT_ON = "_DIFFUSE_LUT_ON";
		const string KEYWORD_EDGE = "_EDGE_ON";
		const string KEYWORD_SSAO = "_SSAO_ON";


		public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
		{
			//base.OnGUI(_materialEditor, _properties);
			materialEditor = _materialEditor;
			FindProperties(_properties);

			DoGeneral();
			DoNormalMap();
			DoOverlay();
			DoRim();
			DoDiffuseLUT();
			DoEdge();
			DoSSAO ();
		}

		private Material currentMaterial
		{
			get { return materialEditor.target as Material; }
		}

		private void FindProperties(MaterialProperty[] _properties)
		{
			m_MainTex = FindProperty("_MainTex", _properties);
			m_DimOn = FindProperty("_DimOn", _properties);
			m_DimTex = FindProperty("_DimTex", _properties);
			m_NormalMapOn = FindProperty("_NormalMapOn", _properties);
			m_NormalMapTex = FindProperty("_NormalMapTex", _properties);
			m_OverlayOn = FindProperty("_OverlayOn", _properties);
			m_OverlayTex = FindProperty("_OverlayTex", _properties);
			m_RimOn = FindProperty("_RimOn", _properties);
			m_RimSize = FindProperty("_RimSize", _properties);
			m_RimIntensity = FindProperty("_RimIntensity", _properties);
			m_DiffuseLUTOn = FindProperty("_DiffuseLUTOn", _properties);
			m_DiffuseLUTTex = FindProperty("_DiffuseLUTTex", _properties);
			m_EdgeOn = FindProperty("_EdgeOn", _properties);
			m_EdgeColor = FindProperty("_EdgeColor", _properties);
			m_EdgeAutoColor = FindProperty("_EdgeAutoColor", _properties);
			m_EdgeAutoColorFactor = FindProperty("_EdgeAutoColorFactor", _properties);
			m_SsaoOn = FindProperty("_SsaoOn", _properties);
			m_SsaoShapness = FindProperty ("_SsaoShapness", _properties);
		}

		private bool Keyword(MaterialProperty _prop, string _desc, string _keyword)
		{
			materialEditor.ShaderProperty(_prop, _desc);
			bool _on = _prop.floatValue > 0;
			SetKeyword (_keyword, _on);
			return _on;
		}

		private void DoGeneral()
		{
			if (!BeginGroup("General"))
				return;

			materialEditor.TextureProperty(m_MainTex, "Main Texture (RGB)");

			if (Keyword (m_DimOn, "Use Dim Texture", KEYWORD_DIM_ON))
			{
				materialEditor.TextureProperty (m_DimTex, "Dim Texture (RGB)");
			}

			EndGroup();
		}

		private void DoNormalMap()
		{
			if (!BeginGroup("Normal Map"))
				return;
			
			if (Keyword(m_NormalMapOn, "Use Normal Map", KEYWORD_NORMAL_MAP_ON))
			{
				materialEditor.TextureProperty(m_NormalMapTex, "Normal Map");
			}

			EndGroup();
		}

		private void DoOverlay()
		{
			if (!BeginGroup("Overlay"))
				return;
			
			if (Keyword(m_OverlayOn, "Use Overlay Texture", KEYWORD_OVERLAY_ON))
			{
				materialEditor.TextureProperty(m_OverlayTex, "Overlay Texture (RGBA)");
			}

			EndGroup();
		}

		private void DoRim()
		{
			if (!BeginGroup("Rim"))
				return;
			
			if (Keyword(m_RimOn, "Use Rim", KEYWORD_RIM_ON))
			{
				materialEditor.ShaderProperty(m_RimSize, "Rim Size");
				materialEditor.ShaderProperty(m_RimIntensity, "Rim Intensity");
			}

			EndGroup();
		}

		private void DoDiffuseLUT()
		{
			if (!BeginGroup("Diffuse LUT"))
				return;
			
			if (Keyword(m_DiffuseLUTOn, "Use Diffuse LUT", KEYWORD_DIFFUSE_LUT_ON))
			{
				materialEditor.TextureProperty(m_DiffuseLUTTex, "Diffuse LUT (Grayscale)");
			}

			EndGroup();
		}

		private void DoEdge()
		{
			if (!BeginGroup("Edge"))
				return;

			if (Keyword (m_EdgeOn, "Use Edges", KEYWORD_EDGE))
			{
				materialEditor.ShaderProperty (m_EdgeColor, "Edge Color");
				materialEditor.ShaderProperty (m_EdgeAutoColor, "Edge Auto Color");
				materialEditor.ShaderProperty (m_EdgeAutoColorFactor, "Edge Auto Color Factor");
			}

			EndGroup();
		}

		private void DoSSAO()
		{
			if (!BeginGroup("SSAO"))
				return;

			if (Keyword (m_SsaoOn, "Use SSAO", KEYWORD_SSAO))
			{
				materialEditor.ShaderProperty (m_SsaoShapness, "SSAO Shapness");
			}

			EndGroup();
		}

		private void SetKeyword(string _keyword, bool _enabled)
		{
			if (_enabled)
			{
				currentMaterial.EnableKeyword(_keyword);
			}
			else
			{
				currentMaterial.DisableKeyword(_keyword);
			}
		}

		//private Dictionary<string, bool> m_groups = new Dictionary<string,bool>();

		private bool BeginGroup(string _name)
		{
			/*
			if (!m_groups.ContainsKey(_name))
				m_groups.Add(_name, true);

			m_groups[_name] = EditorGUILayout.Foldout(m_groups[_name], _name, EditorStyles.helpBox);

			return m_groups[_name];
			*/
			return true;
		}

		private void EndGroup()
		{
			EditorGUILayout.Space();
		}

	}
}