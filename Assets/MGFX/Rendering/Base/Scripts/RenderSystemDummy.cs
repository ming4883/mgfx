using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{
	[ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
	public class RenderSystemDummy : MonoBehaviour
	{
		void OnEnable()
		{
			//Log.I("OnEnable");
		}

		void OnDisable()
		{
			//Log.I("OnDisable");
			//if (Application.isPlaying)
			//	Destroy (this);
			//else
			//	DestroyImmediate (this);
		}

		void OnRenderImage(RenderTexture _src, RenderTexture _dst)
		{
			Graphics.Blit (_src, _dst);
		}
	}
}
