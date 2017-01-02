using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	public class RenderSystemSceneData : MonoBehaviour
	{
		void OnEnabled()
		{
			transform.hideFlags = HideFlags.HideInInspector;
		}
	}
}