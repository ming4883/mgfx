using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{

	[ExecuteInEditMode]
	[AddComponentMenu ("Rendering/MGFX/NPREdge")]
	public class RenderFeatureNPREdge : RenderFeatureBase
	{
		#region Material Identifiers

		public static HashID MTL_EDGE_DETECT = new HashID ("Hidden/MGFX/NPREdgeDetect");
		public static HashID MTL_EDGE_DILATE = new HashID ("Hidden/MGFX/NPREdgeDilate");
		public static HashID MTL_EDGE_AA = new HashID ("Hidden/MGFX/NPREdgeAA");
		public static HashID MTL_EDGE_APPLY = new HashID ("Hidden/MGFX/NPREdgeApply");

		#endregion

		#region Public Properties

		public bool edgeAA = false;

		private Color edgeColor = Color.black;

		[Range (0, 1.0f)]
		private float edgeAutoColoring = 0.25f;

		[Range (0.1f, 4.0f)]
		private float edgeAutoColorFactor = 1.5f;

		[Range (0.5f, 2.0f)]
		public float thickness = 1.0f;

		public float detailsZ = 0.0625f; 

		public float detailsAngle = 0.5f;

		#endregion

		#region Implemetations

		public override void OnEnable()
		{
			base.OnEnable ();

			LoadMaterial (MTL_EDGE_DETECT);
			LoadMaterial (MTL_EDGE_DILATE);
			LoadMaterial (MTL_EDGE_AA);
			LoadMaterial (MTL_EDGE_APPLY);
		}

		public void UpdateMaterialProperties(Camera _cam)
		{
			var _edgeThreshold = new Vector4 (
				detailsZ,
				detailsAngle,
				0,
				0);
			if (RenderSystem.IsSceneCamera (_cam))
				_edgeThreshold.x = 0;

			GetMaterial (MTL_EDGE_DETECT).SetVector ("_EdgeThreshold", _edgeThreshold);
			GetMaterial (MTL_EDGE_DETECT).SetFloat ("_EdgeThickness", thickness);

			GetMaterial (MTL_EDGE_APPLY).SetColor ("_EdgeColor", edgeColor);
			GetMaterial (MTL_EDGE_APPLY).SetFloat ("_EdgeAutoColoring", edgeAutoColoring);
			GetMaterial (MTL_EDGE_APPLY).SetFloat ("_EdgeAutoColorFactor", edgeAutoColorFactor);
		}

		// http://docs.unity3d.com/540/Documentation/Manual/GraphicsCommandBuffers.html
		// http://docs.unity3d.com/540/Documentation/ScriptReference/Rendering.BuiltinRenderTextureType.html
		public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
		{
			UpdateMaterialProperties (_cam);

			// update material properties
			var _screen_texelSize = new Vector4 (
				                        1.0f / _cam.pixelWidth,
				                        1.0f / _cam.pixelHeight,
				                        1.0f * _cam.pixelWidth,
				                        1.0f * _cam.pixelHeight);

			var _idEdgeBuf1 = Shader.PropertyToID ("_EdgeTex1");
			var _idEdgeBuf2 = Shader.PropertyToID ("_EdgeTex2");

			var _idSrcBuf = _idEdgeBuf1;
			var _idDstBuf = _idEdgeBuf2;

			// allocate and setup edge buffer
			{
				var _cmdBuf = GetCommandBufferForEvent (_cam, CameraEvent.AfterDepthNormalsTexture, "Minv.NPREdge");
				_cmdBuf.Clear ();

				int _w = _cam.pixelWidth * 1;
				int _h = _cam.pixelHeight * 1;

				_cmdBuf.GetTemporaryRT (_idEdgeBuf1, _w, _h, 0, FilterMode.Bilinear, RenderTextureFormat.R8);
				_cmdBuf.GetTemporaryRT (_idEdgeBuf2, _w, _h, 0, FilterMode.Bilinear, RenderTextureFormat.R8);

				_cmdBuf.SetGlobalVector ("_ScreenTexelSize", _screen_texelSize);
				_cmdBuf.Blit (BuiltinRenderTextureType.None, _idSrcBuf, GetMaterial (MTL_EDGE_DETECT));

				if (edgeAA)
				{
					_cmdBuf.Blit (_idSrcBuf, _idDstBuf, GetMaterial (MTL_EDGE_AA));
					Swap (ref _idSrcBuf, ref _idDstBuf);
				}

				_cmdBuf.SetGlobalTexture ("_MudNPREdgeTex", _idSrcBuf);
			}

			//apply edges
			{
				var _cmdBuf = GetCommandBufferForEvent (_cam, CameraEvent.AfterForwardOpaque, "Minv.NPREdge");
				_cmdBuf.Clear ();

				/*
				var _idCurr = Shader.PropertyToID ("_CurrTexture");

				_cmdBuf.GetTemporaryRT (_idCurr, -1, -1);
				_cmdBuf.Blit (BuiltinRenderTextureType.CameraTarget, _idCurr);

				// apply edges to albedo
				SetFlip (_cmdBuf, _cam);
				_cmdBuf.Blit (_idCurr, BuiltinRenderTextureType.CameraTarget, GetMaterial (MTL_EDGE_APPLY));

				_cmdBuf.ReleaseTemporaryRT (_idCurr);
				*/
				_cmdBuf.ReleaseTemporaryRT (_idEdgeBuf1);
				_cmdBuf.ReleaseTemporaryRT (_idEdgeBuf2);
			}
		}

		#endregion
	}

}
