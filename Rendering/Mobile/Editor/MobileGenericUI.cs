using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace MGFX.Rendering
{

	public class MobileGenericUI : ShaderGUIBase
	{
		[MaterialProperty("_MainTex")]
		protected MaterialProperty m_MainTex;

		[MaterialProperty("_Color")]
		protected MaterialProperty m_Color;
		
		[MaterialProperty("_ShadowColor")]
		protected MaterialProperty m_ShadowColor;

		[MaterialProperty("_DecalOn", "_DECAL_ON")]
		protected MaterialProperty m_DecalOn;
		
		[MaterialProperty("_DecalOffset")]
		protected MaterialProperty m_DecalOffset;

		[MaterialProperty("_RealtimeLightingOn", "_REALTIME_LIGHTING_ON")]
		protected MaterialProperty m_RealtimeLightingOn;
		
		[MaterialProperty("_ReflectionProbesOn", "_REFLECTION_PROBES_ON")]
		protected MaterialProperty m_ReflectionProbesOn;

		[MaterialProperty("_ReflectionIntensity")]
		protected MaterialProperty m_ReflectionIntensity;

		[MaterialProperty("_CompositeOn", "_COMPOSITE_ON")]
		protected MaterialProperty m_CompositeOn;

		[MaterialProperty("_CompositeTex")]
		protected MaterialProperty m_CompositeTex;

		[MaterialProperty("_CompositeNoiseOn", "_COMPOSITE_NOISE_ON")]
		protected MaterialProperty m_CompositeNoiseOn;

		[MaterialProperty("_CompositeNoise")]
		protected MaterialProperty m_CompositeNoise;

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
			DoDecal(_materialEditor);
			DoComposite(_materialEditor);
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
			_materialEditor.ShaderProperty(m_ShadowColor, "Shadow Color");

			DoKeyword(_materialEditor, m_RealtimeLightingOn, "Use Lighting");

			if (DoKeyword(_materialEditor, m_ReflectionProbesOn, "Use Reflection Probes"))
			{
				_materialEditor.ShaderProperty(m_ReflectionIntensity, "Reflection Intensity");
			}
			
			EndGroup();
		}

		protected void DoDecal(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Decal"))
				return;

			if (DoKeyword(_materialEditor, m_DecalOn, "Is Decal"))
			{
				_materialEditor.ShaderProperty(m_DecalOffset, "Decal Offset");

				SetInt(_materialEditor, "_SrcBlend", (int)BlendMode.SrcAlpha);
				SetInt(_materialEditor, "_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
				SetInt(_materialEditor, "_ZWrite", 0);
				SetRenderQueue(_materialEditor, (int)RenderQueue.Transparent);
				SetOverrideTag(_materialEditor, "RenderType", "Transparent");
			}
			else
			{
				SetInt(_materialEditor, "_SrcBlend", (int)BlendMode.One);
				SetInt(_materialEditor, "_DstBlend", (int)BlendMode.Zero);
				SetInt(_materialEditor, "_ZWrite", 1);
				SetRenderQueue(_materialEditor, -1);
				SetOverrideTag(_materialEditor, "RenderType", "");
			}

			EndGroup();
		}

		protected void DoComposite(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Composite"))
				return;

			if (DoKeyword(_materialEditor, m_CompositeOn, "Composite"))
			{
				_materialEditor.ShaderProperty(m_CompositeTex, "Composite Texture");

				if (DoKeyword(_materialEditor, m_CompositeNoiseOn, "Noise"))
				{
					_materialEditor.ShaderProperty(m_CompositeNoise, "Scale & Stength");
				}
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