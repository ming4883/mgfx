using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Mud
{
    [ExecuteInEditMode]
    [AddComponentMenu ("Mud/Rendering/Features/SSAO")]
    public class RenderFeatureSSAO : RenderFeatureBase
    {
		public static HashID MTL_SSAO = new HashID ("Hidden/Mud/SSAO");

        public enum SSAOSamples
		{
            Low = 0,
            Medium = 1,
            High = 2,
        }

        [Range(0.001f, 1.0f)]
        public float m_Radius = 0.4f;
        public SSAOSamples m_SampleCount = SSAOSamples.Medium;
        [Range(0.25f, 4.0f)]
        public float m_OcclusionIntensity = 1.5f;
        [Range(0, 4)]
        public int m_Blur = 2;
        [Range(1,6)]
        public int m_Downsampling = 2;
        [Range(0.02f, 2.0f)]
        public float m_OcclusionAttenuation = 1.0f;
        [Range(0.00001f, 0.5f)]
        public float m_MinZ = 0.01f;

        //public Shader m_SSAOShader;

        public Texture2D m_RandomTexture;

		public override void OnEnable ()
		{
			base.OnEnable ();

			LoadMaterial (MTL_SSAO);
		}

        [ImageEffectOpaque]
		protected override void OnSetupCameraEvents (Camera _cam)
		{
			var _ssaoMaterial = GetMaterial (MTL_SSAO);

            m_Downsampling = Mathf.Clamp (m_Downsampling, 1, 6);
            m_Radius = Mathf.Clamp (m_Radius, 0.001f, 1.0f);
            m_MinZ = Mathf.Clamp (m_MinZ, 0.00001f, 0.5f);
            m_OcclusionIntensity = Mathf.Clamp (m_OcclusionIntensity, 0.5f, 4.0f);
            m_OcclusionAttenuation = Mathf.Clamp (m_OcclusionAttenuation, 0.02f, 2.0f);
            m_Blur = Mathf.Clamp (m_Blur, 0, 4);

			float fovY = _cam.fieldOfView;
			float far = _cam.farClipPlane;
			float y = Mathf.Tan (fovY * Mathf.Deg2Rad * 0.5f) * far;
			float x = y * _cam.aspect;
			_ssaoMaterial.SetVector ("_FarCorner", new Vector3(x,y,far));

			int _ssaoWidth = Screen.width / m_Downsampling;
			int _ssaoHeight = Screen.height / m_Downsampling;

			int noiseWidth, noiseHeight;
			if (m_RandomTexture) {
				noiseWidth = m_RandomTexture.width;
				noiseHeight = m_RandomTexture.height;
			} else {
				noiseWidth = 1; noiseHeight = 1;
			}
			_ssaoMaterial.SetVector ("_NoiseScale", new Vector3 ((float)_ssaoWidth / noiseWidth, (float)_ssaoHeight / noiseHeight, 0.0f));
			_ssaoMaterial.SetVector ("_Params", new Vector4(
				m_Radius,
				m_MinZ,
				1.0f / m_OcclusionAttenuation,
				m_OcclusionIntensity));

			var _cmdbuf = GetCommandBufferForEvent (_cam, CameraEvent.BeforeLighting, "SSAO");
			_cmdbuf.Clear ();


            // Render SSAO term into a smaller texture
			//RenderTexture.GetTemporary (source.width / m_Downsampling, source.height / m_Downsampling, 0);
			var _rtAO = Shader.PropertyToID("_SSAO");
			_cmdbuf.GetTemporaryRT(_rtAO, _ssaoWidth, _ssaoHeight);


            bool _doBlur = m_Blur > 0;
			_cmdbuf.Blit (null, _rtAO, _ssaoMaterial, (int)m_SampleCount);

			/*
			if (_doBlur)
            {
                // Blur SSAO horizontally
                RenderTexture rtBlurX = RenderTexture.GetTemporary (source.width, source.height, 0);
				_ssaoMaterial.SetVector ("_TexelOffsetScale",
                                          new Vector4 ((float)m_Blur / source.width, 0,0,0));
				_ssaoMaterial.SetTexture ("_SSAO", rtAO);
				Graphics.Blit (null, rtBlurX, _ssaoMaterial, 3);
                RenderTexture.ReleaseTemporary (rtAO); // original rtAO not needed anymore

                // Blur SSAO vertically
                RenderTexture rtBlurY = RenderTexture.GetTemporary (source.width, source.height, 0);
				_ssaoMaterial.SetVector ("_TexelOffsetScale",
                                          new Vector4 (0, (float)m_Blur/source.height, 0,0));
				_ssaoMaterial.SetTexture ("_SSAO", rtBlurX);
				Graphics.Blit (source, rtBlurY, _ssaoMaterial, 3);
                RenderTexture.ReleaseTemporary (rtBlurX); // blurX RT not needed anymore

                rtAO = rtBlurY; // AO is the blurred one now
            }
            */

            // Modulate scene rendering with SSAO
			//_ssaoMaterial.SetTexture ("_SSAO", _rtAO);
			//Graphics.Blit (source, destination, _ssaoMaterial, 4);
			_cmdbuf.Blit (_rtAO, BuiltinRenderTextureType.GBuffer0, _ssaoMaterial, 4);

			_cmdbuf.ReleaseTemporaryRT (_rtAO);
        }
    }
}
