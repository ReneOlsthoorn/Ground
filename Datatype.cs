using GroundCompiler.Statements;

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

        public bool hasArrayDefinition => (ArrayNrs != null) && (ArrayNrs.Count > 0);

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

        public Datatype DeepCopy()
        {
            Datatype result = new Datatype();
            result.Types.AddRange(this.Types);
            result.Name = this.Name;
            result.SizeInBytes = this.SizeInBytes;
            result.Base = this.Base;
            result.ArrayNrs = (this.ArrayNrs == null) ? null : new List<UInt64>(this.ArrayNrs);
            result.IsValueType = this.IsValueType;
            return result;
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
           C++ long = 32 bits(!).
           C++ long long = 64 bits.
           C++ float = 32 bits = 4 bytes.
           C++ double = 64 bits.
         */

        public static Dictionary<string, Datatype> Cached = new() {
            { "int",    Datatype.FromData("int",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:8) },
            { "ptr",    Datatype.FromData("ptr",    [ TypeEnum.Pointer, TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:8) },
            { "pointer",Datatype.FromData("pointer",[ TypeEnum.Pointer, TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:8) },
            { "i64",    Datatype.FromData("i64",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:8) },
            { "i32",    Datatype.FromData("i32",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:4) },
            { "i16",    Datatype.FromData("i16",    [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:2) },
            { "i8",     Datatype.FromData("i8",     [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Signed ],   isValueType:true, nrBytes:1) },
            { "byte1024", Datatype.FromData("byte1024",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:1024) },
            { "byte512", Datatype.FromData("byte512",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:512) },
            { "byte256", Datatype.FromData("byte256",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:256) },
            { "byte128", Datatype.FromData("byte128",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:128) },
            { "byte64", Datatype.FromData("byte64",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:64) },
            { "byte32", Datatype.FromData("byte32",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:32) },
            { "byte16", Datatype.FromData("byte16",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:16) },
            { "byte8", Datatype.FromData("byte8",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:8) },
            { "byte4", Datatype.FromData("byte4",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:4) },
            { "byte2", Datatype.FromData("byte2",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:2) },
            { "byte1", Datatype.FromData("byte1",  [ TypeEnum.Number, TypeEnum.Integer, TypeEnum.Unsigned ], isValueType:true, nrBytes:1) },
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
            if (type1.Contains(TypeEnum.Integer) && type2.Contains(TypeEnum.Integer))
                return true;
            if (type1.Contains(TypeEnum.FloatingPoint) && type2.Contains(TypeEnum.FloatingPoint) && (type1.SizeInBytes == type2.SizeInBytes))
                return true;
            if (type1.Name == "string" && type2.Name == "string")
                return true;
            return false;
        }

        public static void AddClass(ClassStatement classStatement)
        {
            string name = classStatement.Name.Lexeme;
            int sizeInBytes = classStatement.SizeInBytes();
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
                Step6_Compiler.Error($"Datatype>>GetDatatype: Type {theType} does not exist.");

            return Cached[theType];
        }

        public static bool ContainsDatatype(string theType) => Cached.ContainsKey(theType);
        public static bool IsPointerType(Datatype datatype) => datatype.Contains(Datatype.TypeEnum.Pointer);

    }
}
