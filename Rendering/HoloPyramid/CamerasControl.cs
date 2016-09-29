using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class CamerasControl : MonoBehaviour {

	[Range(1, 20)]
	public float distance = 5.0f;
	private Camera left;
	private Camera right;
	private Camera top;
	private Camera bottom;

	// Use this for initialization
	void Start () {
		left = transform.Find("LeftCamera").GetComponent<Camera>();
		right = transform.Find("RightCamera").GetComponent<Camera>();
		top = transform.Find("TopCamera").GetComponent<Camera>();
		bottom = transform.Find("BottomCamera").GetComponent<Camera>();

        Screen.fullScreen = true;
	}
	
	// Update is called once per frame
	void Update () {
		if (left)
			left.transform.localPosition = new Vector3(-distance, 0, 0);
		if (right)
			right.transform.localPosition = new Vector3( distance, 0, 0);
		if (top)
			top.transform.localPosition = new Vector3(0, 0, distance);
		if (bottom)
			bottom.transform.localPosition = new Vector3(0, 0,-distance);
	}
}
