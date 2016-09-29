using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX
{

    public class NPRHairUI : ShaderGUIBase
	{
		[MaterialProperty("_MainTex")]
		MaterialProperty m_MainTex;

		[MaterialProperty("_DiffuseLUTTex")]
		MaterialProperty m_DiffuseLUTTex;

		[MaterialProperty("_SpecularLUTTex")]
		MaterialProperty m_SpecularLUTTex;
		
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
		
		public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
		{
			FindProperties(this, _properties);

			DoGeneral(_materialEditor);
			DoNormalMap(_materialEditor);
			DoRim(_materialEditor);
		}

		private void DoGeneral(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("General"))
				return;

			_materialEditor.ShaderProperty(m_FadeOut, "Fade Out");

			_materialEditor.TextureProperty(m_BayerTex, "Differ Matrix");

			_materialEditor.TextureProperty(m_MainTex, "Main Texture (RGBA)");

			if (DoKeyword(_materialEditor, m_DimOn, "Use Dim Texture"))
			{
				_materialEditor.TextureProperty(m_DimTex, "Dim Texture (RGB)");
			}

			_materialEditor.TextureProperty(m_DiffuseLUTTex, "Diffuse LUT");

			_materialEditor.TextureProperty(m_SpecularLUTTex, "Specular LUT");

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
	}
}