using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace MGFX
{
    [ExecuteInEditMode]
    [AddComponentMenu("Rendering/MGFX/Bloom")]
    public class RenderFeatureBloom : RenderFeatureBase
    {
        #region Material Identifiers

        [Material("Hidden/MGFX/Bloom")]
        private Material MaterialBloom;

        #endregion

        #region Public Properties

        public enum Resolution
        {
            Low = 0,
            High = 1,
        }

        public enum BlurType
        {
            Standard = 0,
            Sgx = 1,
        }

        [Range(0.0f, 1.5f)]
        public float threshold = 0.25f;

        [Range(0.0f, 2.5f)]
        public float intensity = 0.5f;

        [Range(0.25f, 5.5f)]
        public float blurSize = 1.0f;

        Resolution resolution = Resolution.Low;
        [Range(1, 4)]
        public int blurIterations = 1;

        public BlurType blurType = BlurType.Sgx;

        #endregion

        #region MonoBehaviour Functions

        public override void OnEnable()
        {
            base.OnEnable();
            LoadMaterials(this);
        }

        public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
        {
            var _mtl = MaterialBloom;

            int divider = resolution == Resolution.Low ? 4 : 2;
            float widthMod = resolution == Resolution.Low ? 0.5f : 1.0f;

            var _rtW = _cam.pixelWidth / divider;
            var _rtH = _cam.pixelHeight / divider;

            // update command buffers
            var _cmdBuf = GetCommandBufferForEvent(_cam, CameraEvent.BeforeImageEffects, "Minv.Bloom");
            _cmdBuf.Clear();

            var _idCurr = Shader.PropertyToID ("_CurrTexture");

            _cmdBuf.GetTemporaryRT (_idCurr, -1, -1);
            _cmdBuf.Blit (BuiltinRenderTextureType.CameraTarget, _idCurr);

            var _idBloom1 = Shader.PropertyToID("_MudBloomTex1");
            var _idBloom2 = Shader.PropertyToID("_MudBloomTex2");
            _cmdBuf.GetTemporaryRT(_idBloom1, _rtW, _rtH, 0, FilterMode.Bilinear);
            _cmdBuf.GetTemporaryRT(_idBloom2, _rtW, _rtH, 0, FilterMode.Bilinear);

            var _idSrc = _idBloom1;
            var _idDst = _idBloom2;

            // downsample
            _cmdBuf.SetGlobalVector("_BloomParameter", new Vector4(blurSize * widthMod, 0.0f, threshold, intensity));
            _cmdBuf.Blit (_idCurr, _idSrc, _mtl, 1);

            // blur
            var passOffs = blurType == BlurType.Standard ? 0 : 2;

            for (int i = 0; i < blurIterations; i++)
            {
                _cmdBuf.SetGlobalVector("_BloomParameter", new Vector4(blurSize * widthMod + (i * 1.0f), 0.0f, threshold, intensity));

                // vertical blur
                _cmdBuf.Blit (_idSrc, _idDst, _mtl, 2 + passOffs);
                Swap(ref _idSrc, ref _idDst);

                // horizontal blur
                _cmdBuf.Blit (_idSrc, _idDst, _mtl, 3 + passOffs);
                Swap(ref _idSrc, ref _idDst);
            }

            SetFlip (_cmdBuf, _cam);
            _cmdBuf.SetGlobalTexture("_MudBloomTex", _idSrc);
            _cmdBuf.Blit (_idCurr, BuiltinRenderTextureType.CameraTarget, _mtl, 0);

            _cmdBuf.ReleaseTemporaryRT(_idBloom1);
            _cmdBuf.ReleaseTemporaryRT(_idBloom2);
            _cmdBuf.ReleaseTemporaryRT(_idCurr);

        }

        #endregion
    }
}
