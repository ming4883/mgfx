using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/Rendering/MGFX/NPREffects")]
	public class RenderFeatureNPREffects : RenderFeatureBase
	{
		#region Material Identifiers

		[Material("Hidden/MGFX/NPREffects")]
        [HideInInspector]
        public Material MaterialNPREffects;


        [Material("Hidden/MGFX/NPREffectsGeomBuffer")]
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
		float _occlusionSelfShadowing = 14;

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
		int _sampleCountValue = 16;

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
			var _mtl = MaterialNPREffects;
			if (null == _mtl)
				return;
			
			_mtl.shaderKeywords = null;

			_mtl.SetFloat("_OcclusionIntensity", occlusionIntensity);
			_mtl.SetFloat("_OcclusionRadius", occlusionRadius);
			_mtl.SetFloat("_OcclusionSelfShadowing", 1.0f - (occlusionSelfShadowing + 79.5f) / 100.0f);
            _mtl.SetFloat("_EdgeIntensity", edgeIntensity);
            _mtl.SetFloat("_EdgeRadius", edgeRadius);
			_mtl.SetFloat("_TargetScale", downsampling ? 0.5f : 1);
			_mtl.SetVector("_ShadowTraceDir", new Vector3(occlusionDirX, occlusionDirY, occlusionDirZ).normalized);

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
            RenderGeomBuffer(_cam, MaterialNPR2GeomBuffer.shader, "RenderType", new Color(0.5f, 0.5f, 0.0f, 0.0f));

			UpdateMaterialProperties(true);

			var _rtMask = Shader.PropertyToID ("_MudSSAOTex");

            var _m = MaterialNPREffects;
            int _scale = ultraQuality ? 2 : 1;

			// update command buffers
			{
                var _cmdBuf = GetCommandBufferForEvent (_cam, CameraEvent.AfterDepthTexture, "MGFX.NPR2.Setup");
				_cmdBuf.Clear ();

				var tw = _cam.pixelWidth;
				var th = _cam.pixelHeight;
                var format = RenderTextureFormat.ARGB32;
				var rwMode = RenderTextureReadWrite.Linear;

				if (downsampling)
				{
					tw /= 2;
					th /= 2;
				}

                tw = ((tw / 4) + 1) * 4 * _scale;
                th = ((th / 4) + 1) * 4 * _scale;

                _cmdBuf.GetTemporaryRT (_rtMask, tw, th, 0, FilterMode.Bilinear, format, rwMode);
                _cmdBuf.SetGlobalTexture("_MudGeomTex", GetGeomBuffer(_cam));

				// AO estimation
				_cmdBuf.Blit (BuiltinRenderTextureType.None, _rtMask, _m, 0);

				//if (blurIterations > 0)
				{
					// Blur buffer
					var _rtBlur = Shader.PropertyToID ("_BlurTexture");
                    _cmdBuf.GetTemporaryRT (_rtBlur, tw, th, 0, FilterMode.Bilinear, format, rwMode);

                    var _blurRight = new Vector2 ((float)_scale / tw, 0);
                    var _blurUp = new Vector2 (0, (float)_scale / th);

					// Blur iterations
					for (var i = 0; i < blurIterations; i++)
					{
						_cmdBuf.SetGlobalVector ("_BlurVector", _blurRight);
						_cmdBuf.Blit (_rtMask, _rtBlur, _m, 1);

						_cmdBuf.SetGlobalVector ("_BlurVector", _blurUp);
						_cmdBuf.Blit (_rtBlur, _rtMask, _m, 1);
					}

                    // AA
                    //_cmdBuf.Blit (_rtMask, _rtBlur, _m, 2);
                    //_cmdBuf.Blit (_rtBlur, _rtMask, _m, 2);
                    //Swap(ref _rtBlur, ref _rtMask);

					_cmdBuf.ReleaseTemporaryRT (_rtBlur);
				}

				_cmdBuf.SetGlobalTexture ("_MudSSAOTex", _rtMask);
			}

			{
				var _cmdBuf = GetCommandBufferForEvent (_cam, CameraEvent.AfterForwardOpaque, "MGFX.NPR2.Final");
				_cmdBuf.Clear ();

                bool _applyToScreen = edgeIntensity > 0;

                if (_applyToScreen)
                {
                    var _idCurr = Shader.PropertyToID("_CurrTexture");
                    _cmdBuf.GetTemporaryRT(_idCurr, -1, -1);
                    _cmdBuf.Blit (BuiltinRenderTextureType.CameraTarget, _idCurr);

                    SetFlip(_cmdBuf, _cam);
                    _cmdBuf.Blit(_idCurr, BuiltinRenderTextureType.CameraTarget, _m, 3);
                    _cmdBuf.ReleaseTemporaryRT (_idCurr);
                }
                _cmdBuf.ReleaseTemporaryRT(_rtMask);
			}
		}

		#endregion
	}
}
