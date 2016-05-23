using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;

namespace MGFX
{

public static class UI
{
	public static GUILayoutOption[] LAYOUT_DEFAULT = new GUILayoutOption[] { };
	public static List<int> _layerNumbers = new List<int>();

	public static LayerMask LayerMaskField(string label, LayerMask layerMask)
	{
		var _layers = UnityEditorInternal.InternalEditorUtility.layers;

		_layerNumbers.Clear();

		for (int i = 0; i < _layers.Length; i++)
			_layerNumbers.Add(LayerMask.NameToLayer(_layers[i]));

		int _maskWithoutEmpty = 0;
		for (int i = 0; i < _layerNumbers.Count; i++)
		{
			if (((1 << _layerNumbers[i]) & layerMask.value) > 0)
				_maskWithoutEmpty |= (1 << i);
		}

		_maskWithoutEmpty = EditorGUILayout.MaskField(label, _maskWithoutEmpty, _layers);

		int mask = 0;
		for (int i = 0; i < _layerNumbers.Count; i++)
		{
			if ((_maskWithoutEmpty & (1 << i)) > 0)
				mask |= (1 << _layerNumbers[i]);
		}
		layerMask.value = mask;

		return layerMask;
	}
}

}
