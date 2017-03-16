using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{

	public class MobileGenericVSAnimUI : MobileGenericUI
	{
		[MaterialProperty("_VertexAnimRotateOn", "_VERTEX_ANIM_ROTATE_ON")]
		protected MaterialProperty m_VertexAnimRotateOn;

		[MaterialProperty("_VertexAnimRotateAxis")]
		protected MaterialProperty m_VertexAnimRotateAxis;

		[MaterialProperty("_VertexAnimTime")]
		protected MaterialProperty m_VertexAnimTime;
		
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
		
		protected void DoVertexAnimation(MaterialEditor _materialEditor)
		{
			if (!BeginGroup("VS Animation"))
				return;

			if (DoKeyword(_materialEditor, m_VertexAnimRotateOn, "Use VS Rotation"))
			{
				_materialEditor.ShaderProperty(m_VertexAnimRotateAxis, "Axis (XYZ)");
				_materialEditor.ShaderProperty(m_VertexAnimTime, "Time (Scale, Offset)");
			}

			EndGroup();
		}

	}
}