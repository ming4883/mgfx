using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Mud
{

	[ExecuteInEditMode]
	[AddComponentMenu ("Mud/Rendering/Features/NPREdge")]
	public class RenderFeatureNPREdge : RenderFeatureBase
	{
		#region Material Identifiers

		public static HashID MTL_EDGE_DETECT = new HashID ("Hidden/Mud/NPREdgeDetect");
		public static HashID MTL_EDGE_DILATE = new HashID ("Hidden/Mud/NPREdgeDilate");
		public static HashID MTL_EDGE_AA = new HashID ("Hidden/Mud/NPREdgeAA");
		public static HashID MTL_EDGE_APPLY = new HashID ("Hidden/Mud/NPREdgeApply");
		
		#endregion

		#region Public Properties
		[Range (1.0f, 20.0f)]
		public float edgeDetails = 2.0f;

		public bool edgeAA = false;

		public Color edgeColor = Color.black;

		[Range(0, 1.0f)]
		public float edgeAutoColoring = 0.5f;

		#endregion

		#region Implemetations
		public override void OnEnable ()
		{
			base.OnEnable ();

			LoadMaterial (MTL_EDGE_DETECT);
			LoadMaterial (MTL_EDGE_DILATE);
			LoadMaterial (MTL_EDGE_AA);
			LoadMaterial (MTL_EDGE_APPLY);
		}

		public void UpdateMaterialProperties(Camera _cam)
		{
			var _viewRange = _cam.farClipPlane - _cam.nearClipPlane;

			var _edgeThreshold = new Vector4(
				edgeDetails,
				edgeDetails,
				edgeDetails,
				edgeDetails * 200 / (_viewRange * 0.5f));

			GetMaterial(MTL_EDGE_DETECT).SetVector("_EdgeThreshold", _edgeThreshold);
			GetMaterial(MTL_EDGE_APPLY).SetColor("_EdgeColor", edgeColor);
			GetMaterial(MTL_EDGE_APPLY).SetFloat("_EdgeAutoColoring", edgeAutoColoring);
		}

		// http://docs.unity3d.com/540/Documentation/Manual/GraphicsCommandBuffers.html
		// http://docs.unity3d.com/540/Documentation/ScriptReference/Rendering.BuiltinRenderTextureType.html
		public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
		{
			UpdateMaterialProperties(_cam);

			// update material properties
			var _screen_texelSize = new Vector4 (
				1.0f / _cam.pixelWidth,
				1.0f / _cam.pixelHeight,
				1.0f * _cam.pixelWidth,
				1.0f * _cam.pixelHeight);

			// update command buffers
			var _cmdbuf = GetCommandBufferForEvent (_cam, CameraEvent.AfterForwardOpaque, "Mud.NPREdge");
			_cmdbuf.Clear ();

			var _idEdgeBuf1 = Shader.PropertyToID("_EdgeTex1");
			var _idEdgeBuf2 = Shader.PropertyToID("_EdgeTex2");

			var _idSrcBuf = _idEdgeBuf1;
			var _idDstBuf = _idEdgeBuf2;

			_cmdbuf.GetTemporaryRT(_idEdgeBuf1, -1, -1, 0, FilterMode.Bilinear, RenderTextureFormat.R8);
			_cmdbuf.GetTemporaryRT(_idEdgeBuf2, -1, -1, 0, FilterMode.Bilinear, RenderTextureFormat.R8);

			_cmdbuf.SetGlobalVector("_ScreenTexelSize", _screen_texelSize);

			_cmdbuf.Blit (BuiltinRenderTextureType.None, _idSrcBuf, GetMaterial (MTL_EDGE_DETECT));

			if (edgeAA) {

				_cmdbuf.Blit(_idSrcBuf, _idDstBuf, GetMaterial(MTL_EDGE_AA));
				Swap(ref _idSrcBuf, ref _idDstBuf);
			}

			// apply edges to albedo
			_cmdbuf.SetGlobalTexture("_MudAlbedoBuffer", _system.GetAlbedoBufferForCamera(_cam));
			_cmdbuf.Blit(_idSrcBuf, BuiltinRenderTextureType.CameraTarget, GetMaterial (MTL_EDGE_APPLY));

			_cmdbuf.ReleaseTemporaryRT(_idEdgeBuf1);
			_cmdbuf.ReleaseTemporaryRT(_idEdgeBuf2);
		}
		#endregion
	}

}
