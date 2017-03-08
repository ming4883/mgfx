using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlowMapApply")]
	public class WaterFlowMapApply : MonoBehaviour
	{
		public WaterFlowMap m_FlowMap;

		public float m_Speed = 2.0f;
		public float m_Cycle = 64.0f;
		public float m_Scale = 0.1f;

		private MeshRenderer m_MeshRend;
		//public Vector4 m_Params;
		
		public void OnEnable()
		{
			m_MeshRend = GetComponent<MeshRenderer>();
		}

		public void Start()
		{
			ApplyWaterFlowToMaterials();
		}

		public void OnDisable()
		{
		}

		public void Update()
		{
			//if (Application.isEditor)
			ApplyWaterFlowToMaterials();
		}

		float Frac(float _x)
		{
			return _x - Mathf.Floor(_x);
		}

		protected void ApplyWaterFlowToMaterials()
		{
			if (null == m_FlowMap || !m_FlowMap)
				return;

			if (null == m_MeshRend || !m_MeshRend)
				return;

			var _mtx = m_FlowMap.GetTextureMatrix();
			var _prm = new Vector4();
			
			float _time = (Time.time * m_Speed) / m_Cycle;
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