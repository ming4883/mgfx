using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX.Rendering/MobileEffects")]
	public class RenderFeatureMobileEffects : RenderFeatureBase
	{
		#region Material Identifiers

		[Material("Hidden/MGFX.Rendering/NPR2")]
        [HideInInspector]
        public Material MaterialNPR2;

		[Material("Hidden/MGFX.Rendering/FXAA")]
		[HideInInspector]
		public Material MaterialFAXX;

		[Material("Hidden/MGFX.Rendering/NPR2GeomBuffer")]
        [HideInInspector]
        public Material MaterialNPR2GeomBuffer;
		
		#endregion

		#region Public Properties

        public bool ultraQuality = false;

        /// Halves the resolution of the effect to increase performance.
        public bool downsampling
        {
            get { return _downsampling; }
            set { _downsampling = value; }
        }

        [SerializeField, Tooltip("Halves the resolution of the effect to increase performance.")]
        bool _downsampling = false;
		
		/// Degree of darkness produced by the effect.
		public float occlusionIntensity
		{
            get { return _occlusionIntensity; }
			set { _occlusionIntensity = value; }
		}

		[SerializeField, Range(0, 4), Tooltip("Degree of darkness produced by the effect.")]
		float _occlusionIntensity = 2;

		/// Radius of occlusion sample points, which affects extent of darkened areas.
		public float occlusionRadius
		{
            get { return Mathf.Max(_occlusionRadius, 1e-4f); }
			set { _occlusionRadius = value; }
		}

		[SerializeField, Tooltip("Radius of occlusion sample points, which affects extent of darkened areas.")]
		float _occlusionRadius = 0.2f;

		/// Degree of self shadowing produced by the effect.
		public float occlusionSelfShadowing
		{
			get { return _occlusionSelfShadowing; }
			set { _occlusionSelfShadowing = value; }
		}

		[SerializeField, Range(1, 20), Tooltip("Degree of self shadowing produced by the effect.")]
		float _occlusionSelfShadowing = 2;

		/// Trace Dir X
		public float occlusionDirX
		{
			get { return _occlusionDirX; }
			set { _occlusionDirX = value; }
		}

		[SerializeField, Range(-1, 1), Tooltip("Trace direction-x.")]
		float _occlusionDirX = 1;

		/// Trace Dir Y
		public float occlusionDirY
		{
			get { return _occlusionDirY; }
			set { _occlusionDirY = value; }
		}

		[SerializeField, Range(-1, 1), Tooltip("Trace direction-y.")]
		float _occlusionDirY = 1;

		/// Trace Dir Z
		public float occlusionDirZ
		{
			get { return _occlusionDirZ; }
			set { _occlusionDirZ = value; }
		}

		[SerializeField, Range(-1, 1), Tooltip("Trace direction-z.")]
		float _occlusionDirZ = 1;

		public bool fxaa = true;

		/// Radius of the produced edges.
		public float edgeRadius
        {
            get { return Mathf.Max(_edgeRadius, 1e-4f); }
            set { _edgeRadius = value; }
        }

        [SerializeField, Tooltip("Radius of the produced edges.")]
        float _edgeRadius = 0.01f;

        /// Visiblity of the edges.
        public float edgeIntensity
        {
            get { return _edgeIntensity; }
            set { _edgeIntensity = value; }
        }

        [SerializeField, Range(0, 1), Tooltip("Visiblity of the edges.")]
        float _edgeIntensity = 1;


		/// Number of sample points, which affects quality and performance.
		public SampleCount sampleCount
		{
			get { return _sampleCount; }
			set { _sampleCount = value; }
		}

		public enum SampleCount { Lowest, Low, Medium, High, Variable }

		[SerializeField, Tooltip("Number of sample points, which affects quality and performance.")]
        SampleCount _sampleCount = SampleCount.Variable;

		/// Determines the sample count when SampleCount.Variable is used.
		/// In other cases, it returns the preset value of the current setting.
		public int sampleCountValue
		{
			get
			{
				switch (_sampleCount)
				{
					case SampleCount.Lowest: return 3;
					case SampleCount.Low: return 6;
					case SampleCount.Medium: return 12;
					case SampleCount.High: return 20;
				}
				return Mathf.Clamp(_sampleCountValue, 1, 256);
			}
			set { _sampleCountValue = value; }
		}

		[SerializeField]
		int _sampleCountValue = 4;

		/// Number of iterations of blur filter.
		public int blurIterations
		{
			get { return _blurIterations; }
			set { _blurIterations = value; }
		}

		[SerializeField, Range(0, 4), Tooltip("Number of iterations of the blur filter.")]
		int _blurIterations = 1;

		#endregion

		#region Effect Passes
		
		// Update the common material properties.
		void UpdateMaterialProperties(bool _useGBuffer)
		{
			var _mtl = MaterialNPR2;
			if (null == _mtl)
				return;
			
			_mtl.shaderKeywords = null;

			_mtl.SetFloat("_OcclusionIntensity", occlusionIntensity);
			_mtl.SetFloat("_OcclusionRadius", occlusionRadius);
			_mtl.SetFloat("_OcclusionSelfShadowing", 1.0f - (occlusionSelfShadowing + 79.5f) / 100.0f);
            _mtl.SetFloat("_EdgeIntensity", edgeIntensity);
            _mtl.SetFloat("_EdgeRadius", edgeRadius);
			_mtl.SetFloat("_TargetScale", downsampling ? 0.5f : 1);
			//_mtl.SetVector("_ShadowTraceDir", new Vector3(occlusionDirX, occlusionDirY, occlusionDirZ).normalized);

			// Sample count
			if (sampleCount == SampleCount.Lowest)
				_mtl.EnableKeyword("_SAMPLECOUNT_LOWEST");
			else
				_mtl.SetInt("_SampleCount", sampleCountValue);
		}
		

		#endregion

		#region MonoBehaviour Functions

		public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
		{
		}

		#endregion
	}
}
