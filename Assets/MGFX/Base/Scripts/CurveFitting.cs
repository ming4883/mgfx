using System;
using System.Diagnostics;
using System.Collections.Generic;
using UnityEngine;

namespace MGFX
{
	public static class CurveFitting
	{
        // https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
        public class CentripetalCatmullRom
		{
            public static void FindTs(out float _t0, out float _t1, out float _t2, out float _t3,
                float _alpha, Vector3 _P0, Vector3 _P1, Vector3 _P2, Vector3 _P3)
            {
                float _halfAlpha = _alpha * 0.5f;
                _t0 = 0;
                _t1 = Mathf.Pow((_P1 - _P0).sqrMagnitude, _halfAlpha) + _t0;
                _t2 = Mathf.Pow((_P2 - _P1).sqrMagnitude, _halfAlpha) + _t1;
                _t3 = Mathf.Pow((_P3 - _P2).sqrMagnitude, _halfAlpha) + _t2;
            }

            public static Vector3 Intrpl(float _w, float _w1, float _w2, Vector3 _C1, Vector3 _C2)
            {
                return ((_w2 - _w) * _C1 + (_w - _w1) * _C2) / (_w2 - _w1);
            }

            public static Vector3 Intrpl(float _t,
                float _t0, float _t1, float _t2, float _t3, 
                Vector3 _P0, Vector3 _P1, Vector3 _P2, Vector3 _P3)
            {
                Vector3 _A3 = Intrpl(_t, _t2, _t3, _P2, _P3);
                Vector3 _A2 = Intrpl(_t, _t1, _t2, _P1, _P2);
                Vector3 _A1 = Intrpl(_t, _t0, _t1, _P0, _P1);

                Vector3 _B2 = Intrpl(_t, _t1, _t3, _A2, _A3);
                Vector3 _B1 = Intrpl(_t, _t0, _t2, _A1, _A2);

                return Intrpl(_t, _t1, _t2, _B1, _B2);
            }

            public static void Tessellate(List<Vector3> _ret, int _numOfSegments, float _alpha, Vector3 _P0, Vector3 _P1, Vector3 _P2, Vector3 _P3)
            {
                float _t0, _t1, _t2, _t3;
                FindTs(out _t0, out _t1, out _t2, out _t3, _alpha, _P0, _P1, _P2, _P3);
                float _dt = (_t2 - _t1) / _numOfSegments;
                float _t = _t1 + _dt;

                // do not include _P0 and _P3 
                for (int _i = 1; _i < _numOfSegments; ++_i)
                {
                    _ret.Add(Intrpl(_t, _t0, _t1, _t2, _t3, _P0, _P1, _P2, _P3));
                    _t += _dt;
                }
            }

            public static void Tessellate(List<Vector3> _ret, int _numOfSegments, float _alpha, List<Vector3> _path)
            {
                if (_path.Count < 3)
                {
                    // point or line
                    _ret.AddRange(_path);
                    return;
                }
                int _ls = _path.Count - 1;
                int _ls1 = _ls - 1;
                int _ls2 = _ls - 2;

                Vector3 _beg = _path[0] + (_path[0] - _path[1]);
                Vector3 _end = _path[_ls] + (_path[_ls1] - _path[_ls]);

                _ret.Add(_path[0]);
                Tessellate(_ret, _numOfSegments, _alpha, _beg, _path[0], _path[1], _path[2]);

                for (int _i = 1; _i < _ls1; ++_i)
                {
                    _ret.Add(_path[_i]);
                    Tessellate(_ret, _numOfSegments, _alpha, _path[_i - 1], _path[_i], _path[_i + 1], _path[_i + 2]);
                }

                _ret.Add(_path[_ls1]);
                Tessellate(_ret, _numOfSegments, _alpha, _path[_ls2], _path[_ls1], _path[_ls], _end);

                _ret.Add(_path[_ls]);
            }
		}
	}
}