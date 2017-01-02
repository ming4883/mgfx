using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Collections;

namespace MGFX.Rendering
{
	public class LightProbePlacement
	{
		public float mergeDistance = 2.0f;
		public LightProbeGroup probeObject;
		public int layers = 3;
		public float layerHeight = 5.0f;

		public void PlaceProbes()
		{
			if (probeObject != null)
			{
				probeObject.transform.position = Vector3.zero;

				UnityEngine.AI.NavMeshTriangulation navMesh = UnityEngine.AI.NavMesh.CalculateTriangulation();

				Vector3[] _pos = navMesh.vertices;

				// construct kd tree
				KdTree _kd = new KdTree();
				KdTree.Entry[] _kdents = new KdTree.Entry[_pos.Length];
				for (int i = 0; i < _kdents.Length; ++i)
					_kdents[i] = new KdTree.Entry(_pos[i], i);
				_kd.build(_kdents);
				
				List<ProbeGenPoint> probeGen = new List<ProbeGenPoint>();
				foreach (Vector3 _pt in _pos)
				{
					probeGen.Add(new ProbeGenPoint(_pt, false));
				}

				List<Vector3> mergedProbes = new List<Vector3>();

				var _watch = new System.Diagnostics.Stopwatch();
				_watch.Start();

				var _queue = new KdTree.RQueue();

				for (int i = 0; i < probeGen.Count; ++i)
				{
					ProbeGenPoint _pro = probeGen[i];

					if (_pro.used)
						continue;

					float _mergedCnt = 1.0f;
					Vector3 _mergedPos = _pro.pos;
					
					var _neighbor = _kd.rquery(_queue, _pro.pos, mergeDistance);
					
					for (int n = 0; n < _neighbor.Length; ++n)
					{
						if (_neighbor[n] == i)
							continue;

						ProbeGenPoint _subject = probeGen[_neighbor[n]];
						_subject.used = true;
					}

					if (_mergedCnt > 1.0f)
					{
						_mergedPos *= 1.0f / _mergedCnt;
					}
					
					for (int l = 0; l < layers; ++l)
					{
						mergedProbes.Add(_mergedPos + Vector3.up * (layerHeight * l));
					}

					_pro.used = true;
				}

				_watch.Stop();
				Log.I("merging completed in {0} ms", _watch.ElapsedMilliseconds);

				probeObject.probePositions = mergedProbes.ToArray();
			}
		}
	}

	public class ProbeGenPoint
	{

		public Vector3 pos;
		public bool used = false;

		public ProbeGenPoint(Vector3 p, bool u)
		{
			pos = p;
			used = u;
		}

	}
}