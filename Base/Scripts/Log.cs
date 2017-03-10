using System.Diagnostics;

namespace MGFX
{
    public static class Log
    {
        public static bool DETAILS = false;
        private static string GetPrefix(string _suffix)
        {
            var _trace = new StackTrace(DETAILS);
            string _clsName = null;
            if (_trace.FrameCount > 2)
            {
                var _frm = _trace.GetFrame(2);
                
                if (DETAILS)
                {
                    _clsName = string.Format("{0}:{1}", 
                        _frm.GetMethod().ReflectedType.Name,
                        _frm.GetFileLineNumber()
                        );
                }
                else
                {
                    _clsName = _frm.GetMethod().ReflectedType.Name;
                }
                
                if (null != _suffix)
                    _clsName += _suffix;
            }
            
            return _clsName ?? "";
        }

        public static string ToString(object _obj)
        {
            return (_obj == null) ? "(null)" : _obj.ToString();
        }
        
        public static void I(object _obj)
        {
            UnityEngine.Debug.logger.Log(GetPrefix(null), ToString(_obj));
        }
        
        public static void I(string _fmt, object _arg0)
        {
			UnityEngine.Debug.logger.Log(GetPrefix(null), string.Format(_fmt, new object[]{_arg0}));
        }
        
        public static void I(string _fmt, object _arg0, object _arg1)
        {
			UnityEngine.Debug.logger.Log(GetPrefix(null), string.Format(_fmt, new object[]{_arg0, _arg1}));
        }
        
        public static void I(string _fmt, object _arg0, object _arg1, object _arg2)
        {
			UnityEngine.Debug.logger.Log(GetPrefix(null), string.Format(_fmt, new object[]{_arg0, _arg1, _arg2}));
        }
        
        public static void E(object _obj)
        {
            UnityEngine.Debug.logger.LogError(GetPrefix(null), ToString(_obj));
        }
        
        public static void E(string _fmt, object _arg0)
        {
			UnityEngine.Debug.logger.LogError(GetPrefix(null), string.Format(_fmt, new object[]{_arg0}));
        }
        
        public static void E(string _fmt, object _arg0, object _arg1)
        {
			UnityEngine.Debug.logger.LogError(GetPrefix(null), string.Format(_fmt, new object[]{_arg0, _arg1}));
        }
        
        public static void E(string _fmt, object _arg0, object _arg1, object _arg2)
        {
			UnityEngine.Debug.logger.LogError(GetPrefix(null), string.Format(_fmt, new object[]{_arg0, _arg1, _arg2}));
        }
        
    }
}