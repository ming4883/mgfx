using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

namespace MGFX
{
    [ExecuteInEditMode]
    [AddComponentMenu("Rendering/MGFX/VolumetricLineRenderer")]
    public class RenderFeatureVolumetricLine : RenderFeatureBase
    {
        [Material("MGFX/VolumetricLine")]
		[HideInInspector]
		public Material m_MaterialVolLine;

        public Texture m_LookUpTable;

        public Mesh m_CubeMesh;

        public override void OnEnable()
        {
            base.OnEnable();
            LoadMaterials(this);
        }

        public void UpdateMaterialProperties(Camera _cam, VolumetricLine _line)
        {
			
        }

        public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
        {
            var _evt = CameraEvent.AfterForwardAlpha;
            var _cmdBuf = GetCommandBufferForEvent(_cam, _evt, "MGFX.VolLine");
            _cmdBuf.Clear();

            var system = VolumetricLineSystem.instance;

            var propPt0 = Shader.PropertyToID("_VolLinePoint0");
            var propPt1 = Shader.PropertyToID("_VolLinePoint1");
            var propCol = Shader.PropertyToID("_VolLineColor");
            var propRad = Shader.PropertyToID("_VolLineRadius");
            Vector3 valPt0 = Vector3.zero;
            Vector3 valPt1 = Vector3.zero;
            Color valCol = Color.white;
            float valRad = 0;
            Matrix4x4 _m, _p;

            var _lut = m_LookUpTable;
            m_MaterialVolLine.SetTexture("_VolLineLUT", _lut);

            foreach (var _line in system.m_Lines)
            {
                valRad = _line.GetRenderMatrics(out _m, out _p);
                _line.GetPoints(_p, out valPt0, out valPt1);
                valCol = _line.GetLinearColor();

                _cmdBuf.SetGlobalVector(propPt0, valPt0);
                _cmdBuf.SetGlobalVector(propPt1, valPt1);
                _cmdBuf.SetGlobalColor(propCol, valCol);
                _cmdBuf.SetGlobalFloat(propRad, valRad);

                _cmdBuf.DrawMesh(m_CubeMesh, _m, m_MaterialVolLine, 0, 0);
            }
        }
    }
}