using GroundCompiler.Statements;

namespace GroundCompiler.Symbols
{
    public class Symbol
    {
        public string Name = "";
        public string Symboltype = "";
        public Dictionary<string, object?> Properties = new Dictionary<string, object?>();

        public virtual ClassStatement? GetClassStatement() => null;
        public virtual GroupStatement? GetGroupStatement() => null;

        public virtual Datatype? GetDatatype() => null;
    }

    public class VariableSymbol : Symbol
    {
        public Datatype DataType;

        public VariableSymbol(string name, Datatype datatype)
        {
            Name = name;
            DataType = datatype;
            Symboltype = "var";
        }

        public override Datatype? GetDatatype() => DataType;
    }

    public class LocalVariableSymbol : VariableSymbol
    {
        public LocalVariableSymbol(string name, Datatype datatype) : base(name, datatype)
        {
        }

        public override ClassStatement? GetClassStatement()
        {
            if (DataType.Contains(Datatype.TypeEnum.CustomClass))
            {
                var theClassStatement = DataType.Properties["classStatement"];
                if (theClassStatement != null)
                    return (ClassStatement)theClassStatement;
            }
            return null;
        }
    }

    public class HardcodedVariable : VariableSymbol
    {
        public HardcodedVariable(string name, Datatype datatype) : base(name, datatype)
        {
        }
    }

    public class ParentScopeVariable : VariableSymbol
    {
        public int LevelsDeep;
        public IScopeStatement TheScopeStatement;
        public LocalVariableSymbol TheLocalVariable;

        public ParentScopeVariable(string name, Datatype datatype, int levelsDeep, IScopeStatement theScopeStatement, LocalVariableSymbol localVar) : base(name, datatype)
        {
            Symboltype = "parent scope var";
            LevelsDeep = levelsDeep;
            TheScopeStatement = theScopeStatement;
            TheLocalVariable = localVar;
        }

        public override ClassStatement? GetClassStatement()
        {
            if (DataType.Contains(Datatype.TypeEnum.CustomClass))
            {
                var theClassStatement = DataType.Properties["classStatement"];
                if (theClassStatement != null)
                    return (ClassStatement)theClassStatement;
            }
            return null;
        }
    }

    public class StringConstantSymbol : Symbol
    {
        public string Value;
        public string? SymbolRefId;
        public int IndexspaceRownr = -1;

        public StringConstantSymbol(string @value, string symbolRefId)
        {
            Value = @value;
            SymbolRefId = symbolRefId;
            IndexspaceRownr = -1;
            Symboltype = "const str";
        }
    }

    public class FloatConstantSymbol : Symbol
    {
        public double Value;
        public string? SymbolRefId;

        public FloatConstantSymbol(double @value, string symbolRefId)
        {
            Value = @value;
            SymbolRefId = symbolRefId;
            Symboltype = "const float";
        }
    }

    public class ClassSymbol : Symbol
    {
        public ClassStatement ClassStatement;
        public ClassSymbol(string name, ClassStatement classStatement)
        {
            Name = name;
            ClassStatement = classStatement;
            Symboltype = "class";
        }
    }

    public class GroupSymbol : Symbol
    {
        public GroupStatement? GroupStatement;
        public GroupSymbol(string name, GroupStatement? groupStatement = null)
        {
            Name = name;
            GroupStatement = groupStatement;
            Symboltype = "group";
        }

        public override GroupStatement? GetGroupStatement()
        {
            return GroupStatement;
        }

    }

    public class FunctionSymbol : Symbol
    {
        public FunctionStatement FunctionStmt;

        public FunctionSymbol(string name, FunctionStatement functionStatement)
        {
            Name = name;
            FunctionStmt = functionStatement;
            Symboltype = "function";
        }
    }

    public class DllFunctionSymbol : FunctionSymbol
    {
        public DllFunctionSymbol(string name, FunctionStatement functionStatement, Datatype? resultDatatype = null) : base(name, functionStatement)
        {
            if (resultDatatype != null)
                this.FunctionStmt.ResultDatatype = resultDatatype;
        }
    }

    public class HardcodedFunctionSymbol : FunctionSymbol
    {
        public HardcodedFunctionSymbol(string name, Datatype? resultDatatype = null) : base(name, new FunctionStatement())
        {
            this.FunctionStmt.Name.Lexeme = name;
            this.FunctionStmt.Properties["hardcoded"] = true;
            if (resultDatatype != null)
                this.FunctionStmt.ResultDatatype = resultDatatype;
        }
    }

    public class FunctionParameterSymbol : VariableSymbol
    {
        public FunctionParameter FunctionParameter;
        public FunctionStatement TheFunction;

        public FunctionParameterSymbol(string name, FunctionParameter par, FunctionStatement theFunction) : base(name, par.TheType)
        {
            Name = name;
            FunctionParameter = par;
            TheFunction = theFunction;
            Symboltype = "function par";
        }

        public override ClassStatement? GetClassStatement()
        {
            if (DataType.Contains(Datatype.TypeEnum.CustomClass))
            {
                var theClassStatement = DataType.Properties["classStatement"];
                if (theClassStatement != null)
                    return (ClassStatement)theClassStatement;
            }
            return null;
        }
    }
}
