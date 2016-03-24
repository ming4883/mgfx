using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;
namespace Mud
{

[ExecuteInEditMode]
public class RenderSystemBase : MonoBehaviour
{
    protected class EvtCmdBuf
    {
        public CameraEvent Event;
        public CommandBuffer CommandBuffer;
        
    }

    protected class EvtCmdBufList :List<EvtCmdBuf>
    {

    }

    protected class CameraCommands : Dictionary<Camera, EvtCmdBufList> 
    {

    }

    protected HashDict<Material> m_Materials = new HashDict<Material>();
    protected CameraCommands m_CameraCommands = new CameraCommands();

    public void OnDisable()
    {
        Cleanup();
    }

    public virtual void Cleanup()
    {
        foreach (var _pair in m_Materials)
        {
            Material.DestroyImmediate(_pair.Value);
        }

        foreach (var _pair in m_CameraCommands)
        {
            foreach (var _evtCmds in _pair.Value)
            {
                _pair.Key.RemoveCommandBuffer(_evtCmds.Event, _evtCmds.CommandBuffer);
            }
        }
    }

    protected Material LoadMaterial(HashID _id)
    {
        var _shaderName = _id.ToString();

        if (m_Materials.ContainsKey(_id))
        {
            Debug.LogWarningFormat("possible duplicated LoadMaterial {0}", _shaderName);
            return m_Materials[_id];
        }

        Shader _shader = Shader.Find(_shaderName);
        if (null == _shader)
        {
            Debug.LogErrorFormat("shader {0} not found", _shaderName);
            return null;
        }

        var _mtl = new Material(_shader);
        m_Materials.Add(_id, _mtl);
        return _mtl;
    }

    protected Material GetMaterial(HashID _id)
    {
        if (!m_Materials.ContainsKey(_id))
            return null;

        return m_Materials[_id];
    }

    protected virtual void OnSetupCameraEvents(Camera _cam)
    {
    }

    protected static void Swap(ref RenderTexture _a, ref RenderTexture _b)
    {
        RenderTexture _t = _a;
        _a = _b;
        _b = _t;
    }

    protected static void Swap(ref int _a, ref int _b)
    {
        int _t = _a;
        _a = _b;
        _b = _t;
    }

    protected CommandBuffer AddCommandBufferForEvent(Camera _cam, CameraEvent _event, string _name)
    {
        CommandBuffer _buf = new CommandBuffer();
        _buf.name = _name;
        _cam.AddCommandBuffer(_event, _buf);

        m_CameraCommands[_cam].Add(new EvtCmdBuf { Event = _event, CommandBuffer = _buf });

        return _buf;
    }

    public void OnWillRenderObject()
    {
        var _active = gameObject.activeInHierarchy && enabled;
        if (!_active)
        {
            Cleanup();
            return;
        }

        var _cam = Camera.current;
        if (null == _cam)
            return;

        // Did we already add the command buffer on this camera? Nothing to do then.
        if (m_CameraCommands.ContainsKey(_cam))
            return;

        m_CameraCommands[_cam] = new EvtCmdBufList();
        OnSetupCameraEvents(_cam);
    }

}

}
