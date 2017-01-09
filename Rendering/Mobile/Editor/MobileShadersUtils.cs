using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	[InitializeOnLoad]
	public class MobileShadersUtils
	{
		static MobileShadersUtils()
		{
			EditorApplication.delayCall += () =>
			{
				MenuItemHightQuality();
				MenuItemQualityUpdate();
			};
		}

		private const string kMobileShaderHighQuality = "MGFX.Rendering/Mobile Shaders/High Quality";
		private const string kMobileShaderMediumQuality = "MGFX.Rendering/Mobile Shaders/Medium Quality";
		private const string kMobileShaderLowQuality = "MGFX.Rendering/Mobile Shaders/Low Quality";
		private const string kMobileForceRefresh = "MGFX.Rendering/Mobile Shaders/Force Refresh";
		private const string kMobileGenReflectionMask = "MGFX.Rendering/Mobile Shaders/Generate Reflection Mask";

		public static void MenuItemQualityUpdate()
		{
			try
			{
				Menu.SetChecked(kMobileShaderHighQuality, MobileShader.IsUsingQuality(MobileShaderQuality.High));
				Menu.SetChecked(kMobileShaderMediumQuality, MobileShader.IsUsingQuality(MobileShaderQuality.Medium));
				Menu.SetChecked(kMobileShaderLowQuality, MobileShader.IsUsingQuality(MobileShaderQuality.Low));
			}
			catch (System.Exception)
			{

			}
		}

		[MenuItem(kMobileShaderHighQuality, false, 1001)]
		public static void MenuItemHightQuality()
		{
			MobileShader.SetQuality(MobileShaderQuality.High);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileShaderMediumQuality, false, 1002)]
		public static void MenuItemMediumQuality()
		{
			MobileShader.SetQuality(MobileShaderQuality.Medium);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileShaderLowQuality, false, 1003)]
		public static void MenuItemLowQuality()
		{
			MobileShader.SetQuality(MobileShaderQuality.Low);
			MenuItemQualityUpdate();
		}

		protected static List<Shader> GetMobileShaders()
		{
			List<Shader> _shaders = new List<Shader>();
			_shaders.Add(Shader.Find("MGFX/Mobile/Generic"));
			_shaders.Add(Shader.Find("MGFX/Mobile/GenericDS"));
			_shaders.Add(Shader.Find("MGFX/Mobile/Transparent"));

			return _shaders;
		}

		[MenuItem(kMobileForceRefresh, false, 1101)]
		public static void MenuItemForceRefresh()
		{
			var _allMtls = AssetDatabase.FindAssets("t:Material");

			var _shdStandard = Shader.Find("Standard");

			List<Shader> _shaders = GetMobileShaders();

			List<string> _shaderPaths = new List<string>();
			List<List<Material>> _materials = new List<List<Material>>();

			// Setup
			for (int _i = 0; _i < _shaders.Count; ++_i)
			{
				//Log.I("Processing shader {0}", _shaders[_i].name);
				_shaderPaths.Add(AssetDatabase.GetAssetPath(_shaders[_i]));
				_materials.Add(new List<Material>());
			}
			EditorUtility.DisplayProgressBar("Mobile Shader - Force Refresh", "Finding materials", 0);

			float _prog = 0;
			// Query matching materials
			foreach (var _mtlID in _allMtls)
			{
				var _mtlPath = AssetDatabase.GUIDToAssetPath(_mtlID);
				var _deps = AssetDatabase.GetDependencies(_mtlPath);

				for (int _i = 0; _i < _shaders.Count; ++_i)
				{
					if (ArrayUtility.Contains(_deps, _shaderPaths[_i]))
					{
						_materials[_i].Add(AssetDatabase.LoadAssetAtPath<Material>(_mtlPath));
						break;
					}
				}

				_prog += 1.0f;
				EditorUtility.DisplayProgressBar("Mobile Shader - Force Refresh", "Finding materials", _prog / _allMtls.Length);
			}

			// Replace to force shader refresh
			for (int _i = 0; _i < _shaders.Count; ++_i)
			{
				if (_materials[_i].Count == 0)
					continue;

				EditorUtility.DisplayProgressBar("Mobile Shader - Force Refresh", string.Format("Refreshing {0} materials with shader:{1}", _materials[_i].Count, _shaders[_i].name), (_i + 1.0f) / _shaders.Count);

				foreach (var _mtl in _materials[_i])
				{
					_mtl.shader = _shdStandard;
				}

				foreach (var _mtl in _materials[_i])
				{
					_mtl.shader = _shaders[_i];
				}
			}

			AssetDatabase.SaveAssets();
			System.GC.Collect();

			EditorUtility.ClearProgressBar();

			SceneView.RepaintAll();
		}

		[MenuItem(kMobileGenReflectionMask, false, 1102)]
		public static void MenuItemGenReflectionMask()
		{
			var _allMtls = AssetDatabase.FindAssets("t:Material");

			List<Shader> _shaders = GetMobileShaders();

			List<string> _shaderPaths = new List<string>();
			List<Texture> _textures = new List<Texture>();

			// Setup
			for (int _i = 0; _i < _shaders.Count; ++_i)
			{
				//Log.I("Processing shader {0}", _shaders[_i].name);
				_shaderPaths.Add(AssetDatabase.GetAssetPath(_shaders[_i]));
			}
			EditorUtility.DisplayProgressBar("Mobile Shader - Generate Reflection Mask", "Finding materials", 0);

			float _prog = 0;
			// Query matching materials
			foreach (var _mtlID in _allMtls)
			{
				var _mtlPath = AssetDatabase.GUIDToAssetPath(_mtlID);
				var _deps = AssetDatabase.GetDependencies(_mtlPath);

				for (int _i = 0; _i < _shaders.Count; ++_i)
				{
					if (ArrayUtility.Contains(_deps, _shaderPaths[_i]))
					{
						var _mtl = AssetDatabase.LoadAssetAtPath<Material>(_mtlPath);
						var _tex = _mtl.GetTexture("_MainTex");
						if (_tex)
							_textures.Add(_tex);
						break;
					}
				}

				_prog += 1.0f;
				EditorUtility.DisplayProgressBar("Mobile Shader - Generate Reflection Mask", "Finding materials", _prog / _allMtls.Length);
			}

			foreach (var _tex in _textures)
			{
				EditorUtility.DisplayProgressBar("Mobile Shader - Generate Reflection Mask", "Processing " + _tex.name + "...", 0);
				GenerateReflectionMask(_tex as Texture2D);
			}

			AssetDatabase.SaveAssets();
			System.GC.Collect();

			EditorUtility.ClearProgressBar();

			SceneView.RepaintAll();
		}
		
		protected static void GenerateReflectionMask(Texture2D _texture)
		{
			if (!_texture)
				return;

			var _path = AssetDatabase.GetAssetPath(_texture);
			var _import = TextureImporter.GetAtPath(_path) as TextureImporter;
			_import.isReadable = true;
			_import.alphaIsTransparency = false;
			_import.alphaSource = TextureImporterAlphaSource.FromGrayScale;

			var _compression = _import.textureCompression;
			_import.textureCompression = TextureImporterCompression.Uncompressed;
			_import.SaveAndReimport();

			_texture = AssetDatabase.LoadAssetAtPath<Texture2D>(_path);

			var _inputs = _texture.GetPixels32();

			float _avgLum = 0;

			for (int _it = 0; _it < _inputs.Length; ++_it)
			{
				Color32 _p = _inputs[_it];
				var _lum = (_p.r + _p.g + _p.b) / (255.0f * 3);
				_avgLum += _lum;
			}

			float _threshold = (_avgLum / _inputs.Length) * 0.75f;

			var _outputs = new Color32[_inputs.Length];

			for (int _it = 0; _it < _inputs.Length; ++_it)
			{
				Color32 _p = _inputs[_it];
				var _lum = (_p.r + _p.g + _p.b) / (255.0f * 3);
				if (_lum < _threshold)
				{
					_p.a = 255;
				}
				else
				{
					_p.a = 0;
				}
				_outputs[_it] = _p;
			}
			
			_texture.SetPixels32(_outputs);
			_texture.Apply();

			var _outPath = Application.dataPath + _path.Remove(0, 6);
			System.IO.File.WriteAllBytes(_outPath, _texture.EncodeToPNG());
			_import.alphaSource = TextureImporterAlphaSource.FromInput;
			_import.textureCompression = _compression;
			_import.SaveAndReimport();
		}

	}

}