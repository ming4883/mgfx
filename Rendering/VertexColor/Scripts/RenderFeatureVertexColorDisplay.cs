using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX
{

    [ExecuteInEditMode]
    [AddComponentMenu("Rendering/MGFX/VertexColorDisplay")]
    public class RenderFeatureVertexColorDisplay : RenderFeatureBase
    {
        #region Material Identifiers

        [Material("Hidden/MGFX/VertexColorSelect")]
        [HideInInspector]
        public Material MaterialVertexColorSelect;
        
        [Material("Hidden/MGFX/VertexColorDisplay")]
        [HideInInspector]
        public Material MaterialVertexColorDisplay;


        #endregion

        #region Public Properties

        public bool showAlpha = false;

        #endregion

        #region Implemetations

        public void UpdateMaterialProperties(Camera _cam)
        {
        }

        // http://docs.unity3d.com/540/Documentation/Manual/GraphicsCommandBuffers.html
        // http://docs.unity3d.com/540/Documentation/ScriptReference/Rendering.BuiltinRenderTextureType.html
        public override void SetupCameraEvents(Camera _cam, RenderSystem _system)
        {
            RenderGeomBuffer(_cam, MaterialVertexColorSelect.shader, "RenderType", new Color(0, 0, 0, 0));

            UpdateMaterialProperties(_cam);
            var _cmdBuf = GetCommandBufferForEvent(_cam, CameraEvent.BeforeImageEffects, "MGFX.VertexColorDisplay");
            _cmdBuf.Clear();
            _cmdBuf.Blit(GetGeomBuffer(_cam) as Texture, BuiltinRenderTextureType.CameraTarget, MaterialVertexColorDisplay, showAlpha ? 1 : 0);
        }

        #endregion
    }

}
