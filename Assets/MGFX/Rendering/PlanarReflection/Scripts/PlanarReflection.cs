using UnityEngine;
using System.Collections;

// This is in fact just the Water script from Pro Standard Assets,
// just with refraction stuff removed.
namespace MGFX
{
	[ExecuteInEditMode ()]
	[AddComponentMenu ("Rendering/MGFX/PlanarReflection")]
	public class PlanarReflection : MonoBehaviour
	{
		public bool m_DisablePixelLights = false;
		public int m_TextureResolution = 512;
		public float m_MinClipOffset = 0.01f;
		public LayerMask m_ReflectLayers = -1;

		private Vector3 m_calculatedNormal = Vector3.up;
		private float m_calculatedClipOffset = 0.01f;

		private Hashtable m_ReflectionCameras = new Hashtable ();
		//Camera -> Reflection Camera table

		private RenderTexture m_ReflectionTexture = null;
		private int m_OldReflectionTextureSize = 0;

		private static bool s_InsideRendering = false;

		private bool BeginReflection()
		{
			//Safeguard from recursive reflections.        
			if (s_InsideRendering)
				return false;

			s_InsideRendering = true;
			return true;
		}

		private void EndReflection()
		{
			s_InsideRendering = false;
		}

		private void OnDrawGizmosSelected()
		{
			var _c = transform.position;
			Gizmos.color = Color.cyan;
			Gizmos.DrawWireCube (_c, new Vector3 (m_calculatedClipOffset, m_calculatedClipOffset, m_calculatedClipOffset));
			Gizmos.DrawLine (_c, _c + m_calculatedNormal);
		}

		//This is called when it's known that the object will be rendered by some
		//camera. We render reflections and do other updates here.
		//Because the script executes in edit mode, reflections for the scene view
		//camera will just work!
		public void OnWillRenderObject()
		{
			if (!enabled || !GetComponent<Renderer> () || !GetComponent<Renderer> ().sharedMaterial || !GetComponent<Renderer> ().enabled)
				return;

			Camera cam = Camera.current;
			if (!cam)
				return;
			
			if (!BeginReflection ())
				return;
			
			UpdateReflectionParams ();

			Camera reflectionCamera;
			CreateSurfaceObjects (cam, out reflectionCamera);

			UpdateCameraModes (cam, reflectionCamera);
			UpdateCameraMatrics (cam, reflectionCamera, transform.position, m_calculatedNormal);

			//Optionally disable pixel lights for reflection
			int oldPixelLightCount = QualitySettings.pixelLightCount;
			if (m_DisablePixelLights)
				QualitySettings.pixelLightCount = 0;

			GL.invertCulling = true;

			//Render reflection
			reflectionCamera.Render ();
			GL.invertCulling = false;

			//Restore pixel light count
			if (m_DisablePixelLights)
				QualitySettings.pixelLightCount = oldPixelLightCount;
			
			EndReflection ();

			UpdateMaterials ();
		}

		//Cleanup all the objects we possibly have created
		void OnDisable()
		{
			if (m_ReflectionTexture)
			{
				DestroyImmediate (m_ReflectionTexture);
				m_ReflectionTexture = null;
			}
			foreach (DictionaryEntry kvp in m_ReflectionCameras)
				DestroyImmediate (((Camera)kvp.Value).gameObject);
			m_ReflectionCameras.Clear ();
		}

		void UpdateMaterials()
		{
			Material[] materials = GetComponent<Renderer> ().sharedMaterials;
			foreach (Material mat in materials)
			{
				if (mat.HasProperty ("_ReflectionTex"))
					mat.SetTexture ("_ReflectionTex", m_ReflectionTexture);
			}
		}

		public void UpdateReflectionParams()
		{
			MeshFilter meshFilter = GetComponent<MeshFilter> ();
			m_calculatedClipOffset = m_MinClipOffset;
			m_calculatedNormal = transform.forward;

			if (meshFilter != null)
			{
				var ext = meshFilter.sharedMesh.bounds.extents;

				if (ext.x < ext.y && ext.x < ext.z)
				{
					m_calculatedNormal = transform.right;
					m_calculatedClipOffset = ext.x;
				} else if (ext.y < ext.x && ext.y < ext.z)
				{
					m_calculatedNormal = transform.up;
					m_calculatedClipOffset = ext.y;
				} else
				{
					m_calculatedNormal = transform.forward;
					m_calculatedClipOffset = ext.z;
				}
			}

			if (m_MinClipOffset > 0)
			{
				m_calculatedClipOffset = Mathf.Max (m_MinClipOffset, m_calculatedClipOffset);
			}
			else
			{
				m_calculatedClipOffset = Mathf.Min (m_MinClipOffset, -m_calculatedClipOffset);
			}
				
		}

		private void UpdateCameraModes(Camera src, Camera dest)
		{
			if (dest == null)
				return;
			//set camera to clear the same way as current camera
			dest.clearFlags = src.clearFlags;
			dest.backgroundColor = src.backgroundColor;        
			if (src.clearFlags == CameraClearFlags.Skybox)
			{
				Skybox sky = src.GetComponent (typeof(Skybox)) as Skybox;
				Skybox mysky = dest.GetComponent (typeof(Skybox)) as Skybox;
				if (!sky || !sky.material)
				{
					mysky.enabled = false;
				} else
				{
					mysky.enabled = true;
					mysky.material = sky.material;
				}
			}
			//update other values to match current camera.
			//even if we are supplying custom camera&projection matrices,
			//some of values are used elsewhere (e.g. skybox uses far plane)
			dest.farClipPlane = src.farClipPlane;
			dest.nearClipPlane = src.nearClipPlane;
			dest.orthographic = src.orthographic;
			dest.fieldOfView = src.fieldOfView;
			dest.aspect = src.aspect;
			dest.renderingPath = src.actualRenderingPath;
			dest.orthographicSize = src.orthographicSize;
		}

		private void UpdateCameraMatrics(Camera src, Camera dst, Vector3 mirrorPos, Vector3 mirrorDir)
		{
			Plane reflectionPlane = ReflectionPlane (src.transform.position, mirrorPos, mirrorDir, m_calculatedClipOffset);

			Matrix4x4 reflection;
			CalculateReflectionMatrix (out reflection, reflectionPlane);

			// http://docs.unity3d.com/ScriptReference/Camera-worldToCameraMatrix.html
			dst.worldToCameraMatrix = src.worldToCameraMatrix * reflection;

			//Setup oblique projection matrix so that near plane is our reflection plane.
			//This way we clip everything below/above it for free.
			Matrix4x4 projection = src.projectionMatrix;
			CalculateObliqueMatrix (ref projection, CameraSpacePlane (dst, mirrorPos, reflectionPlane.normal, 1.0f, m_calculatedClipOffset));
			dst.projectionMatrix = projection;

			dst.cullingMask = ~(1 << 4) & m_ReflectLayers.value; //never render water layer
			dst.targetTexture = m_ReflectionTexture;
		}

		//On-demand create any objects we need
		private void CreateSurfaceObjects(Camera currentCamera, out Camera reflectionCamera)
		{
			reflectionCamera = null;

			//Reflection render texture
			if (!m_ReflectionTexture || m_OldReflectionTextureSize != m_TextureResolution)
			{
				if (m_ReflectionTexture)
					DestroyImmediate (m_ReflectionTexture);
				m_ReflectionTexture = new RenderTexture (m_TextureResolution, m_TextureResolution, 16);
				m_ReflectionTexture.name = "__PlanarReflection" + GetInstanceID ();
				m_ReflectionTexture.isPowerOfTwo = true;
				m_ReflectionTexture.hideFlags = HideFlags.DontSave;
				m_OldReflectionTextureSize = m_TextureResolution;
			}

			//Camera for reflection
			reflectionCamera = m_ReflectionCameras [currentCamera] as Camera;
			if (!reflectionCamera) //catch both not-in-dictionary and in-dictionary-but-deleted-GO
			{
				GameObject go = new GameObject ("PlanarReflectionCamera" + GetInstanceID () + " for " + currentCamera.GetInstanceID (), typeof(Camera), typeof(Skybox));
				reflectionCamera = go.GetComponent<Camera> ();
				reflectionCamera.enabled = false;
				reflectionCamera.transform.position = transform.position;
				reflectionCamera.transform.rotation = transform.rotation;
				reflectionCamera.gameObject.AddComponent<FlareLayer> ();
				go.hideFlags = HideFlags.HideAndDontSave;
				m_ReflectionCameras [currentCamera] = reflectionCamera;
			}        
		}

		//Extended sign: returns -1, 0 or 1 based on sign of a
		private static float sgn(float a)
		{
			if (a > 0.0f)
				return 1.0f;
			if (a < 0.0f)
				return -1.0f;
			return 0.0f;
		}

		//Calculate the plane for reflection in World Space.
		private static Plane ReflectionPlane(Vector3 viewerPos, Vector3 mirrorPos, Vector3 mirrorDir, float clipOffset)
		{
			float d = -Vector3.Dot (mirrorDir, mirrorPos) - clipOffset;
			Plane reflectionPlane = new Plane (mirrorDir, d);

			if (!reflectionPlane.GetSide (viewerPos))
			{
				// Flip the reflection plane if the camera is behide
				mirrorDir = -mirrorDir;
				d = -Vector3.Dot (mirrorDir, mirrorPos) - clipOffset;
				reflectionPlane = new Plane (mirrorDir, d);
			}

			return reflectionPlane;
		}


		//Given position/normal of the plane, calculates plane in camera space.
		private static Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign, float clipOffset)
		{
			Vector3 offsetPos = pos + normal * clipOffset;
			Matrix4x4 m = cam.worldToCameraMatrix;
			Vector3 cpos = m.MultiplyPoint (offsetPos);
			Vector3 cnormal = m.MultiplyVector (normal).normalized * sideSign;
			return new Vector4 (cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot (cpos, cnormal));
		}

		//Adjusts the given projection matrix so that near plane is the given clipPlane
		//clipPlane is given in camera space. See article in Game Programming Gems 5 and
		//http://aras-p.info/texts/obliqueortho.html
		private static void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
		{
			Vector4 q = projection.inverse * new Vector4 (
				            sgn (clipPlane.x),
				            sgn (clipPlane.y),
				            1.0f,
				            1.0f
			            );
			Vector4 c = clipPlane * (2.0F / (Vector4.Dot (clipPlane, q)));
			//third row = clip plane - fourth row
			projection [2] = c.x - projection [3];
			projection [6] = c.y - projection [7];
			projection [10] = c.z - projection [11];
			projection [14] = c.w - projection [15];
		}

		//Calculates reflection matrix around the given plane
		private static void CalculateReflectionMatrix(out Matrix4x4 reflectionMat, Plane plane)
		{
			Vector4 p = new Vector4 (plane.normal.x, plane.normal.y, plane.normal.z, plane.distance);
			reflectionMat.m00 = (1F - 2F * p [0] * p [0]);
			reflectionMat.m01 = (-2F * p [0] * p [1]);
			reflectionMat.m02 = (-2F * p [0] * p [2]);
			reflectionMat.m03 = (-2F * p [3] * p [0]);

			reflectionMat.m10 = (-2F * p [1] * p [0]);
			reflectionMat.m11 = (1F - 2F * p [1] * p [1]);
			reflectionMat.m12 = (-2F * p [1] * p [2]);
			reflectionMat.m13 = (-2F * p [3] * p [1]);

			reflectionMat.m20 = (-2F * p [2] * p [0]);
			reflectionMat.m21 = (-2F * p [2] * p [1]);
			reflectionMat.m22 = (1F - 2F * p [2] * p [2]);
			reflectionMat.m23 = (-2F * p [3] * p [2]);

			reflectionMat.m30 = 0F;
			reflectionMat.m31 = 0F;
			reflectionMat.m32 = 0F;
			reflectionMat.m33 = 1F;
		}
	}


}