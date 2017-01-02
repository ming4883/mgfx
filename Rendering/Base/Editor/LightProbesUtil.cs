using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
	
	class LightProbessUtil : RenderUtils.IUtil
	{
		//TextAsset mAsset = null;
		LightProbeGroup _output = null;
		int _layers = 2;
		float _layerHeight = 10.0f;
		float _mergeDistance = 2.0f;

		public override string Name()
		{
			return "Light Probes";
		}

		public override void OnGUI()
		{
			
			_output = EditorGUILayout.ObjectField(new GUIContent("Output"), _output, typeof(LightProbeGroup), true) as LightProbeGroup;

			_layers = EditorGUILayout.IntField(new GUIContent("Layers"), _layers);

			_layerHeight = EditorGUILayout.FloatField(new GUIContent("Layer Height"), _layerHeight);

			_mergeDistance = EditorGUILayout.FloatField(new GUIContent("Merge Distance"), _mergeDistance);

			if (GUILayout.Button(new GUIContent("Generate")))
			{
				var _p = new LightProbePlacement
				{
					mergeDistance = _mergeDistance,
					probeObject = _output,
					layers = _layers,
					layerHeight = _layerHeight,
				};

				_p.PlaceProbes();
			}
		}
		
	}
}