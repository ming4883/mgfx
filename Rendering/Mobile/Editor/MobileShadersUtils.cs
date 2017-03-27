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
			EditorApplication.update += MobileShadersUtilsOneTimeInit;
		}

		static void MobileShadersUtilsOneTimeInit()
		{
			MenuItemHightQuality();
			if (MenuItemQualityUpdate())
			{
				EditorApplication.update -= MobileShadersUtilsOneTimeInit;
			}
		}

		private const string kMobileShaderHighQuality = "Minv/Mobile Shaders/High Quality";
		private const string kMobileShaderMediumQuality = "Minv/Mobile Shaders/Medium Quality";
		private const string kMobileShaderLowQuality = "Minv/Mobile Shaders/Low Quality";
		private const string kMobileShaderDebugReflection = "Minv/Mobile Shaders/Debug-Reflection";
		private const string kMobileShaderDebugLighting = "Minv/Mobile Shaders/Debug-Lighting";
		private const string kMobileForceRefresh = "Minv/Mobile Shaders/Force Refresh";

		public static bool MenuItemQualityUpdate()
		{
			try
			{
				Menu.SetChecked(kMobileShaderHighQuality, MobileShaderContol.IsUsingQuality(MobileShaderQuality.High));
				Menu.SetChecked(kMobileShaderMediumQuality, MobileShaderContol.IsUsingQuality(MobileShaderQuality.Medium));
				Menu.SetChecked(kMobileShaderLowQuality, MobileShaderContol.IsUsingQuality(MobileShaderQuality.Low));
				Menu.SetChecked(kMobileShaderDebugReflection, MobileShaderContol.IsUsingQuality(MobileShaderQuality.DebugReflection));
				Menu.SetChecked(kMobileShaderDebugLighting, MobileShaderContol.IsUsingQuality(MobileShaderQuality.DebugLighting));
			}
			catch(System.Exception )
			{
				return false;
			}

			SceneView.RepaintAll();
			return true;
		}
		
		[MenuItem(kMobileShaderHighQuality, false, 1001)]
		public static void MenuItemHightQuality()
		{
			MobileShaderContol.SetQuality(MobileShaderQuality.High);
			MenuItemQualityUpdate();
		}
		
		[MenuItem(kMobileShaderMediumQuality, false, 1002)]
		public static void MenuItemMediumQuality()
		{
			MobileShaderContol.SetQuality(MobileShaderQuality.Medium);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileShaderLowQuality, false, 1003)]
		public static void MenuItemLowQuality()
		{
			MobileShaderContol.SetQuality(MobileShaderQuality.Low);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileShaderDebugReflection, false, 1101)]
		public static void MenuItemDebugReflection()
		{
			MobileShaderContol.SetQuality(MobileShaderQuality.DebugReflection);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileShaderDebugLighting, false, 1102)]
		public static void MenuItemDebugLighting()
		{
			MobileShaderContol.SetQuality(MobileShaderQuality.DebugLighting);
			MenuItemQualityUpdate();
		}

		[MenuItem(kMobileForceRefresh, false, 1201)]
		public static void MenuItemForceRefresh()
		{
			var _allMtls = AssetDatabase.FindAssets("t:Material");

			var _shdStandard = Shader.Find("Standard");

			List<Shader> _shaders = new List<Shader>();
			_shaders.Add(Shader.Find("Minv/Mobile/Generic"));
			_shaders.Add(Shader.Find("Minv/Mobile/GenericDS"));
			_shaders.Add(Shader.Find("Minv/Mobile/Transparent"));

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

				EditorUtility.DisplayProgressBar("Mobile Shader - Force Refresh", string.Format("Refreshing {0} materials with shader:{1}", _materials[_i].Count, _shaders[_i].name), (_i+1.0f) / _shaders.Count);
				
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
	}
}