using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace MGFX.Rendering
{

	[ExecuteInEditMode]
	[RequireComponent (typeof(RenderSystem))]
	public class RenderFeatureBase : MonoBehaviour
	{
		#region Material Management

		[System.AttributeUsage (System.AttributeTargets.Field)]
		public class MaterialAttribute : System.Attribute
		{
			public HashID Id;

			public MaterialAttribute (string _name)
			{
				Id = new HashID(_name);
			}
		}

		public static int LoadMaterials (RenderFeatureBase _inst)
		{
			int _cnt = 0;
			var _flags = System.Reflection.BindingFlags.Instance 
				| System.Reflection.BindingFlags.NonPublic
				| System.Reflection.BindingFlags.Public;
			
			foreach (var _field in _inst.GetType ().GetFields (_flags))
			{
				foreach (var _attr in _field.GetCustomAttributes (true))
				{
					var _mtlAttr = _attr as MaterialAttribute;
					if (null != _mtlAttr && _field.FieldType == typeof(Material))
					{
						var _mtl = _inst.LoadMaterial (_mtlAttr.Id);
						_field.SetValue (_inst, _mtl);
						++_cnt;
					}
				}
			}
			return _cnt;
		}

		protected HashDict<Material> m_Materials = new HashDict<Material> ();

		protected Material LoadMaterial (HashID _id)
		{
			var _shaderName = _id.ToString ();

			if (m_Materials.ContainsKey (_id))
			{
				Debug.LogWarningFormat ("possible duplicated LoadMaterial {0}", _shaderName);
				return m_Materials [_id];
			}

			Shader _shader = Shader.Find (_shaderName);
			if (null == _shader)
			{
				Debug.LogErrorFormat ("shader {0} not found", _shaderName);
				return null;
			}

			var _mtl = new Material (_shader);
			_mtl.hideFlags = HideFlags.HideAndDontSave;
			m_Materials.Add (_id, _mtl);
			return _mtl;
		}

		protected Material GetMaterial (HashID _id)
		{
			if (!m_Materials.ContainsKey (_id))
				return null;

			return m_Materials [_id];
		}


		#endregion
		
		[HideInInspector]
		public bool affectSceneCamera = true;
		
		#region MonoBehaviour related

		public virtual void OnEnable ()
		{
            LoadMaterials(this);
		}

		public void OnDisable ()
		{
			Cleanup ();
		}

        public virtual void Reset()
        {
            LoadMaterials(this);
        }

		protected virtual void Cleanup ()
		{
			foreach (var _pair in m_Materials)
			{
				Material.DestroyImmediate (_pair.Value);
			}

			m_Materials.Clear ();

		}
		
		public virtual void OnPreRenderCamera (Camera _cam, RenderSystem _system)
		{
			var _active = gameObject.activeInHierarchy && enabled;
			if (!_active)
			{
				Cleanup ();
				return;
			}
			
			SetupCameraEvents (_cam, _system);
		}

		public virtual void SetupCameraEvents (Camera _cam, RenderSystem _system)
		{

		}

		#endregion
		
		#region Utils

		protected RenderSystem FindRenderSystem()
		{
			return gameObject.GetComponent<RenderSystem>();
		}

		protected static void Swap (ref RenderTexture _a, ref RenderTexture _b)
		{
			RenderTexture _t = _a;
			_a = _b;
			_b = _t;
		}

		protected static void Swap (ref int _a, ref int _b)
		{
			int _t = _a;
			_a = _b;
			_b = _t;
		}

		protected static void SetFlip (CommandBuffer _cmdBuf, Camera _cam)
		{
			bool _flip = _cam.targetTexture == null;
			_flip = false;
			_cmdBuf.SetGlobalFloat ("_Flip", (true == _flip) ? -1 : 1);
		}


		const string kGeomBufferName = "GeomBuffer";

		protected void RenderGeomBuffer(RenderSystem _system, Camera _cam, Shader _shader, string _tags, Color _clearColor, bool _highPrecision)
		{
			var _lastRT = RenderTexture.active;

			var _camBuffers = _system.CameraBuffers;

			var _bufName = string.Format("{0}@{1}", kGeomBufferName, GetType().Name);

			var _camBuf = _camBuffers.AllocForRender(_cam, _bufName, 32, _highPrecision ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

			RenderTexture.active = _camBuf.Rtt;

			var _camRtt = _camBuffers.PrepareForRender(_cam, this.gameObject);
			_camRtt.backgroundColor = _clearColor;
			_camRtt.targetTexture = _camBuf.Rtt;
			_camRtt.RenderWithShader(_shader, _tags);

			_camRtt.targetTexture = null;
			RenderTexture.active = _lastRT;
		}

		protected RenderTexture GetGeomBuffer(RenderSystem _system, Camera _cam)
		{
			var _bufName = string.Format("{0}@{1}", kGeomBufferName, GetType().Name);
			return _system.CameraBuffers.GetRtt(_cam, _bufName);
		}


		const string kFrameBufferName = "FrameBuffer";

		protected RenderTexture GrabFrameBuffer(RenderSystem _system, Camera _cam, CommandBuffer _commands, Material _mtl, int _pass)
		{
			var _camBuffers = _system.CameraBuffers;
			var _camBuf = _camBuffers.AllocForPostProc(_cam, kFrameBufferName, _cam.allowHDR ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
			_camBuf.Rtt.filterMode = FilterMode.Point;


			if (null != _mtl)
				_commands.Blit(BuiltinRenderTextureType.CameraTarget, _camBuf.Rtt, _mtl, _pass);
			else
				_commands.Blit(BuiltinRenderTextureType.CameraTarget, _camBuf.Rtt);

			return _camBuf.Rtt;
		}

		protected RenderTexture GrabFrameBuffer(RenderSystem _system, Camera _cam, CommandBuffer _commands)
		{
			return GrabFrameBuffer(_system, _cam, _commands, null, 0);
		}

		protected RenderTexture GetFrameBuffer(RenderSystem _system, Camera _cam)
		{
			return _system.CameraBuffers.GetRtt(_cam, kFrameBufferName);
		}

		#endregion
	}

}
