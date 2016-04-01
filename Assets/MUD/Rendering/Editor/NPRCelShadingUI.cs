using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace Mud
{

	public class NPRCelShadingUI : ShaderGUI
	{
		MaterialEditor materialEditor;
		MaterialProperty m_MainTex;
		MaterialProperty m_NormalMapOn;
		MaterialProperty m_NormalMapTex;
		MaterialProperty m_RimOn;
		MaterialProperty m_RimSize;
		MaterialProperty m_RimIntensity;
		MaterialProperty m_OverlayOn;
		MaterialProperty m_OverlayTex;
		MaterialProperty m_DiffuseLUTOn;
		MaterialProperty m_DiffuseLUTTex;
		MaterialProperty m_EdgeStrengthCurve;
		MaterialProperty m_EdgeStrengthPlanar;
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
			//DoEdge();

			foreach (var _obj in _materialEditor.targets)
			{
				var _mtl = _obj as Material;
				//Debug.Log(_mtl.name);
				_mtl.SetOverrideTag("RenderType", "");
				_mtl.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				_mtl.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				_mtl.SetInt("_ZWrite", 1);
				_mtl.DisableKeyword("_ALPHATEST_ON");
				_mtl.DisableKeyword("_ALPHABLEND_ON");
				_mtl.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				_mtl.renderQueue = -1;
			}
			
		}

		private Material currentMaterial
		{
			get { return materialEditor.target as Material; }
		}

		private void FindProperties(MaterialProperty[] _properties)
		{
			m_MainTex = FindProperty("_MainTex", _properties);
			m_NormalMapOn = FindProperty("_NormalMapOn", _properties);
			m_NormalMapTex = FindProperty("_NormalMapTex", _properties);
			m_OverlayOn = FindProperty("_OverlayOn", _properties);
			m_OverlayTex = FindProperty("_OverlayTex", _properties);
			m_RimOn = FindProperty("_RimOn", _properties);
			m_RimSize = FindProperty("_RimSize", _properties);
			m_RimIntensity = FindProperty("_RimIntensity", _properties);
			m_DiffuseLUTOn = FindProperty("_DiffuseLUTOn", _properties);
			m_DiffuseLUTTex = FindProperty("_DiffuseLUTTex", _properties);
			m_EdgeStrengthCurve = FindProperty("_EdgeStrengthCurve", _properties);
			m_EdgeStrengthPlanar = FindProperty("_EdgeStrengthPlanar", _properties);
		}

		private void DoGeneral()
		{
			if (!BeginGroup("General"))
				return;

			materialEditor.TextureProperty(m_MainTex, "Main Texture (RGB)");

			EndGroup();
		}

		const string KEYWORD_NORMAL_MAP_ON = "_NORMAL_MAP_ON";
		const string KEYWORD_OVERLAY_ON = "_OVERLAY_ON";
		const string KEYWORD_RIM_ON = "_RIM_ON";
		const string KEYWORD_DIFFUSE_LUT_ON = "_DIFFUSE_LUT_ON";

		private void DoNormalMap()
		{
			if (!BeginGroup("Normal Map"))
				return;

			materialEditor.ShaderProperty(m_NormalMapOn, "Use Normal Map");

			bool _isOn = m_NormalMapOn.floatValue > 0;
			SetKeyword(KEYWORD_NORMAL_MAP_ON, _isOn);

			if (_isOn)
			{
				materialEditor.TextureProperty(m_NormalMapTex, "Normal Map");
			}

			EndGroup();
		}

		private void DoOverlay()
		{
			if (!BeginGroup("Overlay"))
				return;

			materialEditor.ShaderProperty(m_OverlayOn, "Use Overlay");

			bool _isOn = m_OverlayOn.floatValue > 0;
			SetKeyword(KEYWORD_OVERLAY_ON, _isOn);

			if (_isOn)
			{
				materialEditor.TextureProperty(m_OverlayTex, "Overlay Texture (RGBA)");
			}

			EndGroup();
		}

		private void DoRim()
		{
			if (!BeginGroup("Rim"))
				return;

			materialEditor.ShaderProperty(m_RimOn, "Use Rim");

			bool _isOn = m_RimOn.floatValue > 0;
			SetKeyword(KEYWORD_RIM_ON, _isOn);

			if (_isOn)
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

			materialEditor.ShaderProperty(m_DiffuseLUTOn, "Use Diffuse LUT");
			bool _isOn = m_DiffuseLUTOn.floatValue > 0;
			SetKeyword(KEYWORD_DIFFUSE_LUT_ON, _isOn);

			if (_isOn)
			{
				materialEditor.TextureProperty(m_DiffuseLUTTex, "Diffuse LUT (Grayscale)");
			}

			EndGroup();
		}

		private void DoEdge()
		{
			if (!BeginGroup("Edge"))
				return;

			materialEditor.ShaderProperty(m_EdgeStrengthCurve, "Edge Curve");
			materialEditor.ShaderProperty(m_EdgeStrengthPlanar, "Edge Planar");

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