using UnityEngine;
using UnityEditor;

namespace MGFX.Rendering
{
	class DitherMatrixUtil : RenderUtils.IUtil
	{
		Texture2D m_BayerTex;

		public override string Name()
		{
			return "Dither Matrix";
		}

		public override void OnGUI()
		{
			EditorGUILayout.BeginVertical(new GUILayoutOption[0]);
			m_BayerTex = EditorGUILayout.ObjectField("Dither Matrix", m_BayerTex, typeof(Texture2D), true, new GUILayoutOption[0]) as Texture2D;

			if (GUILayout.Button("Apply To All Materials"))
			{
				int _cnt = 0;
				foreach (Material _mtl in Resources.FindObjectsOfTypeAll<Material>())
				{
					if (_mtl.HasProperty("_BayerTex"))
					{
						_mtl.SetTexture("_BayerTex", m_BayerTex);
						_cnt++;
					}
				}

				if (_cnt > 0)
				{
					EditorUtility.DisplayDialog(Name(), string.Format("Applied to {0} Materials", _cnt), "OK");
				}
			}

			EditorGUILayout.EndVertical();
		}
	}
}