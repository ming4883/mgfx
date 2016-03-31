using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Mud
{

	[ExecuteInEditMode]
	public class RenderFeatureBase : MonoBehaviour
	{
		protected class EvtCmdBuf
		{
			public CameraEvent Event;
			public CommandBuffer CommandBuffer;
		}

		protected class EvtCmdBufList :List<EvtCmdBuf>
		{

		}

		protected class CameraCommands : Dictionary<Camera, EvtCmdBufList>
		{

		}

		protected HashDict<Material> m_Materials = new HashDict<Material> ();
		protected CameraCommands m_CameraCommands = new CameraCommands ();
		private int invokeCounter = 0;

		public virtual void OnEnable()
		{
			invokeCounter = 0;
		}

		public void OnDisable ()
		{
			Cleanup ();
		}

		public virtual void Cleanup ()
		{
			//Debug.Log ("Cleanup");

			foreach (var _pair in m_CameraCommands) {
				foreach (var _evtCmds in _pair.Value) {
					if (_pair.Key)
						_pair.Key.RemoveCommandBuffer (_evtCmds.Event, _evtCmds.CommandBuffer);
				}
			}

			m_CameraCommands.Clear();

			foreach (var _pair in m_Materials) {
				Material.DestroyImmediate (_pair.Value);
			}

			m_Materials.Clear();
		}

		protected Material LoadMaterial (HashID _id)
		{
			var _shaderName = _id.ToString ();

			if (m_Materials.ContainsKey (_id)) {
				Debug.LogWarningFormat ("possible duplicated LoadMaterial {0}", _shaderName);
				return m_Materials [_id];
			}

			Shader _shader = Shader.Find (_shaderName);
			if (null == _shader) {
				Debug.LogErrorFormat ("shader {0} not found", _shaderName);
				return null;
			}

			var _mtl = new Material (_shader);
			_mtl.hideFlags = HideFlags.HideAndDontSave;
			m_Materials.Add (_id, _mtl);
			return _mtl;
		}

		protected Material GetMaterial (HashID _id)
		{
			if (!m_Materials.ContainsKey (_id))
				return null;

			return m_Materials [_id];
		}

		protected virtual void OnSetupCameraEvents (Camera _cam)
		{
		}

		protected static void Swap (ref RenderTexture _a, ref RenderTexture _b)
		{
			RenderTexture _t = _a;
			_a = _b;
			_b = _t;
		}

		protected static void Swap (ref int _a, ref int _b)
		{
			int _t = _a;
			_a = _b;
			_b = _t;
		}

		protected CommandBuffer GetCommandBufferForEvent (Camera _cam, CameraEvent _event, string _name)
		{

			var _curr = m_CameraCommands [_cam].Find ((_evtbuf) => {
				return _evtbuf.Event == _event;
			});

			if (null != _curr)
				return _curr.CommandBuffer;

			CommandBuffer _cmdBuf = new CommandBuffer ();
			_cmdBuf.name = _name;
			_cam.AddCommandBuffer (_event, _cmdBuf);

			m_CameraCommands [_cam].Add (new EvtCmdBuf { Event = _event, CommandBuffer = _cmdBuf });

			return _cmdBuf;
		}

		public void OnWillRenderObject ()
		{
			invokeCounter++;

			var _active = gameObject.activeInHierarchy && enabled;
			if (!_active) {
				Cleanup ();
				return;
			}

			var _cam = Camera.current;
			if (null == _cam)
				return;

			// Did we already add the command buffer on this camera? Nothing to do then.
			if (!m_CameraCommands.ContainsKey (_cam))
				m_CameraCommands [_cam] = new EvtCmdBufList ();
			
			OnSetupCameraEvents (_cam);
		}

	}

}
