using System;
using System.Security.Cryptography;

namespace Mud
{
    // http://codereview.stackexchange.com/questions/39515/implementation-of-the-fnv-1a-hash-algorithm-for-32-and-64-bit
    public sealed class Fnv1a32 : HashAlgorithm
    {
        private const uint FnvPrime = unchecked(16777619);

        private const uint FnvOffsetBasis = unchecked(2166136261);

        private uint hash;

        public Fnv1a32()
        {
            this.Reset();
        }

        public override void Initialize()
        {
            this.Reset();
        }

        protected override void HashCore(byte[] array, int ibStart, int cbSize)
        {
            for (var i = ibStart; i < cbSize; i++)
            {
                unchecked
                {
                    this.hash ^= array[i];
                    this.hash *= FnvPrime;
                }
            }
        }

        protected override byte[] HashFinal()
        {
            return BitConverter.GetBytes(this.hash);
        }

        private void Reset()
        {
            this.hash = FnvOffsetBasis;
        }

        private static Fnv1a32 ms_hashing = new Fnv1a32();
        private static System.Text.Encoding ms_encoding = System.Text.Encoding.UTF8;
        
        public static uint Compute(string _data)
        {
            return System.BitConverter.ToUInt32(ms_hashing.ComputeHash(ms_encoding.GetBytes(_data)), 0);
        }
    }
    
    public sealed class HashID
    {
        public static HashID Empty = new HashID();
        
        public HashID(string _name)
        {
            m_name = _name;
            var _hash = ms_hashing.ComputeHash(ms_encoding.GetBytes(_name));
            m_hash = BitConverter.ToInt32(_hash, 0);
        }
        
        public override string ToString()
        {
            return m_name;
        }
        
        public override bool Equals(object _other)
        {
            return this == (_other as HashID);
        }
        
        public override int GetHashCode()
        {
            return m_hash;
        }
        
        public static bool operator == (HashID _x, HashID _y)
        {
            return (_x ?? Empty).m_hash == (_y ?? Empty).m_hash;
        }
        
        public static bool operator != (HashID _x, HashID _y)
        {
            return (_x ?? Empty).m_hash != (_y ?? Empty).m_hash;
        }
        
        private string m_name;
        private int m_hash;
        private static Fnv1a32 ms_hashing = new Fnv1a32();
        private static System.Text.Encoding ms_encoding = System.Text.Encoding.UTF8;

        private HashID()
        {
            m_name = "";
            m_hash = 0;
        }
    }

    public sealed class HashDict<T> : System.Collections.Generic.Dictionary<HashID, T>
    {
        public bool ContainsKey(string _str)
        {
            return base.ContainsKey(new HashID(_str));
        }
    }

}