using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX.Rendering
{

	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/RenderSystem")]
	public class RenderSystem : MonoBehaviour
	{
		RenderSystemSceneData m_SceneData;
		List<RenderFeatureBase> m_Features;

		#region MonoBehaviour related
		public virtual void OnEnable()
		{
			transform.hideFlags = HideFlags.HideInInspector;
			Camera.onPreRender += OnPreRenderCamera;

			// collect render features
			m_Features = new List<RenderFeatureBase>();
			foreach (var _feature in GetComponents<RenderFeatureBase>())
			{
				m_Features.Add(_feature);
			}
			
		}

		public void OnDisable ()
		{
			Cleanup ();
		}

		protected RenderSystemSceneData SceneData
		{
			get
			{
				if (null == m_SceneData)
				{
					var _sceneData = FindObjectsOfType<RenderSystemSceneData>();
					if (_sceneData.Length == 0)
					{
						Log.I("Creating RenderSystemSceneData");
						m_SceneData = new GameObject("RenderSystemSceneData").AddComponent<RenderSystemSceneData>();
					}
					else
					{
						m_SceneData = _sceneData[0];
					}
				}
				
				return m_SceneData;
			}
		}
		
		public T GetSceneData<T>() where T :UnityEngine.MonoBehaviour
		{
			if (null == SceneData)
				return null;

			return SceneData.gameObject.GetComponent<T>();
		}


		public T AddSceneData<T>() where T : UnityEngine.MonoBehaviour
		{
			if (null == SceneData)
				return null;

			return SceneData.gameObject.AddComponent<T>();
		}

		public void Cleanup ()
		{
			//Log.I ("Cleanup");
			m_CameraCommands.Cleanup();
			m_CameraBuffers.Cleanup();
			Camera.onPreRender -= OnPreRenderCamera;
		}

		private void EnsureImageEffect(Camera _cam)
		{
			RenderSystemDummy _dummy = _cam.gameObject.GetComponent<RenderSystemDummy> ();
			if (!_dummy)
			{
				//Log.I ("adding RenderSystemDummy for camera '{0}'", _cam.name);
				_dummy = _cam.gameObject.AddComponent<RenderSystemDummy> ();
                _dummy.hideFlags = HideFlags.None;
			}
		}

		public static bool IsSceneCamera(Camera _cam)
		{
			// Camera of SceneView
			return string.Compare (_cam.name, "SceneCamera") == 0;
		}

		public static bool IsPreRenderCamera(Camera _cam)
		{
			// Camera of Preview
			return string.Compare (_cam.name, "PreRenderCamera") == 0;
		}

		private void OnPreRenderCamera(Camera _cam)
		{
			if (null == _cam || _cam.name == gameObject.name)
				return;

			//Log.I (_cam.name);

			bool _active = gameObject.activeInHierarchy && enabled;
			if (!_active)
			{
				Cleanup();
				return;
			}

			var _ignore = _cam.gameObject.GetComponent<RenderSystemIgnore>();
			if (_ignore)
				return;

			EnsureImageEffect (_cam);
			
            _cam.depthTextureMode = DepthTextureMode.Depth;

			bool _isSceneCam = IsSceneCamera(_cam);

			foreach(var _feature in m_Features)
			{
				if (_isSceneCam && false == _feature.affectSceneCamera)
					continue;
				
				_feature.OnPreRenderCamera(_cam, this);
			}
		}

		#endregion

		#region Camera Buffer Management
		public class CameraBuffer
		{
			public RenderTexture Rtt = null;

			public void Cleanup()
			{
				if (Rtt)
					RenderTexture.DestroyImmediate(Rtt);
			}
		}

		public class CameraBufferCollection : Dictionary<int, CameraBuffer>
		{
			public Camera Cam = null;
			public Camera PrepareForRender(Camera _cam, GameObject _gameObject)
			{
				if (!this.Cam)
				{
					this.Cam = _gameObject.GetComponent<Camera>();
					if (!this.Cam)
						this.Cam = _gameObject.AddComponent<Camera>();
				}

				this.Cam.CopyFrom(_cam);
				this.Cam.depthTextureMode = DepthTextureMode.None;
				
#if UNITY_5_6_OR_NEWER
				this.Cam.allowHDR = false;
#else
				this.Cam.hdr = false;
#endif
				this.Cam.renderingPath = RenderingPath.VertexLit;
				this.Cam.clearFlags = CameraClearFlags.Color;
				this.Cam.rect = new Rect(0, 0, 1, 1);
				this.Cam.enabled = false;
				this.Cam.hideFlags = HideFlags.HideInInspector;
				this.Cam.nearClipPlane = Mathf.Max(_cam.nearClipPlane, 0.1f);

				return this.Cam;
			}

			public CameraBuffer Alloc(Camera _cam, string _name, int _w, int _h, int _d, RenderTextureFormat _fmt, RenderTextureReadWrite _rw)
			{
				CameraBuffer _camBuf;

				_name = _name + "@" + _cam.name;
				int _key = _name.GetHashCode();

				// Did we already add the command buffer on this camera? Nothing to do then.
				if (!this.ContainsKey(_key))
				{
					_camBuf = new CameraBuffer();
					this[_key] = _camBuf;
				}
				else
				{
					_camBuf = this[_key];
				}

				if (_camBuf.Rtt == null || 
					_camBuf.Rtt.width != _w || 
					_camBuf.Rtt.height != _h || 
					_camBuf.Rtt.depth != _d || 
					_camBuf.Rtt.format != _fmt)
				{
					if (_camBuf.Rtt)
						RenderTexture.DestroyImmediate(_camBuf.Rtt);
					
					var _rtt = new RenderTexture(_w, _h, _d, _fmt, _rw);
					_rtt.autoGenerateMips = false;
					_rtt.filterMode = FilterMode.Point;
					_rtt.name = _name;
					_camBuf.Rtt = _rtt;
				}

				return _camBuf;
			}

			public CameraBuffer AllocForPostProc(Camera _cam, string _name, RenderTextureFormat _fmt, RenderTextureReadWrite _rw)
			{
				int _w = Mathf.CeilToInt(_cam.pixelWidth * 0.5f) * 2;
				int _h = Mathf.CeilToInt(_cam.pixelHeight * 0.5f) * 2;
				
				return Alloc(_cam, _name, _w, _h, 0, _fmt, _rw);
			}

			public CameraBuffer AllocForRender(Camera _cam, string _name, int _depth, RenderTextureFormat _fmt, RenderTextureReadWrite _rw)
			{
				int _w = Mathf.CeilToInt(_cam.pixelWidth * 0.5f) * 2;
				int _h = Mathf.CeilToInt(_cam.pixelHeight * 0.5f) * 2;

				return Alloc(_cam, _name, _w, _h, _depth, _fmt, _rw);
			}

			public RenderTexture GetRtt(Camera _cam, string _name)
			{
				_name = _name + "@" + _cam.name;
				int _key = _name.GetHashCode();

				if (!this.ContainsKey(_key))
					return null;

				return this[_key].Rtt;
			}

			public void Cleanup()
			{
				foreach (var _pair in this)
				{
					_pair.Value.Cleanup();
				}

				this.Clear();
			}
		}

		private CameraBufferCollection m_CameraBuffers = new CameraBufferCollection();

		public CameraBufferCollection CameraBuffers { get { return m_CameraBuffers; } }

		#endregion


		#region Command Buffer Management

		public class CameraCommand
		{
			public Camera Camera;
			public CameraEvent Event;
			public CommandBuffer CommandBuffer;
		}

		public class CameraCommandCollection : Dictionary<int, CameraCommand>
		{
			public void Cleanup()
			{
				foreach (var _pair in this)
				{
					var _cmd = _pair.Value;

					if (_cmd.Camera)
						_cmd.Camera.RemoveCommandBuffer(_cmd.Event, _cmd.CommandBuffer);
				}

				Clear();
			}

			public CommandBuffer Alloc(Camera _cam, CameraEvent _event, string _name)
			{
				UnityEngine.Profiling.Profiler.BeginSample("RenderFeature.GetCmdBufForEvt");

				int _key = (_name + "@" + _cam.name + "@" + _event.ToString()).GetHashCode();

				if (this.ContainsKey(_key))
					return this[_key].CommandBuffer;

				CommandBuffer _cmdBuf = new CommandBuffer();
				_cmdBuf.name = _name;
				_cam.AddCommandBuffer(_event, _cmdBuf);

				this[_key] = new CameraCommand
				{
					Camera = _cam,
					Event = _event,
					CommandBuffer = _cmdBuf,
				};

				UnityEngine.Profiling.Profiler.EndSample();

				return _cmdBuf;
			}
		}

		protected CameraCommandCollection m_CameraCommands = new CameraCommandCollection();

		public CameraCommandCollection Commands { get { return m_CameraCommands; } }

		#endregion


	}

}
