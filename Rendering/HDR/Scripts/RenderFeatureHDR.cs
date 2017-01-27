using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("Rendering/MGFX/HDR")]
	public class RenderFeatureHDR : RenderFeatureBase
	{
		#region Material Identifiers

		[Material("Hidden/MGFX/HDR")]
		[HideInInspector]
		public Material MaterialBloom;

		#endregion

		#region Public Properties

		public enum Resolution
		{
			Low = 0,
			High = 1,
		}
		
		protected float exposure { get { return SceneData.exposure; } }

		protected float whitePointBias { get { return SceneData.whitePointBias; } }

		protected float adaptionSpeed { get { return SceneData.adaptionSpeed; } }

		protected float bloomThreshold { get { return SceneData.bloomThreshold; } }

		protected float bloomIntensity { get { return SceneData.bloomIntensity; } }

		protected float blurSize { get { return SceneData.blurSize; } }

		protected int blurIterations { get { return SceneData.blurIterations; } }

		protected RenderFeatureHDRBlurType blurType { get { return SceneData.blurType; } }
		
		#endregion

		private Resolution resolution = Resolution.High;
		private float adaptionRate
		{
			get { return Mathf.Clamp(adaptionSpeed * Time.deltaTime, 1.0f / 128.0f, 1.0f); }
		}

		private RenderFeatureHDRSceneData m_SceneData;

		public RenderFeatureHDRSceneData SceneData
		{
			get
			{
				if (null == m_SceneData)
				{
					m_SceneData = FindRenderSystem().GetSceneData<RenderFeatureHDRSceneData>();
					if (null == m_SceneData)
						m_SceneData = FindRenderSystem().AddSceneData<RenderFeatureHDRSceneData>();
				}
				
				return m_SceneData;
			}
		}

		#region MonoBehaviour Functions
		
		protected void SetupCommandBufferForHDR(CommandBuffer _cmdBuf, Camera _cam, RenderSystem _system, RenderTexture _frameBuf, RenderTargetIdentifier _outputTarget, Material _outputMtl, int _outputPass)
		{
			var _mtl = MaterialBloom;

			int _divider = resolution == Resolution.Low ? 4 : 2;
			float _widthMod = resolution == Resolution.Low ? 0.5f : 1.0f;

			var _rtW = _frameBuf.width / _divider;
			var _rtH = _frameBuf.height / _divider;

			var _bloomBuf1 = _system.CameraBuffers.Alloc(_cam, "BloomBuffer1", _rtW, _rtH, 0, _frameBuf.format, RenderTextureReadWrite.Default).Rtt;
			var _bloomBuf2 = _system.CameraBuffers.Alloc(_cam, "BloomBuffer2", _rtW, _rtH, 0, _frameBuf.format, RenderTextureReadWrite.Default).Rtt;
			var _whitePointBuf = _system.CameraBuffers.Alloc(_cam, "WhitePointBuffer", 1, 1, 0, _frameBuf.format, RenderTextureReadWrite.Default).Rtt;

			_bloomBuf1.filterMode = FilterMode.Bilinear;
			_bloomBuf2.filterMode = FilterMode.Bilinear;

			var _bufSrc = _bloomBuf1;
			var _bufDst = _bloomBuf2;

			// downsample
			float _edgeIntensity = 1.0f;
			float _adaptionRate = adaptionRate;
			if (RenderSystem.IsSceneCamera(_cam))
				_adaptionRate = 0.5f;
			_cmdBuf.SetGlobalVector("_ToneMappingParameter", new Vector4(exposure, whitePointBias, _adaptionRate, _edgeIntensity));

			_cmdBuf.SetGlobalVector("_BloomParameter", new Vector4(blurSize * _widthMod, 0.0f, bloomThreshold, bloomIntensity));
			
			_cmdBuf.Blit((RenderTargetIdentifier)_frameBuf, _bufSrc, _mtl, 1);

			// blur
			var passOffs = blurType == RenderFeatureHDRBlurType.Standard ? 0 : 2;

			for (int i = 0; i < blurIterations; i++)
			{
				_cmdBuf.SetGlobalVector("_BloomParameter", new Vector4(blurSize * _widthMod + (i * 1.0f), 0.0f, bloomThreshold, bloomIntensity));

				// vertical blur
				_cmdBuf.Blit((RenderTargetIdentifier)_bufSrc, _bufDst, _mtl, 3 + passOffs);
				Swap(ref _bufSrc, ref _bufDst);

				// horizontal blur
				_cmdBuf.Blit((RenderTargetIdentifier)_bufSrc, _bufDst, _mtl, 4 + passOffs);
				Swap(ref _bufSrc, ref _bufDst);
			}

			_cmdBuf.Blit((RenderTargetIdentifier)_bufSrc, _whitePointBuf, _mtl, 2);

			SetFlip(_cmdBuf, _cam);
			_cmdBuf.SetGlobalTexture("_MudBloomTex", _bufSrc);
			_cmdBuf.SetGlobalTexture("_MudWhitePointTex", _whitePointBuf);
			_cmdBuf.Blit((RenderTargetIdentifier)_frameBuf, _outputTarget, _outputMtl, _outputPass);
		}

		public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
		{
			// update command buffers
			var _cmdBuf = _system.Commands.Alloc(_cam, CameraEvent.BeforeImageEffects, "MGFX.HDR");
			_cmdBuf.Clear();


			var _frameBuf = GrabFrameBuffer(_system, _cam, _cmdBuf);

			SetupCommandBufferForHDR(_cmdBuf, _cam, _system, _frameBuf, BuiltinRenderTextureType.CameraTarget, MaterialBloom, 0);
		}

		#endregion
	}

	
}
