using UnityEngine;
using UnityEditor;
using System;

namespace MGFX
{

	[CustomEditor (typeof(CameraControlWithInput))]
	public class CameraControlWithInputUI : Editor
	{
		public override void OnInspectorGUI ()
		{
			CameraControlWithInput _target = target as CameraControlWithInput;

			EditorGUILayout.Separator ();

			bool _needReset = false;
        
			CameraControlWithInput.ControlStyles _lastStyle = _target.style;
			_target.style = (CameraControlWithInput.ControlStyles)EditorGUILayout.EnumPopup ("Style", _lastStyle, UI.LAYOUT_DEFAULT);
			_needReset |= _lastStyle != _target.style;

			if (_target.style == CameraControlWithInput.ControlStyles.FirstPerson) {
				_target.speed = EditorGUILayout.Slider ("Speed", _target.speed, 1 / 128.0f, 10.0f, UI.LAYOUT_DEFAULT);

				EditorGUILayout.Separator ();
				EditorGUILayout.TextArea (
					"W - forward\n" +
					"S - backward\n" +
					"A - left\n" +
					"D - right\n" +
					"Q - up\n" +
					"Z - down\n"
                , EditorStyles.helpBox, UI.LAYOUT_DEFAULT);

				EditorGUILayout.Separator ();
			} else {
				Transform _lastTarget = _target.target;
				_target.target = EditorGUILayout.ObjectField ("Target", _lastTarget, typeof(Transform), true, UI.LAYOUT_DEFAULT) as Transform;
				_needReset |= _lastTarget != _target.target;
			}

			if (GUILayout.Button ("Apply") || _needReset) {
				_target.Reset ();
			}
		}

		public static void AddControl (CameraControlWithInput.ControlStyles _style)
		{
			Camera[] _camList = null;
			if (null != Selection.activeGameObject)
				_camList = Selection.activeGameObject.GetComponents<Camera> ();

			if (null == _camList || 0 == _camList.Length) {
				EditorUtility.DisplayDialog ("Camera/Add Control", "Please select a Camera", "OK");
				return;
			}

			foreach (Camera _cam in _camList) {
				if (null == _cam.GetComponent<CameraControlWithInput> ()) {
					CameraControlWithInput _c = _cam.gameObject.AddComponent<CameraControlWithInput> ();
					_c.style = _style;
				}
			}
		}

		[MenuItem ("MGFX/Camera/Add 1st-Person Control", false, 2000)]
		public static void MenuItem ()
		{
			AddControl (CameraControlWithInput.ControlStyles.FirstPerson);
		}

		[MenuItem ("MGFX/Camera/Add 3rd-Person Control", false, 2001)]
		public static void MenuItem3rd ()
		{
			AddControl (CameraControlWithInput.ControlStyles.ThirdPerson);
		}
	}
}