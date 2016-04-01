using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Mud
{

	[ExecuteInEditMode]
	public class RenderFeatureBase : MonoBehaviour
	{

		#region Material Management

		public static HashID MTL_ALBEDO = new HashID("Hidden/Mud/Albedo");

		protected HashDict<Material> m_Materials = new HashDict<Material>();
		protected Material LoadMaterial(HashID _id)
		{
			var _shaderName = _id.ToString();

			if (m_Materials.ContainsKey(_id))
			{
				Debug.LogWarningFormat("possible duplicated LoadMaterial {0}", _shaderName);
				return m_Materials[_id];
			}

			Shader _shader = Shader.Find(_shaderName);
			if (null == _shader)
			{
				Debug.LogErrorFormat("shader {0} not found", _shaderName);
				return null;
			}

			var _mtl = new Material(_shader);
			_mtl.hideFlags = HideFlags.HideAndDontSave;
			m_Materials.Add(_id, _mtl);
			return _mtl;
		}

		protected Material GetMaterial(HashID _id)
		{
			if (!m_Materials.ContainsKey(_id))
				return null;

			return m_Materials[_id];
		}


		#endregion

		#region Command Buffer Management
		protected class EvtCmdBuf
		{
			public CameraEvent Event;
			public CommandBuffer CommandBuffer;
		}

		protected class EvtCmdBufList :List<EvtCmdBuf>
		{
			public RenderTexture AlbedoBuffer;
		}

		protected class CameraCommands : Dictionary<Camera, EvtCmdBufList>
		{

		}

		protected CameraCommands m_CameraCommands = new CameraCommands ();

		private Camera m_AlbedoCamera = null;

		protected CommandBuffer GetCommandBufferForEvent(Camera _cam, CameraEvent _event, string _name)
		{

			var _curr = m_CameraCommands[_cam].Find((_evtbuf) =>
			{
				return _evtbuf.Event == _event;
			});

			if (null != _curr)
				return _curr.CommandBuffer;

			CommandBuffer _cmdBuf = new CommandBuffer();
			_cmdBuf.name = _name;
			_cam.AddCommandBuffer(_event, _cmdBuf);

			m_CameraCommands[_cam].Add(new EvtCmdBuf { Event = _event, CommandBuffer = _cmdBuf });

			return _cmdBuf;
		}

		protected RenderTexture GetAlbedoBufferForCamera(Camera _cam)
		{
			if (!m_CameraCommands.ContainsKey(_cam))
				return null;

			return m_CameraCommands[_cam].AlbedoBuffer;
		}

		#endregion

		#region MonoBehaviour related
		public virtual void OnEnable()
		{
			LoadMaterial(MTL_ALBEDO);

			Camera.onPreRender += OnPreRenderCamera;
		}

		public void OnDisable ()
		{
			Cleanup ();
		}

		public virtual void Cleanup ()
		{
			//Debug.Log ("Cleanup");
			if (m_AlbedoCamera)
				m_AlbedoCamera.targetTexture = null;

			foreach (var _pair in m_CameraCommands) {
				foreach (var _evtCmds in _pair.Value) {
					if (_pair.Key)
						_pair.Key.RemoveCommandBuffer (_evtCmds.Event, _evtCmds.CommandBuffer);

					if (_pair.Value.AlbedoBuffer)
						RenderTexture.DestroyImmediate(_pair.Value.AlbedoBuffer);
				}
			}

			m_CameraCommands.Clear();

			foreach (var _pair in m_Materials) {
				Material.DestroyImmediate (_pair.Value);
			}

			m_Materials.Clear();

			Camera.onPreRender -= OnPreRenderCamera;
		}

		protected virtual void OnSetupCameraEvents (Camera _cam)
		{
		}

		private void OnPreRenderCamera(Camera _cam)
		{
			if (null == _cam)
				return;

			if (_cam.name == gameObject.name)
				return;

			var _active = gameObject.activeInHierarchy && enabled;
			if (!_active)
			{
				Cleanup();
				return;
			}


			_cam.depthTextureMode = DepthTextureMode.DepthNormals;

			// Did we already add the command buffer on this camera? Nothing to do then.
			if (!m_CameraCommands.ContainsKey(_cam))
			{
				var _cmdList = new EvtCmdBufList();
				var _albedoBuffer = new RenderTexture(_cam.pixelWidth, _cam.pixelHeight, 16, RenderTextureFormat.ARGB32);
				_albedoBuffer.name = "MudAlbedoBuffer." + _cam.name;
				_cmdList.AlbedoBuffer = _albedoBuffer;
				m_CameraCommands[_cam] = _cmdList;
			}
			OnSetupCameraEvents(_cam);

			if (!m_AlbedoCamera)
			{
				m_AlbedoCamera = gameObject.GetComponent<Camera>();
				if (!m_AlbedoCamera)
					m_AlbedoCamera = gameObject.AddComponent<Camera>();
			}
			m_AlbedoCamera.CopyFrom(_cam);
			m_AlbedoCamera.depthTextureMode = DepthTextureMode.None;
			m_AlbedoCamera.clearFlags = CameraClearFlags.Color;
			m_AlbedoCamera.backgroundColor = new Color(0, 0, 0, 0);
			m_AlbedoCamera.rect = new Rect(0, 0, 1, 1);
			m_AlbedoCamera.enabled = false;
			m_AlbedoCamera.hideFlags = HideFlags.HideInInspector;
			
			var _lastRT = RenderTexture.active;
			RenderTexture.active = m_CameraCommands[_cam].AlbedoBuffer;

			m_AlbedoCamera.targetTexture = m_CameraCommands[_cam].AlbedoBuffer;
			m_AlbedoCamera.RenderWithShader(GetMaterial(MTL_ALBEDO).shader, "");
			
			RenderTexture.active = _lastRT;
		}

		#endregion

		#region Utils
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

		#endregion
	}

}
