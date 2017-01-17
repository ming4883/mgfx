using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
    
    [CustomEditor(typeof(ControlWithInput))]
    public class ControlWithInputUI : Editor
    {
        public override void OnInspectorGUI()
        {
            ControlWithInput _target = target as ControlWithInput;

            EditorGUILayout.Separator();

            bool _needReset = false;
        
            ControlWithInput.ControlStyles _lastStyle = _target.style;
            _target.style = (ControlWithInput.ControlStyles)EditorGUILayout.EnumPopup("Style", _lastStyle, UI.LAYOUT_DEFAULT);
            _needReset |= _lastStyle != _target.style;

            if (_target.style == ControlWithInput.ControlStyles.FirstPerson)
            {
                _target.speed = EditorGUILayout.Slider("Speed", _target.speed, 1 / 128.0f, 10.0f, UI.LAYOUT_DEFAULT);

                EditorGUILayout.Separator();
                EditorGUILayout.TextArea(
                    "W - forward\n" +
                    "S - backward\n" +
                    "A - left\n" +
                    "D - right\n" +
                    "Q - up\n" +
                    "Z - down\n"
                , EditorStyles.helpBox, UI.LAYOUT_DEFAULT);

                EditorGUILayout.Separator();
            }
            else
            {
                Transform _lastTarget = _target.target;
                _target.target = EditorGUILayout.ObjectField("Target", _lastTarget, typeof(Transform), true, UI.LAYOUT_DEFAULT) as Transform;
                _needReset |= _lastTarget != _target.target;
            }

            if (GUILayout.Button("Apply") || _needReset)
            {
                _target.Reset();
            }
        }

        public static void AddControl(ControlWithInput.ControlStyles _style)
        {
            Camera[] _camList = null;
            if (null != Selection.activeGameObject)
                _camList = Selection.activeGameObject.GetComponents<Camera>();

            if (null == _camList || 0 == _camList.Length)
            {
                EditorUtility.DisplayDialog("Camera/Add Control", "Please select a Camera", "OK");
                return;
            }

            foreach (Camera _cam in _camList)
            {
                if (null == _cam.GetComponent<ControlWithInput>())
                {
                    ControlWithInput _c = _cam.gameObject.AddComponent<ControlWithInput>();
                    _c.style = _style;
                }
            }
        }

        [MenuItem("MGFX/Camera/Add 1st-Person Control", false, 2000)]
        public static void MenuItem()
        {
            AddControl(ControlWithInput.ControlStyles.FirstPerson);
        }

        [MenuItem("MGFX/Camera/Add 3rd-Person Control", false, 2001)]
        public static void MenuItem3rd()
        {
            AddControl(ControlWithInput.ControlStyles.ThirdPerson);
        }

    }
}