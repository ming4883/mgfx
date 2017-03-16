using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/FlowControl")]
	public class FlowControl : MonoBehaviour
	{
		public FlowMap m_FlowMap;

		public float m_Speed = 2.0f;
		public float m_Cycle = 64.0f;
		public float m_Scale = 0.1f;

		private MeshRenderer m_MeshRend;
		private float m_Time;
		//public Vector4 m_Params;
		
		public void OnEnable()
		{
			m_MeshRend = GetComponent<MeshRenderer>();
			m_Time = 0;
		}

		public void Start()
		{
			m_Time = 0;
			ApplyWaterFlowToMaterials();
		}

		public void OnDisable()
		{
		}

		public void Update()
		{
			//if (Application.isEditor)
			if (Application.isPlaying)
				m_Time += Time.deltaTime;
			ApplyWaterFlowToMaterials();
		}

		float Frac(float _x)
		{
			return _x - Mathf.Floor(_x);
		}

		protected void ApplyWaterFlowToMaterials()
		{
			if (null == m_MeshRend || !m_MeshRend)
				return;

			var _mtx = Matrix4x4.identity;
			
			if (m_FlowMap != null && m_FlowMap)
				_mtx = m_FlowMap.GetTextureMatrix();

			var _prm = new Vector4();
			
			float _time = (m_Time * m_Speed) / m_Cycle;
			//_time = 0;
			_prm.x = Frac(_time);
			_prm.y = Frac(_time + 0.5f);
			_prm.z = m_Scale;
			_prm.w = 0;

			//m_Params = _prm;

			int _idFlowMtx = Shader.PropertyToID("_FlowMapMatrix");
			int _idFlowPrm = Shader.PropertyToID("_FlowMapParams");

			foreach (var _mtl in m_MeshRend.sharedMaterials)
			{
				_mtl.SetMatrix(_idFlowMtx, _mtx);
				_mtl.SetVector(_idFlowPrm, _prm);
			}
		}
	}
}