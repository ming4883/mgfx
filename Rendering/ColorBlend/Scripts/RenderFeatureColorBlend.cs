using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{

	[ExecuteInEditMode]
	[AddComponentMenu ("Rendering/MGFX/ColorBlend")]
	public class RenderFeatureColorBlend : RenderFeatureBase
	{
		#region Material Identifiers

        [Material("Hidden/MGFX/ColorBlend")]
        [HideInInspector]
        public Material MaterialColorBlend;
		
		#endregion

		#region Public Properties
		public enum Mode { 
			Lerp,		// lerp(src, color.rgb, color.a);
			Add, 		// add(src, color.rgb * color.a);
			Subtract, 	// sub(src, color.rgb * color.a);
			ReverseSubtract, // sub(color.rgb * color.a, sub);
			Multiply,	// mul(src, color.rgb * color.a);
		}

		public Color color = new Color(0, 0, 0, 0.5f);
		public Mode mode = Mode.Lerp;

		#endregion

		#region Implemetations
		public override void OnEnable ()
		{
			base.OnEnable ();

			affectSceneCamera = false;
		}

		public void UpdateMaterialProperties(Camera _cam)
		{
            MaterialColorBlend.SetColor("_BlendColor", color);
		}

		// http://docs.unity3d.com/540/Documentation/Manual/GraphicsCommandBuffers.html
		// http://docs.unity3d.com/540/Documentation/ScriptReference/Rendering.BuiltinRenderTextureType.html
		public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
		{
			UpdateMaterialProperties(_cam);

			// update command buffers
			var _cmdBuf = GetCommandBufferForEvent (_cam, CameraEvent.BeforeImageEffects, "MGFX.ColorBlend");
			_cmdBuf.Clear ();

			var _idCurr = Shader.PropertyToID("_CurrTexture");

			_cmdBuf.GetTemporaryRT(_idCurr, -1, -1);

			_cmdBuf.Blit(BuiltinRenderTextureType.CameraTarget, _idCurr);
			SetFlip(_cmdBuf, _cam);
            _cmdBuf.Blit(_idCurr, BuiltinRenderTextureType.CameraTarget, MaterialColorBlend, (int)mode);

			_cmdBuf.ReleaseTemporaryRT(_idCurr);
		}
		#endregion
	}

}
