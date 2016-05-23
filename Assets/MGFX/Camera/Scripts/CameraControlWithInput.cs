using UnityEngine;
using System;

namespace MGFX
{
	[RequireComponent (typeof(Camera))]
	[AddComponentMenu ("Mud/Camera/ContolWithInput")]
	public class CameraControlWithInput : MonoBehaviour
	{
		public class DragState
		{
			public Vector3 startMousePos;
			public Quaternion startRotate;
			public float startDist;
			public bool valid;
		}

		public enum ControlStyles
		{
			FirstPerson,
			ThirdPerson,
		}

		public abstract class Control
		{
			public float speed;

			public static void UpdatePosition (Transform _transform, Transform _target, float _dist)
			{
				Vector3 _lookdir = _transform.TransformDirection (0, 0, 1).normalized;
				_transform.position = _target.position - _lookdir * _dist;
			}

			public static void Move (Transform _transform, Vector3 _localDir)
			{
				Vector3 _worldDir = _transform.TransformDirection (_localDir);
				_transform.position = _transform.position + _worldDir;
			}

			public abstract void Update (Transform _transform, Transform _target, DragState _dragState);

			public abstract void Reset (Transform _transform, Transform _target);
		}

		public class TPStyleControl : Control
		{
			public override void Update (Transform _transform, Transform _target, DragState _dragState)
			{
				if (Input.GetMouseButton (0)) {
					if (_dragState.valid) {
						Vector3 _delta = Input.mousePosition - _dragState.startMousePos;
						Quaternion _q1 = Quaternion.AngleAxis (Mathf.Floor (0.5f * _delta.x), Vector3.up);
						Quaternion _q2 = Quaternion.AngleAxis (Mathf.Floor (-0.5f * _delta.y), Vector3.right);

						_transform.rotation = _dragState.startRotate * _q2 * _q1;

						Control.UpdatePosition (_transform, _target, _dragState.startDist);
					} else {
						_dragState.startMousePos = Input.mousePosition;
						_dragState.startRotate = _transform.rotation;
						_dragState.startDist = (_transform.position - _target.position).magnitude;
						_dragState.valid = true;
					}
				} else {
					if (_dragState.valid) {
						//on mouse up
					}
					_dragState.valid = false;
				}
			}

			public override void Reset (Transform _transform, Transform _target)
			{
				if (null != _target) {
					float _dist = (_transform.position - _target.position).magnitude;
					_transform.position = _target.position + _target.forward * _dist;
					_transform.LookAt (_target, Vector3.up);
				}
			}
		}

		public class FPStyleControl : Control
		{
			public FPStyleControl ()
			{
			}

			public override void Update (Transform _transform, Transform _target, DragState _dragState)
			{
				if (Input.GetMouseButton (0)) {
					if (_dragState.valid) {
						Vector3 _delta = Input.mousePosition - _dragState.startMousePos;
						Quaternion _q1 = Quaternion.AngleAxis (Mathf.Floor (0.5f * _delta.x), Vector3.up);
						Quaternion _q2 = Quaternion.AngleAxis (Mathf.Floor (-0.5f * _delta.y), Vector3.right);

						_transform.rotation = _dragState.startRotate * _q2 * _q1;

						Vector3 _lookat = _transform.position + _transform.forward;
						_transform.LookAt (_lookat, Vector3.up);

						//Control.UpdatePosition(_transform, _target, _dragState.startDist);
					} else {
						_dragState.startMousePos = Input.mousePosition;
						_dragState.startRotate = _transform.rotation;
						//_dragState.startDist = (_transform.position - _target.position).magnitude;
						_dragState.valid = true;
					}
				} else {
					if (_dragState.valid) {
						//on mouse up
					}
					_dragState.valid = false;
				}

				if (Input.GetKey (KeyCode.W) || Input.GetKey (KeyCode.UpArrow)) {
					Move (_transform, new Vector3 (0, 0, speed * Time.fixedDeltaTime));
				} else if (Input.GetKey (KeyCode.S) || Input.GetKey (KeyCode.DownArrow)) {
					Move (_transform, new Vector3 (0, 0, speed * -Time.fixedDeltaTime));
				} else if (Input.GetKey (KeyCode.A) || Input.GetKey (KeyCode.LeftArrow)) {
					Move (_transform, new Vector3 (speed * -Time.fixedDeltaTime, 0, 0));
				} else if (Input.GetKey (KeyCode.D) || Input.GetKey (KeyCode.RightArrow)) {
					Move (_transform, new Vector3 (speed * Time.fixedDeltaTime, 0, 0));
				} else if (Input.GetKey (KeyCode.Q)) {
					Move (_transform, new Vector3 (0, speed * Time.fixedDeltaTime, 0));
				} else if (Input.GetKey (KeyCode.Z)) {
					Move (_transform, new Vector3 (0, speed * -Time.fixedDeltaTime, 0));
				}
			}

			public override void Reset (Transform _transform, Transform _target)
			{
				if (null != _target) {
					_transform.LookAt (_target, Vector3.up);
				} else {
					Vector3 _lookat = _transform.position + _transform.forward;
					_transform.LookAt (_lookat, Vector3.up);
				}
			}
		}

		public Transform target;
		public ControlStyles style = ControlStyles.ThirdPerson;
		public float speed = 1.0f;

		DragState m_dragState = new DragState ();
		Control m_control;

		void Start ()
		{
			Input.simulateMouseWithTouches = true;
			Reset ();
		}

		void Update ()
		{
			if (null != m_control) {
				m_control.speed = speed;
				m_control.Update (transform, target, m_dragState);
			} else {
				CreateController ();
			}
		}

		private void CreateController ()
		{
			switch (style) {
			case ControlStyles.ThirdPerson:
				{
					m_control = new TPStyleControl ();
				}
                
				break;

			case ControlStyles.FirstPerson:
				{
					m_control = new FPStyleControl ();
				}
				break;
			}
		}

		public void Reset ()
		{
			m_dragState.valid = false;

			CreateController ();
			m_control.Reset (transform, target);
		}
	}

}