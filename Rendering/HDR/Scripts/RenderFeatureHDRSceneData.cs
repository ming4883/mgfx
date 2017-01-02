using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX.Rendering
{

	public enum RenderFeatureHDRBlurType
	{
		Standard = 0,
		Sgx = 1,
	}

	public class RenderFeatureHDRSceneData : MonoBehaviour
	{
		[Header("Tone Mapping")]
		[Range(0.0f, 2.0f)]
		public float exposure = 1.0f;

		[Range(0.0f, 100.0f)]
		public float whitePointBias = 15.0f;

		[Range(0.125f, 2.0f)]
		public float adaptionSpeed = 1.0f;

		[Header("Bloom")]
		[Range(0.0f, 10.0f)]
		public float bloomThreshold = 3.0f;

		[Range(0.0f, 1.0f)]
		public float bloomIntensity = 0.125f;

		[Range(0.25f, 5.5f)]
		public float blurSize = 2.0f;

		[Range(1, 4)]
		public int blurIterations = 2;

		public RenderFeatureHDRBlurType blurType = RenderFeatureHDRBlurType.Sgx;
	}
}
