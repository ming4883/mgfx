using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;

namespace Mud
{
	class AssetsImportWindow : EditorWindow
	{
	    class Entry
	    {
	        public string dir;
	        public bool selected;

	        public string name
	        {
	            get { return System.IO.Path.GetFileName(dir); }
	        }
	    }

	    List<Entry> m_entries = new List<Entry>();
	    
	    Dictionary<string, bool> buildinTypes = new Dictionary<string,bool>();
	    Dictionary<string, bool> excludes = new Dictionary<string, bool>();
	    bool cleanImport = false;

	    [MenuItem("Mud/Assets/Import", false, 1000)]
	    public static void MenuItem()
	    {
	        int _w = 600;
	        int _h = 300;

	        AssetsImportWindow _window = AssetsImportWindow.CreateInstance <AssetsImportWindow>();
	        _window.InitBuildInTypes();
	        _window.InitExcludes();
	        _window.position = new Rect((Screen.width - _w) / 2, (Screen.height - _h) / 2, _w, _h);
	        _window.FindEntries();

	        if (_window.m_entries.Count > 0)
	            _window.ShowUtility();
	    }
	    
	    void InitBuildInTypes()
	    {
	        buildinTypes[".png"] = true;
	        buildinTypes[".tga"] = true;
	        buildinTypes[".jpg"] = true;
	        buildinTypes[".gif"] = true;
	        buildinTypes[".psd"] = true;
	        buildinTypes[".fbx"] = true;
	        buildinTypes[".json"] = true;
	        buildinTypes[".txt"] = true;
	    }
	    
	    void InitExcludes()
	    {
	        excludes[".psd"] = true;
	        excludes[".canx"] = true;
	        excludes[".cmox"] = true;
	        excludes[".db"] = true;
	        excludes[".max"] = true;
	        excludes[".maya"] = true;
	    }

	    Vector2 m_scrollPos1 = Vector2.zero;
	    void OnGUI()
	    {
	        cleanImport = EditorGUILayout.Toggle("Clean before Import", cleanImport);

	        EditorGUILayout.LabelField("Select folders to import");
	        EditorGUILayout.Separator();

	        m_scrollPos1 = EditorGUILayout.BeginScrollView(m_scrollPos1, EditorStyles.helpBox);

	        var _options = new GUILayoutOption[] {};
	        foreach(Entry _ent in m_entries)
	        {
	            _ent.selected = EditorGUILayout.ToggleLeft(_ent.dir, _ent.selected, _options);
	        }

	        EditorGUILayout.EndScrollView();

	        EditorGUILayout.Separator();

	        if (GUILayout.Button("OK"))
	        {
	            if (cleanImport && EditorUtility.DisplayDialog("Assets Import", "Clean import will remove local files, continue?", "Yes", "No") == false)
	                return;

	            int _cnt = ImportEntries();
	            if (_cnt > 0)
	            {
	                EditorUtility.DisplayDialog("Assets Import", string.Format("{0} folders had been imported!", _cnt), "OK");
	                AssetDatabase.Refresh();
	            }
	            Close();
	        }
	    }

	    void FindEntries()
	    {
	        TextAsset _importListAsset = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Import.txt");
	        if (null == _importListAsset)
	        {
	            EditorUtility.DisplayDialog("Assets Import", "\"Assets/Import.txt\" does not exists!", "OK");
	            return;
	        }
	        string[] _importList = System.Text.Encoding.GetEncoding("UTF-8").GetString(_importListAsset.bytes).Split(new string[] {"\r\n", "\n"}, StringSplitOptions.RemoveEmptyEntries);
	        
	        List<string> _dirs = new List<string>();
	        foreach (string _line in _importList)
	        {
	            if (!string.IsNullOrEmpty(_line))
	            {
	                string _dir = _line.Replace('\\', '/');

	                try
	                {
	                    if (string.IsNullOrEmpty(System.IO.Path.GetPathRoot(_dir)))
	                    {
	                        //Debug.LogFormat("data:{0}, dir:{1}", Application.dataPath, _dir);
	                        _dir = System.IO.Path.Combine(Application.dataPath, _dir);
	                    }
	                    _dir = System.IO.Path.GetFullPath(_dir);

	                    if (System.IO.Directory.Exists(_dir))
	                        _dirs.Add(_dir);
	                    else
	                        Debug.LogErrorFormat("folder not found \"{0}\" -> \"{1}\"", _line, _dir);
	                }
	                catch(Exception)
	                {
	                    Debug.LogErrorFormat("invalid dir \"{0}\"", _dir);
	                }
	                
	            }
	        }

	        m_entries.Clear();

	        foreach(string _dir in _dirs)
	        {
	            //Debug.Log(_dir);
	            foreach(string _dir2 in System.IO.Directory.GetDirectories(_dir))
	            {
	                //Debug.Log(_dir2);
	                Entry _ent = new Entry();
	                _ent.dir = _dir2;
	                _ent.selected = false;
	                m_entries.Add(_ent);
	            }
	        }
	    }
	    int ImportEntries()
	    {
	        string _resDir = Application.dataPath + "/Artworks";
	        SafeMakeDirectory(_resDir);

	        foreach (Entry _ent in m_entries)
	        {
	            if (!_ent.selected)
	                continue;

	            string _dst = _resDir + "/" + _ent.name;

	            if (System.IO.Directory.Exists(_dst))
	            {
	                try
	                {
	                    if (cleanImport)
	                        FileUtil.DeleteFileOrDirectory(_dst);
	                }
	                catch (Exception _exc)
	                {
	                    Debug.LogError(_exc);
	                }
	            }
	        }

	        System.Threading.Thread.Sleep(500);

	        int _cnt = 0;
	        
	        foreach (Entry _ent in m_entries)
	        {
	            if (!_ent.selected)
	                continue;

	            string _dst = _resDir + "/" + _ent.name;

	            ExCopyDir(_ent.dir, _dst);
	            _cnt++;
	        }

	        return _cnt;
	    }

	    void SafeMakeDirectory(string _path)
	    {
	        try
	        {
	            if (!System.IO.Directory.Exists(_path))
	                System.IO.Directory.CreateDirectory(_path);
	        }
	        catch (Exception _exc)
	        {
	            Debug.LogError(_exc);
	        }
	    }

	    void ExCopyDir(string _src, string _dst)
	    {
	        //Debug.LogFormat("{0} -> {1}", _src, _dst);
	        SafeMakeDirectory(_dst);

	        foreach (string _file in System.IO.Directory.GetFiles(_src))
	        {
	            if (_file.Contains("~"))
	                continue;

	            string _ext = System.IO.Path.GetExtension(_file);

	            if (excludes.ContainsKey(_ext.ToLower()))
	                continue;

	            string _subdst = System.IO.Path.GetFullPath(_dst + _file.Replace(_src, ""));

	            if (!buildinTypes.ContainsKey(_ext.ToLower()))
	            {
	                _subdst = System.IO.Path.ChangeExtension(_subdst, _ext + ".bytes");
	            }

	            //Debug.LogFormat("{0} -> {1}, {2}", _file, _subdst, _ext);
	            System.IO.File.Copy(_file, _subdst, true);
	        }

	        foreach (string _subdir in System.IO.Directory.GetDirectories(_src))
	        {
	            if (_subdir.Contains("~"))
	                continue;

	            string _subdst = System.IO.Path.GetFullPath(_dst + _subdir.Replace(_src, ""));

	            ExCopyDir(_subdir, _subdst);
	        }
	    }
	}
}