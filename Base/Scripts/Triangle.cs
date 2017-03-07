using UnityEngine;

namespace MGFX
{
    public static class Triangle
    {
        public static Vector3 ProjectToPlane(Vector3 _pt, Plane _plane)
        {
            float _dist = _plane.GetDistanceToPoint(_pt);
            return _pt - (_plane.normal * _dist);
        }

        public static bool GetBarycentricCoords(out Vector3 _ret, Vector3 _a, Vector3 _b, Vector3 _c, Vector3 _p)
        {
            Vector3 v0 = _b - _a;
            Vector3 v1 = _c - _a;
            Vector3 v2 = _p - _a;

            float _d00 = Vector3.Dot(v0, v0);
            float _d01 = Vector3.Dot(v0, v1);
            float _d11 = Vector3.Dot(v1, v1);
            float _d20 = Vector3.Dot(v2, v0);
            float _d21 = Vector3.Dot(v2, v1);
            float _denom = _d00 * _d11 - _d01 * _d01;

            if (_denom * _denom < Mathf.Epsilon)
            {
                _ret = Vector3.zero;
                return false;
            }

            float _v = (_d11 * _d20 - _d01 * _d21) / _denom;
            float _w = (_d00 * _d21 - _d01 * _d20) / _denom;
            float _u = 1.0f - _v - _w;

            //Log.I(string.Format("{0}, {1}, {2} , {3}", _a, _b, _c, _p));
            //Log.I(string.Format("{0}, {1}, {2} , {3}", _denom, _u, _v, _w));

            bool _uIsInValid = _u < 0 || _u > 1;
            bool _vIsInValid = _v < 0 || _v > 1;
            bool _wIsInValid = _w < 0 || _w > 1;
            if (_uIsInValid || _vIsInValid || _wIsInValid)
            {
                _ret = Vector3.zero;
                return false;
            }

            _ret.x = _u;
            _ret.y = _v;
            _ret.z = _w;

            return true;
        }
    }
}