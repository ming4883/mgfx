using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX
{

    public class NPRCelShading2UI : ShaderGUIBase
	{
		[MaterialProperty("_MainTex")]
		MaterialProperty m_MainTex;

        [MaterialProperty("_FadeOut")]
        MaterialProperty m_FadeOut;

        [MaterialProperty("_BayerTex")]
        MaterialProperty m_BayerTex;

		[MaterialProperty("_DimOn", "_DIM_ON")]
		MaterialProperty m_DimOn;

		[MaterialProperty("_DimTex")]
		MaterialProperty m_DimTex;

		[MaterialProperty("_NormalMapOn", "_NORMAL_MAP_ON")]
		MaterialProperty m_NormalMapOn;

		[MaterialProperty("_NormalMapTex")]
		MaterialProperty m_NormalMapTex;

		[MaterialProperty("_RimOn", "_RIM_ON")]
		MaterialProperty m_RimOn;

        [MaterialProperty("_RimLUTTex")]
        MaterialProperty m_RimLUTTex;

		[MaterialProperty("_RimIntensity")]
		MaterialProperty m_RimIntensity;

		[MaterialProperty("_OverlayOn", "_OVERLAY_ON")]
		MaterialProperty m_OverlayOn;

		[MaterialProperty("_OverlayTex")]
		MaterialProperty m_OverlayTex;

		[MaterialProperty("_DiffuseLUTOn", "_DIFFUSE_LUT_ON")]
		MaterialProperty m_DiffuseLUTOn;

		[MaterialProperty("_DiffuseLUTTex")]
		MaterialProperty m_DiffuseLUTTex;

        [MaterialProperty("_EdgeOn", "_EDGE_ON")]
		MaterialProperty m_EdgeOn;

		[MaterialProperty("_EdgeColor")]
		MaterialProperty m_EdgeColor;

		[MaterialProperty("_EdgeAutoColor")]
		MaterialProperty m_EdgeAutoColor;

		[MaterialProperty("_EdgeAutoColorFactor")]
		MaterialProperty m_EdgeAutoColorFactor;

        /*
		[MaterialProperty("_SsaoOn", "_SSAO_ON")]
		MaterialProperty m_SsaoOn;

		[MaterialProperty("_SsaoShapness")]
		MaterialProperty m_SsaoShapness;
        */

		public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
		{
			FindProperties(this, _properties);

			DoGeneral(_materialEditor);
			DoNormalMap(_materialEditor);
			DoOverlay(_materialEditor);
			DoRim(_materialEditor);
			DoDiffuseLUT(_materialEditor);
			DoEdge(_materialEditor);
			DoSSAO (_materialEditor);
		}

		private void DoGeneral(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("General"))
				return;

			_materialEditor.TextureProperty(m_MainTex, "Main Texture (RGB)");

            _materialEditor.TextureProperty(m_BayerTex, "Differ Matrix");

            _materialEditor.ShaderProperty(m_FadeOut, "Fade Out");

			if (DoKeyword (_materialEditor, m_DimOn, "Use Dim Texture"))
			{
				_materialEditor.TextureProperty (m_DimTex, "Dim Texture (RGB)");
			}

			EndGroup();
		}

		private void DoNormalMap(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Normal Map"))
				return;
			
			if (DoKeyword(_materialEditor, m_NormalMapOn, "Use Normal Map"))
			{
				_materialEditor.TextureProperty(m_NormalMapTex, "Normal Map");
			}

			EndGroup();
		}

		private void DoOverlay(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Overlay"))
				return;
			
			if (DoKeyword(_materialEditor, m_OverlayOn, "Use Overlay Texture"))
			{
				_materialEditor.TextureProperty(m_OverlayTex, "Overlay Texture (RGBA)");
			}

			EndGroup();
		}

		private void DoRim(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Rim"))
				return;
			
			if (DoKeyword(_materialEditor, m_RimOn, "Use Rim"))
			{
                _materialEditor.ShaderProperty(m_RimLUTTex, "Rim LUT (Grayscale)");
				_materialEditor.ShaderProperty(m_RimIntensity, "Rim Intensity");
			}

			EndGroup();
		}

		private void DoDiffuseLUT(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Diffuse LUT"))
				return;
			
			if (DoKeyword(_materialEditor, m_DiffuseLUTOn, "Use Diffuse LUT"))
			{
				_materialEditor.TextureProperty(m_DiffuseLUTTex, "Diffuse LUT (Grayscale)");
			}

			EndGroup();
		}

		private void DoEdge(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Edge"))
				return;
            
			if (DoKeyword (_materialEditor, m_EdgeOn, "Use Edges"))
			{
				_materialEditor.ShaderProperty (m_EdgeColor, "Edge Color");
				_materialEditor.ShaderProperty (m_EdgeAutoColor, "Edge Auto Color");
				_materialEditor.ShaderProperty (m_EdgeAutoColorFactor, "Edge Auto Color Factor");
			}

			EndGroup();
		}

		private void DoSSAO(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("SSAO"))
				return;
            /*
			if (DoKeyword (_materialEditor, m_SsaoOn, "Use SSAO"))
			{
				_materialEditor.ShaderProperty (m_SsaoShapness, "SSAO Shapness");
			}
            */         

			EndGroup();
		}
	}
}