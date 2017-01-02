using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace MGFX.Rendering
{

	public class PriorityQueue<T> : IEnumerable<T> where T : System.IComparable<T>
	{
		public List<T> queue { get; private set; }

		public PriorityQueue()
		{
			reset();
		}

		public void reset()
		{
			if (null == queue)
				queue = new List<T>();
			else
				queue.Clear();
		}

		public virtual void enqueue(T newNode)
		{
			int iNewNode = queue.Count;
			queue.Add(newNode);

			int iParent = parent(iNewNode);
			while (iNewNode != ROOT_INDEX && newNode.CompareTo(queue[iParent]) > 0)
			{
				T tmpNode = queue[iParent]; queue[iParent] = newNode; queue[iNewNode] = tmpNode;
				iNewNode = iParent; iParent = parent(iNewNode);
			}
		}

		public T dequeue()
		{
			int iParent = ROOT_INDEX;
			int n = queue.Count - 1;
			T result = queue[iParent];
			queue[iParent] = queue[n];
			queue.RemoveAt(n);

			int iChild = left(iParent);
			while (iChild < n)
			{
				int iRight = iChild + 1;
				if (iRight < n && queue[iRight].CompareTo(queue[iChild]) > 0)
					iChild = iRight;
				if (queue[iChild].CompareTo(queue[iParent]) > 0)
				{
					T tmpNode = queue[iChild]; queue[iChild] = queue[iParent]; queue[iParent] = tmpNode;
				}
				iParent = iChild; iChild = left(iParent);
			}
			return result;
		}

		public virtual void resize(int count)
		{
			while (queue.Count > count)
				dequeue();
		}
		public int count() { return queue.Count; }

		public T head() { return queue[0]; }

		public const int ROOT_INDEX = 0;
		public static int parent(int iChild)
		{
			return (iChild - 1) >> 1;
		}
		public static int left(int iParent)
		{
			return 2 * iParent + 1;
		}

		#region IEnumerable[T] implementation
		public IEnumerator<T> GetEnumerator()
		{
			while (queue.Count > 0)
				yield return dequeue();
		}
		System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
		{
			while (queue.Count > 0)
				yield return dequeue();
		}
		#endregion
	}

	public class FixedSizePriorityQueue<T> : IEnumerable<T> where T : System.IComparable<T>
	{
		private T[] _queue;
		private int _count;

		public FixedSizePriorityQueue(int size)
		{
			_queue = new T[size];
			_count = 0;
		}
		public void enqueue(T newNode)
		{
			var iInsert = 0;
			for (; iInsert < _count; iInsert++)
			{
				if (newNode.CompareTo(_queue[iInsert]) >= 0)
					break;
			}
			if (_count < _queue.Length)
			{
				var movementLength = _count - iInsert;
				if (movementLength > 0)
					System.Array.Copy(_queue, iInsert, _queue, iInsert + 1, movementLength);
				_count++;
			}
			else if (iInsert-- == 0)
			{
				return;
			}
			else
			{
				var movementLength = iInsert;
				if (movementLength > 0)
					System.Array.Copy(_queue, 1, _queue, 0, movementLength);
			}
			_queue[iInsert] = newNode;
		}
		public T head()
		{
			return _queue[0];
		}
		public void reset()
		{
			_count = 0;
		}
		public void resize(int size)
		{
			if (_queue.Length != size)
				_queue = new T[size];
		}

		#region IEnumerable[T] implementation
		public IEnumerator<T> GetEnumerator()
		{
			for (int i = 0; i < _count; i++)
				yield return _queue[i];
		}
		#endregion

		#region IEnumerable implementation
		System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
		{
			for (int i = 0; i < _count; i++)
				yield return _queue[i];
		}
		#endregion
	}

	public class KdTree
	{
		public Entry[] points { get; private set; }
		private Point _root;

		public void build(Entry[] points)
		{
			this.points = points;
			_root = build(0, points.Length, 0);
		}
		private Point build(int offset, int length, int depth)
		{
			if (length == 0)
				return null;
			int axis = depth % 3;
			System.Array.Sort(points, offset, length, COMPS[axis]);
			int mid = length >> 1;
			return new Point()
			{
				mid = offset + mid,
				smaller = build(offset, mid, depth + 1),
				larger = build(offset + mid + 1, length - (mid + 1), depth + 1)
			};
		}

		public class KQueue : FixedSizePriorityQueue<PriorityPoint>
		{
			public KQueue(int _size) : base(_size)
			{

			}
		}

		public int[] knearest(KQueue _priQueue, Vector3 point, int k)
		{
			_priQueue.reset();
			_priQueue.resize(k);
			_priQueue.enqueue(new PriorityPoint(-1, float.PositiveInfinity));
			knearest(_priQueue, point, _root, 0);
			return (from node in _priQueue.Reverse() where node.ipos >= 0 select points[node.ipos].id).ToArray();
		}
		private void knearest(KQueue _priQueue, Vector3 point, Point p, int depth)
		{
			if (p == null)
				return;
			var axis = depth % 3;
			var distOnAxis = points[p.mid].pos[axis] - point[axis];
			if (distOnAxis > 0)
			{
				knearest(_priQueue, point, p.smaller, depth + 1);
				var sqDist2leaf = sqDist(point, _priQueue.head().ipos);
				if (sqDist2leaf > distOnAxis * distOnAxis)
					knearest(_priQueue, point, p.larger, depth + 1);
			}
			else
			{
				knearest(_priQueue, point, p.larger, depth + 1);
				var sqDist2leaf = sqDist(point, _priQueue.head().ipos);
				if (sqDist2leaf > distOnAxis * distOnAxis)
					knearest(_priQueue, point, p.smaller, depth + 1);
			}
			_priQueue.enqueue(new PriorityPoint(p.mid, sqDist(point, p.mid)));
		}

		public class RQueue : PriorityQueue<PriorityPoint>
		{
		}
		
		public int[] rquery(RQueue _queue, Vector3 point, float range)
		{
			_queue.reset();
			_queue.enqueue(new PriorityPoint(-1, float.PositiveInfinity));
			rquery(_queue, point, _root, 0, range, range * range);
			return (from node in _queue.Reverse() where (node.ipos >= 0) select points[node.ipos].id).ToArray();
		}

		private void rquery(RQueue _queue, Vector3 point, Point p, int depth, float range, float sqrange)
		{
			if (p == null)
				return;
			
			var axis = depth % 3;
			var distOnAxis = point[axis] - points[p.mid].pos[axis];
			if (distOnAxis > 0)
			{
				if (distOnAxis <= range)
					rquery(_queue, point, p.smaller, depth + 1, range, sqrange);

				rquery(_queue, point, p.larger, depth + 1, range, sqrange);
			}
			else
			{
				if (distOnAxis >= -range)
					rquery(_queue, point, p.larger, depth + 1, range, sqrange);
				
				rquery(_queue, point, p.smaller, depth + 1, range, sqrange);
			}
			var sqdist = sqDist(point, p.mid);
			if (sqdist <= sqrange)
				_queue.enqueue(new PriorityPoint(p.mid, sqdist));
		}

		private float sqDist(Vector3 point, int index)
		{
			if (index == -1)
				return float.PositiveInfinity;
			var dist = point - points[index].pos;
			return dist.sqrMagnitude;
		}
		private int closer(Vector3 point, int i0, int i1)
		{
			if (i0 == -1)
				return i1;
			else if (i1 == -1)
				return i0;
			return sqDist(point, i0) < sqDist(point, i1) ? i0 : i1;
		}

		private class Point
		{
			public int mid;
			public Point smaller;
			public Point larger;
		}

		private static readonly IComparer<Entry>[] COMPS;
		static KdTree()
		{
			COMPS = new IComparer<Entry>[] { new AxisComparer(0), new AxisComparer(1), new AxisComparer(2) };
		}
		private class AxisComparer : IComparer<Entry>
		{
			private int _axis;
			public AxisComparer(int axis)
			{
				_axis = axis;
			}
			public int Compare(Entry p0, Entry p1)
			{
				return p0.pos[_axis] > p1.pos[_axis] ? +1 : (p0.pos[_axis] < p1.pos[_axis] ? -1 : 0);
			}
		}
		public class PriorityPoint : System.IComparable<PriorityPoint>
		{
			public readonly int ipos;
			public readonly float dist;

			public PriorityPoint(int ipos, float dist)
			{
				this.ipos = ipos;
				this.dist = dist;
			}

			public int CompareTo(PriorityPoint other)
			{
				return dist > other.dist ? +1 : (dist < other.dist ? -1 : 0);
			}

			public override string ToString()
			{
				return string.Format("(i={0},d={1})", ipos, dist);
			}
		}

		public class Entry
		{
			public Vector3 pos;
			public int id;

			public Entry(Vector3 pos, int id)
			{
				this.pos = pos;
				this.id = id;
			}
		}
	}
}