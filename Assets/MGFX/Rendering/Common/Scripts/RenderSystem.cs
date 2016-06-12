using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{

	[ExecuteInEditMode]
	[AddComponentMenu("Rendering/MGFX/RenderSystem")]
	public class RenderSystem : MonoBehaviour
	{
		#region Camera Buffers Management
		protected class CameraBuffers
		{
			public RenderTexture Albedo;

			public void Cleanup()
			{
				if (Albedo)
					RenderTexture.DestroyImmediate(Albedo);
			}
		}

		protected class CameraBuffersMapping : Dictionary<Camera, CameraBuffers>
		{

		}

		private CameraBuffersMapping m_CameraBuffers = new CameraBuffersMapping();

		private Camera m_AlbedoCamera = null;
		private Shader m_AlbedoShader = null;

		public RenderTexture GetAlbedoBufferForCamera(Camera _cam)
		{
			if (!m_CameraBuffers.ContainsKey(_cam))
				return null;

			return m_CameraBuffers[_cam].Albedo;
		}

		#endregion

		#region MonoBehaviour related
		public virtual void OnEnable()
		{
			transform.hideFlags = HideFlags.HideInInspector;
			Camera.onPreRender += OnPreRenderCamera;

			//QualitySettings.antiAliasing = 0;
		}

		public void OnDisable ()
		{
			Cleanup ();
		}

		public void Cleanup ()
		{
			//Log.I ("Cleanup");
			foreach (var _pair in m_CameraBuffers)
			{
				_pair.Value.Cleanup();
			}

			m_CameraBuffers.Clear();

			Camera.onPreRender -= OnPreRenderCamera;
		}

		private void RenderAlbedoBuffer(Camera _cam)
		{
			// Did we already add the command buffer on this camera? Nothing to do then.
			if (!m_CameraBuffers.ContainsKey(_cam))
			{
				var _buffers = new CameraBuffers();
				var _albedoBuffer = new RenderTexture(_cam.pixelWidth, _cam.pixelHeight, 16, RenderTextureFormat.ARGB32);
				_albedoBuffer.name = "MudAlbedoBuffer." + _cam.name;
				_buffers.Albedo = _albedoBuffer;
				m_CameraBuffers[_cam] = _buffers;
			}

			if (!m_AlbedoCamera)
			{
				m_AlbedoCamera = gameObject.GetComponent<Camera>();
				if (!m_AlbedoCamera)
					m_AlbedoCamera = gameObject.AddComponent<Camera>();
			}

			if (!m_AlbedoShader)
			{
				m_AlbedoShader = Shader.Find("Hidden/Mud/Albedo");
			}

			m_AlbedoCamera.CopyFrom(_cam);
			m_AlbedoCamera.depthTextureMode = DepthTextureMode.None;
			m_AlbedoCamera.clearFlags = CameraClearFlags.Color;
			m_AlbedoCamera.backgroundColor = new Color(0, 0, 0, 0);
			m_AlbedoCamera.rect = new Rect(0, 0, 1, 1);
			m_AlbedoCamera.enabled = false;
			m_AlbedoCamera.hideFlags = HideFlags.HideInInspector;

			var _lastRT = RenderTexture.active;

			var _buffer = m_CameraBuffers[_cam].Albedo;

			RenderTexture.active = _buffer;

			m_AlbedoCamera.targetTexture = _buffer;
			m_AlbedoCamera.RenderWithShader(m_AlbedoShader, "");

			m_AlbedoCamera.targetTexture = null;
			RenderTexture.active = _lastRT;
		}

		private void EnsureImageEffect(Camera _cam)
		{
			RenderSystemDummy _dummy = _cam.gameObject.GetComponent<RenderSystemDummy> ();
			if (!_dummy)
			{
				//Log.I ("adding RenderSystemDummy for camera '{0}'", _cam.name);
				_dummy = _cam.gameObject.AddComponent<RenderSystemDummy> ();
			}
            _dummy.hideFlags = HideFlags.NotEditable;
		}

		public static bool IsSceneCamera(Camera _cam)
		{
			return string.Compare (_cam.name, "SceneCamera") == 0;
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
			
			_cam.depthTextureMode = DepthTextureMode.DepthNormals;
			//RenderAlbedoBuffer(_cam);

			bool _isSceneCam = IsSceneCamera(_cam);

			foreach(var _feature in GetComponents<RenderFeatureBase>())
			{
				if (_isSceneCam && false == _feature.affectSceneCamera)
					continue;
				
				_feature.OnPreRenderCamera(_cam, this);
			}
		}

		#endregion

	}

}
