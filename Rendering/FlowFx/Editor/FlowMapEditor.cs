using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections.Generic;

namespace MGFX.Rendering
{
    [CustomEditor(typeof(FlowMap))]
    public class FlowMapEditor : Editor
    {
        private GUIContent kShowSampleText = new GUIContent("Show Samples");
        private GUIContent kBakeText = new GUIContent("Bake");
        private static bool m_ShowSamples = false;
        private static Color m_CachedColor = new Color(1.0f, 0.5f, 0.5f, 0.5f);
        private static Color m_SampleColor = new Color(1, 1, 1, 0.5f);
        private static Color m_OffsetUColor = new Color(1, 0, 0, 0.5f);
        private static Color m_OffsetVColor = new Color(0, 1, 0, 0.5f);

        public override void OnInspectorGUI()
        {
            base.DrawDefaultInspector();

            EditorGUILayout.Separator();
            EditorGUI.BeginChangeCheck();
            m_ShowSamples = EditorGUILayout.Toggle(kShowSampleText, m_ShowSamples);
            if (EditorGUI.EndChangeCheck())
            {
                SceneView.RepaintAll();
            }

            EditorGUILayout.Separator();

            if (GUILayout.Button(kBakeText))
            {
                Bake(target as FlowMap);
            }
        }

        public void OnSceneGUI()
        {
            var _inst = target as FlowMap;

            Vector2 _offset = _inst.size * -0.5f;

            {
                Vector3 _pt = new Vector3(_offset.x, 0, _offset.y);
                _pt = _inst.transform.TransformPoint(_pt);
                float _scale = HandleUtility.GetHandleSize(_pt) * 0.125f;

                Vector3 _du = Vector3.right;
                Vector3 _dv = Vector3.forward;

                _du = _inst.transform.TransformVector(_du);
                _dv = _inst.transform.TransformVector(_dv);

                Handles.color = m_OffsetUColor;
                Handles.ConeHandleCap(0, _pt + _du * _scale, Quaternion.FromToRotation(Vector3.forward, _du), _scale, EventType.Repaint);

                Handles.color = m_OffsetVColor;
                Handles.ConeHandleCap(0, _pt + _dv * _scale, Quaternion.FromToRotation(Vector3.forward, _dv), _scale, EventType.Repaint);
            }

            if (m_ShowSamples)
            {
                int _tw = Mathf.NextPowerOfTwo((int)_inst.resolution.x);
                int _th = Mathf.NextPowerOfTwo((int)_inst.resolution.y);

                Vector2 _delta = new Vector2(_inst.size.x / _tw, _inst.size.y / _th);
                List<Flow.Sample> _samples = _inst.GatherSamples(_delta * _inst.minimumDistance);

                if (_samples.Count > 0)
                {
                    Handles.color = m_SampleColor;

                    for (int _it = 0; _it < _samples.Count; ++_it)
                    {
                        var _samp = _samples[_it];
                        float _scale = HandleUtility.GetHandleSize(_samp.position) * 0.0625f;

                        if (_samp.direction.sqrMagnitude > 0)
                            Handles.ConeHandleCap(0, _samp.position, Quaternion.FromToRotation(Vector3.forward, _samp.direction), _scale, EventType.Repaint);
                    }
                }

                if (_inst.cached != null)
                {
                    Handles.color = m_CachedColor;
                    foreach (var _samp in _inst.cached)
                    {
                        float _scale = HandleUtility.GetHandleSize(_samp.position) * 0.0625f;

                        if (_samp.direction.sqrMagnitude > 0)
                            Handles.ConeHandleCap(0, _samp.position, Quaternion.FromToRotation(Vector3.forward, _samp.direction), _scale, EventType.Repaint);
                    }
                }

            } // if (m_ShowSamples)

        } // OnSceneGUI

        private void Bake(FlowMap _inst)
        {
            int _tw = Mathf.NextPowerOfTwo((int)_inst.resolution.x);
            int _th = Mathf.NextPowerOfTwo((int)_inst.resolution.y);

            Vector2 _delta = new Vector2(_inst.size.x / _tw, _inst.size.y / _th);

            List<Flow.Sample> _samples = _inst.GatherSamples(_delta * _inst.minimumDistance);

            if (_samples.Count == 0)
                return;

            Flow.Sample[,] _outputs = new Flow.Sample[_tw, _th];
            InterpolateSamples(_inst, _samples, _delta, _outputs);

            Texture2D _tex = EncodeToTexture(_inst, _outputs);
            
            SaveTexture(_inst, _tex);
        } // Bake

        private KdTree CreateKdTree(List<Flow.Sample> _samples)
        {
            KdTree.Entry[] _kdEnt = new KdTree.Entry[_samples.Count];
            for (int _it = 0; _it < _samples.Count; ++_it)
            {
                _kdEnt[_it] = new KdTree.Entry(_samples[_it].position, _it);
            }

            KdTree _kdTree = new KdTree();
            _kdTree.build(_kdEnt);

            return _kdTree;
        }

        private void InterpolateSamples(FlowMap _inst, List<Flow.Sample> _samples, Vector2 _delta, Flow.Sample[,] _outputs)
        {
            var _transform = _inst.transform;
            var _offset = _inst.size * -0.5f + _delta * 0.5f;

            int _w = _outputs.GetUpperBound(0) + 1;
            int _h = _outputs.GetUpperBound(1) + 1;
            
            KdTree _kdTree = CreateKdTree(_samples);
            KdTree.KQueue _kqueue = new KdTree.KQueue(3);

            for (int _y = 0; _y < _h; ++_y)
            {
                for (int _x = 0; _x < _w; ++_x)
                {
                    Vector2 _pos = _offset + Vector2.Scale(_delta, new Vector2(_x, _y));
                    Vector3 _worldPos = _transform.TransformPoint(new Vector3(_pos.x, 0, _pos.y));

                    Flow.Sample _outSamp = new Flow.Sample()
                    {
                        position = _worldPos,
                        direction = Vector3.zero,
                    };

                    int[] _knn = _kdTree.knearest(_kqueue, _worldPos, 3);
                    if (_knn.Length == 3)
                    {
                        var _sampA = _samples[_knn[0]];
                        var _sampB = _samples[_knn[1]];
                        var _sampC = _samples[_knn[2]];
                        Vector3 _weights;
                        Vector3 _dir = _sampA.direction;

                        if (Triangle.GetBarycentricCoords(out _weights, _sampA.position, _sampB.position, _sampC.position, _worldPos))
                        {
                            _dir = (_sampA.direction * _weights.x) + (_sampB.direction * _weights.y) + (_sampC.direction * _weights.z);
                        }

                        _outSamp.direction = _dir;
                    }

                    _outputs[_x, _y] = _outSamp;

                }
            }
        }

        private Texture2D EncodeToTexture(FlowMap _inst, Flow.Sample[,] _outputs)
        {
            Texture2D _tex = new Texture2D(_outputs.GetUpperBound(0)+1, _outputs.GetUpperBound(1)+1, TextureFormat.ARGB32, false);
            _inst.cached = new Flow.Sample[_tex.width * _tex.height];

            int _c = 0;

            for (int _y = 0; _y < _tex.height; ++_y)
            {
                for (int _x = 0; _x < _tex.width; ++_x)
                {
                    _inst.cached[_c] = _outputs[_x, _y];

                    Color _clr = new Color(0.5f, 0.5f, 0.5f, 0.0f);
                    Vector3 _dir = _outputs[_x, _y].direction;

                    _clr.r = _dir.x * 0.5f + 0.5f;
                    _clr.g = _dir.z * 0.5f + 0.5f;
                    //_clr.b = _dir.y * 0.5f + 0.5f;
                    _clr.b = 0.5f;
                    _clr.a = 1.0f;
#if false
					// debug uv mapping
					_clr.r = (float)_x / _tw;
					_clr.g = (float)_y / _th;
					_clr.b = 0;
#endif
                    _tex.SetPixel(_x, _y, _clr);

                    _c++;
                }
            }

            if (_inst.blurSize > 0 && _inst.blurIterations > 0)
            {
                Texture2D _texBlurred = new Blur().FastBlur(_tex, _inst.blurSize, _inst.blurIterations);
                DestroyImmediate(_tex);
                _tex = _texBlurred;
            }
            
            return _tex;
        }

        private void SaveTexture(FlowMap _inst, Texture2D _tex)
        {
            Scene _scene = SceneManager.GetActiveScene();
            string _path = System.IO.Path.GetDirectoryName(_scene.path);
            _path = _path + "/" + _inst.Filename;

            System.IO.File.WriteAllBytes(Application.dataPath + _path.Remove(0, 6), _tex.EncodeToPNG());

            AssetDatabase.ImportAsset(_path);

            TextureImporter _imp = TextureImporter.GetAtPath(_path) as TextureImporter;
            _imp.filterMode = FilterMode.Bilinear;
            _imp.wrapMode = TextureWrapMode.Clamp;
            _imp.anisoLevel = 0;
            _imp.mipmapEnabled = false;
            _imp.sRGBTexture = false;
            _imp.textureCompression = TextureImporterCompression.Uncompressed;
            _imp.SaveAndReimport();
        }

    }
}