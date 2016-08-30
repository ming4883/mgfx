using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{

	[ExecuteInEditMode]
	[AddComponentMenu("Rendering/MGFX/RenderSystem")]
	public class RenderSystem : MonoBehaviour
	{
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
			
            _cam.depthTextureMode = DepthTextureMode.Depth;

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
