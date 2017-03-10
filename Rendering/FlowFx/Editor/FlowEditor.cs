using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(Flow))]
	public class FlowEditor : Editor
	{
		private static Color m_ConeColor = new Color(0, 1, 1, 0.5f);
		private static Color m_LineColor = new Color(0, 1, 1, 1.0f);
		private static Color m_PivotColor = new Color(1, 1, 1, 1.0f);

		private float m_HandleSize = 0.04f;
		private float m_PickSize = 0.06f;

		private int m_SelectedIndex = -1;

		public override void OnInspectorGUI()
		{
			base.DrawDefaultInspector();
		}

		public void OnEnable()
		{
			//Tools.hidden = true;
		}

		public void OnDisable()
		{
			//Tools.hidden = false;
		}

		public void OnSceneGUIPivot()
		{
			var _inst = target as Flow;
			var _tran = _inst.transform;

			float _scale = HandleUtility.GetHandleSize(_tran.position);

			Handles.color = m_PivotColor;

			if (Handles.Button(_tran.position, Quaternion.identity, m_HandleSize * _scale, m_PickSize * _scale, Handles.DotHandleCap))
			{
				m_SelectedIndex = -1;
			}

			Tools.hidden = m_SelectedIndex != -1;
		}

		public bool OnSceneGUIPoint(int _index)
		{
			var _inst = target as Flow;
			var _tran = _inst.transform;
			var _pt = _inst.points[_index];
			_pt = _tran.TransformPoint(_pt);
			float _scale = HandleUtility.GetHandleSize(_pt);

			Handles.color = m_ConeColor;

			if (_index > 0)
			{
				var _pt2 = _inst.points[_index - 1];
				_pt2 = _tran.TransformPoint(_pt2);

				var _dir = _pt - _pt2;

				Handles.ConeHandleCap(0, _pt2 + _dir * 0.75f, Quaternion.FromToRotation(Vector3.forward, _dir), 0.25f * _scale, EventType.Repaint);
			}

			Handles.color = m_LineColor;

			_scale = _index == 0 ? 2 * _scale : _scale;
			if (Handles.Button(_pt, Quaternion.identity, m_HandleSize * _scale, m_PickSize * _scale, Handles.DotHandleCap))
			{
				m_SelectedIndex = _index;
			}

			Tools.hidden = m_SelectedIndex != -1;

			if (_index == m_SelectedIndex)
			{
				EditorGUI.BeginChangeCheck();

				_pt = Handles.DoPositionHandle(_pt, _tran.rotation);

				if (EditorGUI.EndChangeCheck())
				{
					Undo.RecordObject(target, "Flow Move Point");
					_inst.points[_index] = _tran.InverseTransformPoint(_pt);
					return true;
				}
			}
			return false;
		}

		public void OnSceneGUI()
		{
			var _inst = target as Flow;

			int _numOfPts = _inst.points.Length;

			if (_numOfPts < 1)
				return;

			OnSceneGUIPoint(0);

			if (_numOfPts < 2)
				return;

			var _tran = _inst.transform;

			for (int _it = 1; _it < _numOfPts; _it++)
			{
				OnSceneGUIPoint(_it);
			}

			OnSceneGUIPivot();
		}
	}
}