using UnityEngine;
using UnityEditor;
using System;


namespace MGFX.Rendering
{
	[CustomEditor (typeof(PlanarReflection))]
	public class PlanarReflectionUI : Editor
	{
		private string[] ResolutionTxts = new string[] {"256","512", "1024", "2048"};
		private int[] ResolutionVals = new int[] {256, 512, 1024, 2048};

		public override void OnInspectorGUI()
		{
			PlanarReflection _target = target as PlanarReflection;

			EditorGUILayout.Separator ();

			_target.m_TextureResolution = EditorGUILayout.IntPopup("Resolution", _target.m_TextureResolution, ResolutionTxts, ResolutionVals, UI.LAYOUT_DEFAULT); 

			_target.m_MinClipOffset = EditorGUILayout.FloatField ("Min Clip Offset", _target.m_MinClipOffset, UI.LAYOUT_DEFAULT);

			_target.m_ReflectLayers = UI.LayerMaskField("Reflected Layers", _target.m_ReflectLayers);
		}
	}

}