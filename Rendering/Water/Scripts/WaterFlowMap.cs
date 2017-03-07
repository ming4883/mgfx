using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlowMap")]
	public class WaterFlowMap : MonoBehaviour
	{
		public WaterFlow[] flows = new WaterFlow[] {
			null
		};

		public Vector2 size = new Vector2(10, 10);
		public Vector2 resolution = new Vector2(512, 512);
		public string Filename = "FlowMap.png";

		[HideInInspector]
		[System.NonSerialized]
		public WaterFlow.Sample[] cached;

		public void OnEnable()
		{
		}

		public void Start()
		{
		}

		public void OnDisable()
		{
		}

		private static Color m_LineColor = new Color(0.25f, 1.0f, 1.0f, 0.5f);

		public Matrix4x4 GetTextureMatrix()
		{
			Matrix4x4 _world2Local = transform.worldToLocalMatrix;

			Matrix4x4 _offset = Matrix4x4.Translate(new Vector3(0.5f * size.x, 0, 0.5f * size.y));

			Matrix4x4 _scale = Matrix4x4.identity;
			_scale.m00 = 1.0f / size.x;
			_scale.m11 = 1.0f;
			_scale.m22 = 1.0f / size.y;

			Matrix4x4 _swizzle = new Matrix4x4();
			_swizzle.SetRow(0, new Vector4(1, 0, 0, 0));
			_swizzle.SetRow(1, new Vector4(0, 0, 1, 0));
			_swizzle.SetRow(2, new Vector4(0, 1, 0, 0));
			_swizzle.SetRow(3, new Vector4(0, 0, 0, 1));

			return _swizzle * _scale * _offset * _world2Local;
		}

		public void OnDrawGizmos()
		{
			Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
			Gizmos.color = m_LineColor;

			Vector2 _halfSize = size * 0.5f;

			Gizmos.DrawLine(new Vector3( _halfSize.x, 0, _halfSize.y), new Vector3(-_halfSize.x, 0, _halfSize.y));
			Gizmos.DrawLine(new Vector3(-_halfSize.x, 0, _halfSize.y), new Vector3(-_halfSize.x, 0,-_halfSize.y));
			Gizmos.DrawLine(new Vector3(-_halfSize.x, 0,-_halfSize.y), new Vector3( _halfSize.x, 0,-_halfSize.y));
			Gizmos.DrawLine(new Vector3( _halfSize.x, 0,-_halfSize.y), new Vector3( _halfSize.x, 0, _halfSize.y));
		}

		public List<WaterFlow.Sample> GatherSamples(Vector2 _sampleSize)
		{
			List<WaterFlow.Sample> _samples = new List<WaterFlow.Sample>();

			foreach (var _flow in flows)
			{
				if (null == _flow || !_flow)
					continue;
				
				_flow.GatherSamples(_samples, _sampleSize);
			}

			return _samples;	
		}
	}
}