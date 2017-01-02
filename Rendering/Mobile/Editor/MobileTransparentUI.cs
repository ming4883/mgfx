using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	public class MobileTransparentUI : MobileGenericUI
	{
		//[MaterialProperty("_Transparency")]
		//MaterialProperty m_Transparency;

		public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
		{
			FindProperties(this, _properties);

			DoTransparent(_materialEditor);
			DoGeneral(_materialEditor);
			DoGI(_materialEditor);
			DoNormalMap(_materialEditor);
			DoMatCap(_materialEditor);
			DoDiffuseLUT(_materialEditor);
		}

		private void DoTransparent(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("Transparent"))
				return;

			//(_materialEditor.target as Material).EnableKeyword ("_TRANSPARENT_ON");
			//_materialEditor.ShaderProperty(m_Transparency, "Transparency");
			EndGroup();
		}
	}
}