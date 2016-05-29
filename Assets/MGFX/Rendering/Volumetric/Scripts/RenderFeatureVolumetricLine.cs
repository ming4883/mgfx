using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

namespace MGFX
{
	[ExecuteInEditMode]
	[AddComponentMenu("Rendering/MGFX/VolumetricLine")]
	public class RenderFeatureVolumetricLine : RenderFeatureBase
	{
		[Material("MGFX/VolumetricLine")]
		private Material m_MaterialLine;

		public override void OnEnable ()
		{
			base.OnEnable();
			LoadMaterials(this);
		}

		public void UpdateMaterialProperties (Camera _cam, VolumetricLine _line)
		{
			
		}

		public override void SetupCameraEvents (Camera _cam, RenderSystem _system)
		{
			
		}
		/*
		public void OnWillRenderObject ()
		{
			var act = gameObject.activeInHierarchy && enabled;
			if (!act) {
				OnDisable ();
				return;
			}

			var cam = Camera.current;
			if (!cam)
				return;

			// create material used to render lights
			if (!m_LightMaterial) {
				m_LightMaterial = new Material (m_LightShader);
				m_LightMaterial.hideFlags = HideFlags.HideAndDontSave;
			}			

			CmdBufferEntry buf = new CmdBufferEntry ();
			if (m_Cameras.ContainsKey (cam)) {
				// use existing command buffers: clear them
				buf = m_Cameras [cam];
				buf.m_AfterLighting.Clear ();
				buf.m_BeforeAlpha.Clear ();
			} else {
				// create new command buffers
				buf.m_AfterLighting = new CommandBuffer ();
				buf.m_AfterLighting.name = "Deferred custom lights";
				buf.m_BeforeAlpha = new CommandBuffer ();
				buf.m_BeforeAlpha.name = "Draw light shapes";
				m_Cameras [cam] = buf;

				cam.AddCommandBuffer (CameraEvent.AfterLighting, buf.m_AfterLighting);
				cam.AddCommandBuffer (CameraEvent.BeforeForwardAlpha, buf.m_BeforeAlpha);
			}

			//@TODO: in a real system should cull lights, and possibly only
			// recreate the command buffer when something has changed.

			var system = CustomLightSystem.instance;

			var propParams = Shader.PropertyToID ("_CustomLightParams");
			var propColor = Shader.PropertyToID ("_CustomLightColor");
			Vector4 param = Vector4.zero;
			Matrix4x4 trs = Matrix4x4.identity;

			// construct command buffer to draw lights and compute illumination on the scene
			foreach (var o in system.m_Lights) {
				// light parameters we'll use in the shader
				param.x = o.m_TubeLength;
				param.y = o.m_Size;
				param.z = 1.0f / (o.m_Range * o.m_Range);
				param.w = (float)o.m_Kind;
				buf.m_AfterLighting.SetGlobalVector (propParams, param);
				// light color
				buf.m_AfterLighting.SetGlobalColor (propColor, o.GetLinearColor ());

				// draw sphere that covers light area, with shader
				// pass that computes illumination on the scene
				trs = Matrix4x4.TRS (o.transform.position, o.transform.rotation, new Vector3 (o.m_Range * 2, o.m_Range * 2, o.m_Range * 2));
				buf.m_AfterLighting.DrawMesh (m_SphereMesh, trs, m_LightMaterial, 0, 0);
			}

			// construct buffer to draw light shapes themselves as simple objects in the scene
			foreach (var o in system.m_Lights) {
				// light color
				buf.m_BeforeAlpha.SetGlobalColor (propColor, o.GetLinearColor ());

				// draw light "shape" itself as a small sphere/tube
				if (o.m_Kind == CustomLight.Kind.Sphere) {
					trs = Matrix4x4.TRS (o.transform.position, o.transform.rotation, new Vector3 (o.m_Size * 2, o.m_Size * 2, o.m_Size * 2));
					buf.m_BeforeAlpha.DrawMesh (m_SphereMesh, trs, m_LightMaterial, 0, 1);
				} else if (o.m_Kind == CustomLight.Kind.Tube) {
					trs = Matrix4x4.TRS (o.transform.position, o.transform.rotation, new Vector3 (o.m_TubeLength * 2, o.m_Size * 2, o.m_Size * 2));
					buf.m_BeforeAlpha.DrawMesh (m_CubeMesh, trs, m_LightMaterial, 0, 1);
				}
			}		
		}
		*/
	}
}