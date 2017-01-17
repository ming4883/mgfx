using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace MGFX.Rendering
{
	class RenderUtils : EditorWindow
	{
		#region IUtil

		public class IUtil
		{
			public virtual string Name()
			{
				return "";
			}

			public virtual void OnGUI()
			{
			}

			public virtual void OnEnable()
			{

			}

			public virtual void OnDisable()
			{

			}

			public static string GetAssetDatabaseSelectedDir()
			{
				string _path = "";
				foreach (UnityEngine.Object obj in Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets))
				{
					_path = AssetDatabase.GetAssetPath(obj);
					if (!string.IsNullOrEmpty(_path) && System.IO.File.Exists(_path))
					{
						_path = System.IO.Path.GetDirectoryName(_path);
						break;
					}
				}

				//Log.I(_path);
				return System.IO.Path.GetFullPath(Application.dataPath + _path.Remove(0, 6));
			}

			public static string GetAssetPath(UnityEngine.Object _asset)
			{
				return AssetDatabase.GetAssetPath(_asset);
			}

			public static string GetAssetFullPath(UnityEngine.Object _asset)
			{
				return Application.dataPath + GetAssetPath(_asset).Remove(0, 6);
			}

			public static string GetAssetPath(string _fullPath)
			{
				_fullPath = System.IO.Path.GetFullPath(_fullPath).Replace('\\', '/');
				_fullPath = _fullPath.Replace(Application.dataPath, "Assets");
				return _fullPath;
			}

			public static T CreateAsset<T> (string _assetPath) where T : UnityEngine.Object
			{
				string _fullPath = Application.dataPath + _assetPath.Remove(0, 6);
				System.IO.File.WriteAllBytes(_fullPath, new byte[] { });

				AssetDatabase.ImportAsset(_assetPath);
				return AssetDatabase.LoadAssetAtPath<T>(_assetPath);
			}

			public static bool WriteAsset(UnityEngine.Object _asset, string _content)
			{
				if (!_asset)
					return false;

				string _path = GetAssetFullPath(_asset);
				Log.I("Writing to {0}", _path);
				try
				{
					System.IO.File.WriteAllText(_path, _content);
					AssetDatabase.ImportAsset(GetAssetPath(_asset));
				}
				catch (System.Exception _err)
				{
					Log.E(_err);
					return false;
				}

				return true;
			}

			protected string GetSettingsPath()
			{
				return System.IO.Path.GetDirectoryName(Application.dataPath) + "/Temp/" + "RenderUtils." + GetType().Name + ".txt";
			}

			protected bool SaveSettings(string _settings)
			{
				string _path = GetSettingsPath();
				try
				{
					System.IO.File.WriteAllText(_path, _settings);
				}
				catch(System.Exception _err)
				{
					Log.E(_err);
					return false;
				}
				return true;
			}

			protected string LoadSettings()
			{
				string _path = GetSettingsPath();
				try
				{
					return System.IO.File.ReadAllText(_path);
				}
				catch (System.IO.FileNotFoundException)
				{

				}
				catch (System.Exception _err)
				{
					Log.E(_err);
				}
				return "";
			}
		}

		void Util(IUtil _util)
		{
			if (null == mUtils)
				mUtils = new List<IUtil>();

			if (null == _util)
				return;
			
			mUtils.Add(_util);
		}

		void SetupUtils()
		{
			if (null == mUtils || mUtils.Count == 0)
			{
				Util(new LookUpTableUtil());
				Util(new LightProbessUtil());
				Util(new DitherMatrixUtil());
				Util(new ShaderGenUtil());
				//Util(CreateInstance<ShadowCascadeUtil>());
			}
		}
		
		List<IUtil> mUtils = null;

		int mSelectedUtil = 0;
		
		void OnEnable()
		{
			SetupUtils();

			foreach(var _utils in mUtils)
			{
				_utils.OnEnable();
			}
		}

		void OnDisable()
		{
			foreach (var _utils in mUtils)
			{
				_utils.OnDisable();
			}
		}

		void OnGUI()
		{
			GUILayout.Space(5.0f);

			GUILayout.BeginHorizontal();
			for (int _i = 0; _i < mUtils.Count; ++_i)
			{
				if (null != mUtils[_i] && 
					GUILayout.Toggle(mSelectedUtil == _i, mUtils[_i].Name(), EditorStyles.toolbarButton))
				{
					mSelectedUtil = _i; //Tab click
				}
			}
			GUILayout.EndHorizontal();

			GUILayout.Space(5.0f);

			if (-1 != mSelectedUtil)
			{
				GUILayout.BeginVertical();

				mUtils[mSelectedUtil].OnGUI();

				GUILayout.EndVertical();
			}

		}

		[MenuItem("MGFX/RenderUtils", false, 3001)]
		public static void MenuItem()
		{
			RenderUtils _window = EditorWindow.CreateInstance <RenderUtils>();
			_window.titleContent = new GUIContent("RenderUtils");
			_window.minSize = new Vector2(450, 360);
			_window.Show();
		}

		#endregion

		/*
		#region ShadowCascadeUtil

		class ShadowCascadeUtil : IUtil
		{
			public override string Name()
			{
				return "Shadow Cascades";
			}

			public override void OnGUI()
			{
				if (GUILayout.Button("Fix Shadow Cascades"))
				{
					QualitySettings.shadowCascade4Split = new Vector3(0.03125f, 0.0625f, 0.125f);
				}
			}
		}

		#endregion
		*/
	}
}