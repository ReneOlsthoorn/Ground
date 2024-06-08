using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using static GroundCompiler.AstNodes.Statement;

namespace GroundCompiler
{
    public class Datatype
    {
        public enum TypeEnum
        {
            Allocated,
            Array,
            Pointer,
            Number,
            Integer,
            Signed,
            Unsigned,
            FloatingPoint,
            Boolean,
            String,
            CustomClass
        }

        public Datatype() {
            Types = new List<TypeEnum>();
            Name = "";
            Properties = new Dictionary<string, object?>();
        }
        public bool Contains(TypeEnum tokenType)
        {
            return Types.Contains(tokenType);
        }

        public bool IsValueType = false;
        public bool IsReferenceType
        {
            get { return !IsValueType;  }
        }

        public bool isClass() => Contains(TypeEnum.CustomClass);

        public List<TypeEnum> Types;
        public string Name;
        public int SizeInBytes;
        public Datatype? Base;
        public List<UInt64>? ArrayNrs = null;
        public Dictionary<string, object?> Properties;

        public UInt64 BytesToAllocate()
        {
            UInt64 baseSizeInBytes = (UInt64)this.Base!.SizeInBytes;
            if (this.ArrayNrs != null)
            {
                if (this.ArrayNrs.Count == 0)
                    return 10 * baseSizeInBytes;

                foreach (UInt64 value in this.ArrayNrs)
                    baseSizeInBytes *= (UInt64)value;
            }
            return baseSizeInBytes;
        }

        public static Datatype FromData(string name, List<TypeEnum> tokenTypes, bool isValueType = false, int nrBytes = 0)
        {
            Datatype result = new Datatype();
            result.Types = new List<TypeEnum>(tokenTypes);
            result.Name = name;
            result.SizeInBytes = nrBytes;
            result.IsValueType = isValueType;
            return result;
        }

        //string = cp-1252 ? Dat is de codepage die ik vroeger altijd gebruikte en waar alle characters van europa in passen.

        /* Unrelated C++ notice:
           C++ int = 32 bits. So, int is not 64 bits in C++ x64!
           C++ long = 32 bits.
           C++ long long = 64 bits.
           C++ float = 32 bits.
           C++ double = 64 bits.
         */

        public static Dictionary<string, Datatype> Cached = new() {
            { "int",    Datatype.FromData("int",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:8) },
            { "ptr",    Datatype.FromData("ptr",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:8) },
            { "i64",    Datatype.FromData("i64",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:8) },
            { "i32",    Datatype.FromData("i32",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:4) },
            { "i16",    Datatype.FromData("i16",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:2) },
            { "i8",     Datatype.FromData("i8",     [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:1) },
            { "u64",    Datatype.FromData("u64",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:8) },
            { "u32",    Datatype.FromData("u32",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:4) },
            { "u16",    Datatype.FromData("u16",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:2) },
            { "u8",     Datatype.FromData("u8",     [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:1) },
            { "byte",   Datatype.FromData("byte",   [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:1) },
            { "f32",    Datatype.FromData("f32",    [ TypeEnum.Number, TypeEnum.FloatingPoint ], isValueType:true, nrBytes:4) },
            { "float",  Datatype.FromData("float",  [ TypeEnum.Number, TypeEnum.FloatingPoint ], isValueType:true, nrBytes:8) },
            { "double",  Datatype.FromData("double",  [ TypeEnum.Number, TypeEnum.FloatingPoint ], isValueType:true, nrBytes:8) },
            { "f64",    Datatype.FromData("f64",    [ TypeEnum.Number, TypeEnum.FloatingPoint ], isValueType:true, nrBytes:8) },
            { "bool",   Datatype.FromData("bool",   [ TypeEnum.Boolean ], isValueType:true, nrBytes:8) },
            { "string", Datatype.FromData("string", [ TypeEnum.String, TypeEnum.Array, TypeEnum.Allocated ], isValueType:false, nrBytes:8) }
        };

        public static bool IsCompatible(Datatype type1, Datatype type2)
        {
            return ((type1.SizeInBytes == type2.SizeInBytes) && (type1.IsValueType && type2.IsValueType) && (type1.Contains(TypeEnum.Integer) && type2.Contains(TypeEnum.Integer)));
        }

        public static void AddClass(ClassStatement classStatement)
        {
            string name = classStatement.Name.Lexeme;

            int sizeInBytes = 0;
            foreach (VarStatement vs in classStatement.InstanceVariables)
                sizeInBytes += vs.ResultType.SizeInBytes;

            var newDatatype = Datatype.FromData(name, [ TypeEnum.CustomClass ], false, sizeInBytes);
            newDatatype.Properties["classStatement"] = classStatement;
            Cached.Add(name, newDatatype);
        }

        public static bool DatatypeContains(string type, TypeEnum tokenType)
        {
            var theType = Cached[type];
            return theType.Contains(tokenType);
        }

        public static Datatype Default
        {
            get { return GetDatatype("i64"); }
        }

        public static bool _needFillInteralBaseType = true;
        public static void FillInternalBasetype()
        {
            if (!_needFillInteralBaseType)
                return;
            _needFillInteralBaseType = false;
            var stringType = Cached["string"];
            stringType.Base = GetDatatype("byte");
        }

        public static Datatype GetDatatype(string theType, List<UInt64>? arraySizeList = null)
        {
            FillInternalBasetype();

            if (theType.EndsWith("[]"))
            {
                Datatype arrayDatatype = Datatype.FromData(theType, new List<TypeEnum> { TypeEnum.Array, TypeEnum.Allocated }, isValueType: false, nrBytes: 8);
                var baseTypeStr = theType.Substring(0, theType.IndexOf('['));
                Datatype baseType = GetDatatype(baseTypeStr);
                arrayDatatype.Base = baseType;
                arrayDatatype.ArrayNrs = arraySizeList;
                return arrayDatatype;
            }
            if (theType.EndsWith("*"))
            {
                Datatype pointerDatatype = Datatype.FromData(theType, new List<TypeEnum> { TypeEnum.Pointer }, isValueType: true, nrBytes: 8);
                var baseTypeStr = theType.Substring(0, theType.IndexOf('*'));
                Datatype baseType = GetDatatype(baseTypeStr);
                pointerDatatype.Base = baseType;
                return pointerDatatype;
            }

            if (!Cached.ContainsKey(theType))
                Compiler.Error($"Datatype>>GetDatatype: Type {theType} does not exist.");

            return Cached[theType];
        }

        public static bool ContainsDatatype(string theType)
        {
            return Cached.ContainsKey(theType);
        }

    }
}
