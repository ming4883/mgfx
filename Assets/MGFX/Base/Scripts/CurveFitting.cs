using System;
using System.Diagnostics;
using UnityEngine;

namespace MGFX
{
    public static class CurveFitting
    {
        public static Vector3 CatmullRom(Vector3 previous, Vector3 start, Vector3 end, Vector3 next, 
                                  float elapsedTime, float duration)
        {
            // References used:
            // p.266 GemsV1
            //
            // tension is often set to 0.5 but you can use any reasonable value:
            // http://www.cs.cmu.edu/~462/projects/assn2/assn2/catmullRom.pdf
            //
            // bias and tension controls:
            // http://local.wasp.uwa.edu.au/~pbourke/miscellaneous/interpolation/
 
            float percentComplete = elapsedTime / duration;
            float percentCompleteSquared = percentComplete * percentComplete;
            float percentCompleteCubed = percentCompleteSquared * percentComplete;
 
            return previous * (-0.5f * percentCompleteCubed + percentCompleteSquared - 0.5f * percentComplete) 
                + start * (1.5f * percentCompleteCubed + -2.5f * percentCompleteSquared + 1.0f) 
                + end * (-1.5f * percentCompleteCubed + 2.0f * percentCompleteSquared + 0.5f * percentComplete)
                + next * (0.5f * percentCompleteCubed - 0.5f * percentCompleteSquared);
        }
        
    }
}