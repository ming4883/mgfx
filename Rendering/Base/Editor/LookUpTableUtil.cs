using UnityEngine;
using UnityEditor;
using System;

namespace MGFX.Rendering
{
	[Serializable]
	public struct KFProxy
	{
		public float inTangent;
		public float outTangent;
		public int tangentMode;
		public float time;
		public float value;
		
		public KFProxy(Keyframe _val)
		{
			inTangent = _val.inTangent;
			outTangent = _val.outTangent;
			tangentMode = _val.tangentMode;
			time = _val.time;
			value = _val.value;
		}

		public Keyframe keyframe
		{
			get
			{
				return new Keyframe(time, value, inTangent, outTangent);
			}
		}
	}

	[Serializable]
	public struct CurveProxy
	{
		public KFProxy[] keys;
		public WrapMode preWrapMode;
		public WrapMode postWrapMode;

		public CurveProxy(AnimationCurve _val)
		{
			preWrapMode = _val.preWrapMode;
			postWrapMode = _val.postWrapMode;
			keys = new KFProxy[_val.keys.Length];

			for (int _i = 0; _i < _val.keys.Length; ++_i)
			{
				keys[_i] = new KFProxy(_val.keys[_i]);
			}
		}

		public AnimationCurve animationCurve
		{
			get
			{
				Keyframe[] _keys = new Keyframe[keys.Length];

				for (int _i = 0; _i < keys.Length; ++_i)
				{
					_keys[_i] = keys[_i].keyframe;
				}
				AnimationCurve _curve = new AnimationCurve(_keys);
				_curve.preWrapMode = preWrapMode;
				_curve.postWrapMode = postWrapMode;
				return _curve;
			}
		}
	}

	class LookUpTableUtil : RenderUtils.IUtil
	{
		AnimationCurve mCurveX = new AnimationCurve();

		TextAsset mAsset = null;
		
		public override string Name()
		{
			return "Look Up Tables";
		}

		public override void OnGUI()
		{
			OnGUIAsset();

			OnGUICurve();

			OnGUIActions();
		}

		public void OnGUIAsset()
		{
			EditorGUI.BeginChangeCheck();
			mAsset = EditorGUILayout.ObjectField(new GUIContent("Asset"), mAsset, typeof(TextAsset), false) as TextAsset;

			if (EditorGUI.EndChangeCheck())
			{
				Load();
			}
		}

		public void OnGUICurve()
		{
			Color _color = new Color(0.0f, 1.0f, 0.0f, 1.0f);
			Rect _range = new Rect(-1.0f, 0.0f, 2.0f, 1.0f);
			EditorGUILayout.CurveField(mCurveX, _color, _range, GUILayout.Height(100.0f));

		}

		public void OnGUIActions()
		{
			EditorGUILayout.Separator();

			if (GUILayout.Button("Load"))
			{
				Load();
			}

			EditorGUILayout.Separator();

			if (GUILayout.Button("Save"))
			{
				DoSave();
			}

			EditorGUILayout.Separator();

			int[] _res = new int[] { 16, 32, 64 };
			
			foreach(int _r in _res)
			{
				if (GUILayout.Button(string.Format("Generate {0}", _r)))
				{
					DoGenerate(_r);
				}
			}
		}

		private string AssetPath { get { return GetAssetPath(mAsset); } }

		private string AssetFullPath {  get { return GetAssetFullPath(mAsset); } }

		private void Load()
		{
			if (mAsset)
			{
				try
				{
					CurveProxy _proxy = JsonUtility.FromJson<CurveProxy>(mAsset.text);
					mCurveX = _proxy.animationCurve;
				}
				catch(Exception _err)
				{
					if (!string.IsNullOrEmpty(mAsset.text))
					{
						Log.E(_err);
					}
					else
					{
						Keyframe[] _keys = new Keyframe[2];
						_keys[0].time = 0;
						_keys[0].value = 0;
						_keys[1].time = 1;
						_keys[1].value = 1;
						mCurveX = new AnimationCurve(_keys);
					}
				}
				
			}
		}

		private void DoSave()
		{
			WriteAsset(mAsset, JsonUtility.ToJson(new CurveProxy(mCurveX)));
		}

		private void DoGenerate(int _res)
		{
			if (null != mCurveX)
			{
				Texture2D _tex = new Texture2D(_res, 4, TextureFormat.ARGB32, false);
				
				float _ires = 1.0f / (_res - 1.0f);
				for(int _i = 0; _i < _res; ++_i)
				{
					float _x = _i * _ires;
					_x = -1.0f + _x * 2.0f;
					float _y = mCurveX.Evaluate(_x);

					Color _clr = new Color(_y, _y, _y, _y);
					_tex.SetPixel(_i, 0, _clr);
					_tex.SetPixel(_i, 1, _clr);
					_tex.SetPixel(_i, 2, _clr);
					_tex.SetPixel(_i, 3, _clr);
					//Log.I("{0}: {1}", _x, _y);
				}

				string _path = AssetFullPath.Replace(".txt", ".png");

				System.IO.File.WriteAllBytes(_path, _tex.EncodeToPNG());

				_path = AssetPath.Replace(".txt", ".png");

				AssetDatabase.ImportAsset(_path);

				TextureImporter _imp = TextureImporter.GetAtPath(_path) as TextureImporter;
				_imp.filterMode = FilterMode.Bilinear;
				_imp.wrapMode = TextureWrapMode.Clamp;
				_imp.anisoLevel = 0;
				_imp.mipmapEnabled = false;
				_imp.sRGBTexture = true;
				_imp.textureCompression = TextureImporterCompression.Uncompressed;
				_imp.SaveAndReimport();
			}
		}

		[MenuItem("Assets/Create/MIRendering/LookUpTable")]
		private static void NewLUT()
		{
			int i = 0;
			bool _ok = false;

			string _dir = GetAssetDatabaseSelectedDir();

			while (!_ok)
			{
				string _filename = System.IO.Path.Combine(_dir, string.Format("NewLUT{0}.txt", i));
				++i;

				if (!System.IO.File.Exists(_filename))
				{
					using (var _f = System.IO.File.Open(_filename, System.IO.FileMode.CreateNew))
					{
					}
					_filename = GetAssetPath(_filename);
					Log.I("Created {0}", _filename);
					AssetDatabase.ImportAsset(_filename);
					_ok = true;
				}
			}
		}
	}
}