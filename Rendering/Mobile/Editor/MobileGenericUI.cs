using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{

	public class MobileGenericUI : ShaderGUIBase
	{
		[MaterialProperty("_MainTex")]
		protected MaterialProperty m_MainTex;

		[MaterialProperty("_Color")]
		protected MaterialProperty m_Color;

		[MaterialProperty("_RealtimeLightingOn", "_REALTIME_LIGHTING_ON")]
		protected MaterialProperty m_RealtimeLightingOn;
		
		[MaterialProperty("_ReflectionProbesOn", "_REFLECTION_PROBES_ON")]
		protected MaterialProperty m_ReflectionProbesOn;

		[MaterialProperty("_ReflectionIntensity")]
		protected MaterialProperty m_ReflectionIntensity;

		[MaterialProperty("_VertexAnimRotateOn", "_VERTEX_ANIM_ROTATE_ON")]
		protected MaterialProperty m_VertexAnimRotateOn;

		[MaterialProperty("_VertexAnimRotateAxis")]
		protected MaterialProperty m_VertexAnimRotateAxis;

		[MaterialProperty("_VertexAnimRotateAngle")]
		protected MaterialProperty m_VertexAnimRotateAngle;

		[MaterialProperty("_GIAlbedoTex")]
		protected MaterialProperty m_GIAlbedoTex;

		[MaterialProperty("_GIAlbedoColor")]
		protected MaterialProperty m_GIAlbedoColor;

		[MaterialProperty("_GIEmissionTex")]
		protected MaterialProperty m_GIEmissionTex;

		[MaterialProperty("_GIEmissionColor")]
		protected MaterialProperty m_GIEmissionColor;
		
		[MaterialProperty("_GIIrradianceOn", "_GI_IRRADIANCE_ON")]
		protected MaterialProperty m_GIIrradianceOn;

		[MaterialProperty("_GIIrradianceIntensity")]
		protected MaterialProperty m_GIIrradianceIntensity;

		[MaterialProperty("_NormalMapOn", "_NORMAL_MAP_ON")]
		protected MaterialProperty m_NormalMapOn;

		[MaterialProperty("_NormalMapTex")]
		protected MaterialProperty m_NormalMapTex;

		[MaterialProperty("_MatCapOn", "_MATCAP_ON")]
		protected MaterialProperty m_MatCapOn;

		[MaterialProperty("_MatCapPlanarOn", "_MATCAP_PLANAR_ON")]
		protected MaterialProperty m_MatCapPlanarOn;

		[MaterialProperty("_MatCapAlbedoOn", "_MATCAP_ALBEDO_ON")]
		protected MaterialProperty m_MatCapAlbedoOn;

		[MaterialProperty("_MatCapTex")]
		protected MaterialProperty m_MatCapTex;

		[MaterialProperty("_MatCapIntensity")]
		protected MaterialProperty m_MapCapIntensity;

		[MaterialProperty("_DiffuseLUTOn", "_DIFFUSE_LUT_ON")]
		protected MaterialProperty m_DiffuseLUTOn;

		[MaterialProperty("_DiffuseLUTTex")]
		protected MaterialProperty m_DiffuseLUTTex;
		
		public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
		{
			FindProperties(this, _properties);

			DoGeneral(_materialEditor);
			DoVertexAnimation(_materialEditor);
			DoGI(_materialEditor);
			DoNormalMap(_materialEditor);
			DoMatCap(_materialEditor);
			DoDiffuseLUT(_materialEditor);
		}

		protected void DoGeneral(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("General"))
				return;

			_materialEditor.TextureProperty(m_MainTex, "Main Texture (RGB)");
			_materialEditor.ShaderProperty(m_Color, "Color");

			DoKeyword(_materialEditor, m_RealtimeLightingOn, "Use Lighting");

			if (DoKeyword(_materialEditor, m_ReflectionProbesOn, "Use Reflection Probes"))
			{
				_materialEditor.ShaderProperty(m_ReflectionIntensity, "Reflection Intensity");
			}
			
			EndGroup();
		}

		protected void DoVertexAnimation(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("VS Animation"))
				return;

			if (DoKeyword(_materialEditor, m_VertexAnimRotateOn, "Use VS Rotation"))
			{
				_materialEditor.ShaderProperty(m_VertexAnimRotateAxis, "Axis (XYZ)");
				_materialEditor.ShaderProperty(m_VertexAnimRotateAngle, "Angle (Scale, Offset)");
			}

			EndGroup();
		}

		protected void DoGI(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("GI"))
				return;
			
			if (DoKeyword(_materialEditor, m_GIIrradianceOn, "Use GI Irradiance"))
			{
				_materialEditor.ShaderProperty(m_GIIrradianceIntensity, "Irradiance Intensity");
			}

			_materialEditor.LightmapEmissionProperty (0);

			if (BeginGroup ("Baking"))
			{
				if (m_GIAlbedoTex.textureValue == null)
					m_GIAlbedoTex.textureValue = m_MainTex.textureValue;

				_materialEditor.ShaderProperty (m_GIAlbedoTex, "GI Albedo Tex");
				_materialEditor.ShaderProperty (m_GIAlbedoColor, "GI Albedo Color");
				_materialEditor.ShaderProperty (m_GIEmissionTex, "GI Emission Tex");
				_materialEditor.ShaderProperty (m_GIEmissionColor, "GI Emission Color");
				EndGroup ();
			}

			EndGroup();
		}

		protected void DoNormalMap(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Normal Map"))
				return;
			
			if (DoKeyword(_materialEditor, m_NormalMapOn, "Use Normal Map"))
			{
				_materialEditor.TextureProperty(m_NormalMapTex, "Normal Map");
			}

			EndGroup();
		}

		protected void DoMatCap(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("MatCap"))
				return;

			if (DoKeyword(_materialEditor, m_MatCapOn, "Use MatCap"))
			{
				_materialEditor.TextureProperty(m_MatCapTex, "MatCap");
				_materialEditor.ShaderProperty(m_MapCapIntensity, "MatCap Intensity");
				DoKeyword(_materialEditor, m_MatCapPlanarOn, "MatCap Planar");
				DoKeyword(_materialEditor, m_MatCapAlbedoOn, "MatCap Albedo");
			}

			EndGroup();
		}

		protected void DoDiffuseLUT(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Diffuse LUT"))
				return;
			
			if (DoKeyword(_materialEditor, m_DiffuseLUTOn, "Use Diffuse LUT"))
			{
				_materialEditor.TextureProperty(m_DiffuseLUTTex, "Diffuse LUT (Grayscale)");
			}

			EndGroup();
		}
	}
}