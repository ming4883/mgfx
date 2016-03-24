using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Mud
{

[ExecuteInEditMode]
[AddComponentMenu("Minverse/Rendering/RenderSystemNPR")]
public class NPREdge : RenderSystemBase
{
    public static HashID MTL_NORMAL_DEPTH = new HashID("Hidden/Minverse/NPRNormalDepth");
    public static HashID MTL_EDGE_DETECT = new HashID("Hidden/Minverse/NPREdgeDetect");
    public static HashID MTL_EDGE_DILATE = new HashID("Hidden/Minverse/NPREdgeDilate");
    public static HashID MTL_EDGE_AA = new HashID("Hidden/Minverse/NPREdgeAA");
    public static HashID MTL_EDGE_APPLY = new HashID("Hidden/Minverse/NPREdgeApply");

    /*
    Material m_materialNormalDepth;
    Material m_materialEdgeDetect;
    Material m_materialEdgeDilate;
    Material m_materialEdgeAA;
    Material m_materialEdgeApply;
    */

    [Range(1.0f / 64.0f, 2.0f)]
    public float edgeDetails = 1.0f;

    public bool edgeAA = false;
    
    void OnEnable()
    {
        
        /*
        m_materialNormalDepth = LoadMaterial("Hidden/Minverse/NPRNormalDepth");
        m_materialEdgeDetect = LoadMaterial("Hidden/Minverse/NPREdgeDetect");
        m_materialEdgeDilate = LoadMaterial("Hidden/Minverse/NPREdgeDilate");
        m_materialEdgeAA = LoadMaterial("Hidden/Minverse/NPREdgeAA");
        m_materialEdgeApply = LoadMaterial("Hidden/Minverse/NPREdgeApply");
        */
        LoadMaterial(MTL_NORMAL_DEPTH);
        LoadMaterial(MTL_EDGE_DETECT);
        LoadMaterial(MTL_EDGE_DILATE);
        LoadMaterial(MTL_EDGE_AA);
        LoadMaterial(MTL_EDGE_APPLY);
        GetMaterial(MTL_EDGE_DETECT).EnableKeyword("_LARGE_KERNEL");
       
    }

    // http://docs.unity3d.com/540/Documentation/Manual/GraphicsCommandBuffers.html
    // http://docs.unity3d.com/540/Documentation/ScriptReference/Rendering.BuiltinRenderTextureType.html
    protected override void OnSetupCameraEvents(Camera _cam)
    {
        var _cmdbuf = AddCommandBufferForEvent(_cam, CameraEvent.AfterGBuffer, "NPREdge");

        int _idTempBuf1 = Shader.PropertyToID("TempBuffer1");
        int _idTempBuf2 = Shader.PropertyToID("TempBuffer2");
        _cmdbuf.GetTemporaryRT(_idTempBuf1, -1, -1, 0, FilterMode.Point, RenderTextureFormat.R8);
        _cmdbuf.GetTemporaryRT(_idTempBuf2, -1, -1, 0, FilterMode.Point, RenderTextureFormat.R8);


        _cmdbuf.Blit(BuiltinRenderTextureType.GBuffer2, _idTempBuf1, GetMaterial(MTL_EDGE_DETECT));
        _cmdbuf.Blit(_idTempBuf1, BuiltinRenderTextureType.GBuffer0, GetMaterial(MTL_EDGE_APPLY));
    }

    /*
    public void OnWillRenderObject()
    {
        Camera _cam = Camera.current;

        if (null == _cam)
            return;

        RenderTextureFormat _rtf = RenderTextureFormat.R8;
        RenderTexture _rtSrc = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, _rtf);
        RenderTexture _rtDst = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, _rtf);
        
        _rtSrc.filterMode = FilterMode.Point;
        _rtDst.filterMode = FilterMode.Point;
        
        // Edge detection
        Vector4 _edgeThreshold = new Vector4();
        float _viewDist = Mathf.Min(cam.farClipPlane - cam.nearClipPlane, 16);
        //float _unused = 1024;
        _edgeThreshold.x = 1.0f / (edgeDetails * 4);
        _edgeThreshold.y = _edgeThreshold.x * (1.0f / (_viewDist * 64));
        _edgeThreshold.z = (1.0f / _viewDist);
        _edgeThreshold.w = edgeDetails;

        LoadMaterial(MTL_EDGE_DETECT).SetVector("_EdgeThreshold", _edgeThreshold);
        Graphics.Blit(_src, _rtSrc, LoadMaterial(MTL_EDGE_DETECT));

        if (edgeAA) 
        {
            for (int i = 0; i < 1; ++i)
            {
                Graphics.Blit(_rtSrc, _rtDst, m_materialEdgeDilate);
                Swap(ref _rtSrc, ref _rtDst);
                Graphics.Blit (_rtSrc, _rtDst, m_materialEdgeAA);
                Swap (ref _rtSrc, ref _rtDst);
            }
        }

        // Edge Apply
        m_materialEdgeApply.SetTexture ("_EdgeTex", _rtSrc);
        Graphics.Blit (_src, _dst, m_materialEdgeApply);

        // Clean up
        RenderTexture.ReleaseTemporary (_rtSrc);
        RenderTexture.ReleaseTemporary (_rtDst);
        
        //DebugNormalAndDepth (_src, _dst);
    }

    void DebugNormalAndDepth(RenderTexture _src, RenderTexture _dst)
    {
        Graphics.Blit (_src, _dst, m_materialNormalDepth);
    }
     * */
}

}
