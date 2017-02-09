using UnityEngine;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[ExecuteInEditMode]
	[AddComponentMenu("MGFX/WaterFlowMapApply")]
	public class WaterFlowMapApply : MonoBehaviour
	{
		public WaterFlowMap m_FlowMap;
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
			if (Application.isEditor)
				ApplyWaterFlowToMaterials();
		}

		protected void ApplyWaterFlowToMaterials()
		{
			if (null == m_FlowMap || !m_FlowMap)
				return;

			if (null == m_MeshRend || !m_MeshRend)
				return;

			var _mtx = m_FlowMap.GetTextureMatrix();

			int _id = Shader.PropertyToID("_FlowMapMatrix");

			foreach (var _mtl in m_MeshRend.sharedMaterials)
			{
				_mtl.SetMatrix(_id, _mtx);
			}
		}
	}
}