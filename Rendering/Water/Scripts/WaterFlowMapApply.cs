using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlowMapApply")]
	public class WaterFlowMapApply : MonoBehaviour
	{
		public WaterFlowMap m_FlowMap;
		public float m_Cycle = 32.0f;
		
		private MeshRenderer m_MeshRend;
		
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
			

			float _halfCycle = m_Cycle * 0.5f;
			float _rcpCycle = 1.0f / m_Cycle;
			_prm.x = Frac((Time.time + 0.0f) * _rcpCycle) * m_Cycle;
			_prm.y = Frac((Time.time + _halfCycle) * _rcpCycle) * m_Cycle;
			_prm.z = m_Cycle * 0.5f;
			_prm.w = 0;

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