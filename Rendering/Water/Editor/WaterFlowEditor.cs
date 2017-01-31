using UnityEditor;
using UnityEngine;

namespace MGFX.Rendering
{
	[CustomEditor(typeof(WaterFlow))]
	public class WaterFlowEditor : Editor
	{
		private static Color m_HeadColor = new Color(1, 1, 1, 1.0f);
		private static Color m_LineColor = new Color(1, 1, 0, 1.0f);

		private int m_SelectedIndex = -1;

		public override void OnInspectorGUI()
		{
			base.DrawDefaultInspector();
		}
		
		public bool OnSceneGUIPoint(ref Vector3 _pt, int _index)
		{
			float _scale = HandleUtility.GetHandleSize(_pt);
			float _handleSize = 0.04f * _scale;
			float _pickSize = 0.06f * _scale;
			
			if (Handles.Button(_pt, Quaternion.identity, _handleSize, _pickSize, Handles.DotCap))
			{
				m_SelectedIndex = _index;
			}

			if (_index == m_SelectedIndex)
			{
				EditorGUI.BeginChangeCheck();
				_pt = Handles.DoPositionHandle(_pt, Quaternion.identity);

				if(EditorGUI.EndChangeCheck())
				{
					Undo.RecordObject(target, "WaterFlow Move Point");
					return true;
				}	
			}
			return false;
		}

		public void OnEnable()
		{
			//Tools.hidden = true;
		}

		public void OnDisable()
		{
			//Tools.hidden = false;
		}

		public void OnSceneGUI()
		{
			var _inst = target as WaterFlow;

			int _numOfPts = _inst.points.Length;

			if (_numOfPts < 1)
				return;

			Handles.color = m_HeadColor;

			var _p0 = _inst.points[0];
			if (OnSceneGUIPoint(ref _p0, 0))
				_inst.points[0] = _p0;

			if (_numOfPts < 2)
				return;

			Handles.color = m_LineColor;

			for(int _it = 1; _it < _numOfPts; _it++)
			{
				var _beg = _inst.points[_it-1];
				var _end = _inst.points[_it];
				Handles.DrawLine(_beg, _end);

				if (OnSceneGUIPoint(ref _end, _it))
					_inst.points[_it] = _end;
			}
		}
	}
}