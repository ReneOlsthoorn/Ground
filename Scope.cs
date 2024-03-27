using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Linq;
using System.Text;
using GroundCompiler.AstNodes;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Scope.Symbol;

namespace GroundCompiler
{
    public interface IScopeStatement
    {
        Scope GetScopeFromStatement();
        Token GetScopeName();
    }

    public class Scope
    {
        public Scope? Parent;
        public Dictionary<string, Symbol> Symboltable = new();
        public IScopeStatement Owner;

        public Scope(IScopeStatement owner)
        {
            Parent = null;
            Owner = owner;
        }

        public bool ExistsAnywhere(string name, string datatype)
        {
            string id = IdFor(name, datatype);
            if (Symboltable.ContainsKey(id))
                return true;

            if (Parent != null)
                return Parent.ExistsAnywhere(name, datatype);

            return false;
        }

        public bool Contains(string id)
        {
            return Symboltable.ContainsKey(id);
        }

        public bool ContainsAnywhere(string id)
        {
            if (Symboltable.ContainsKey(id))
                return true;

            if (Parent != null)
                return Parent.ContainsAnywhere(id);

            return false;
        }


        public Symbol? GetVariable(string name, string datatype)
        {
            string id = IdFor(name, datatype);
            return GetVariable(id);
        }

        public Symbol? GetVariable(string id)
        {
            if (!Contains(id))
                return null;

            return Symboltable[id];
        }

        public Symbol? GetVariableAnywhere(string id)
        {
            if (Contains(id))
                return Symboltable[id];

            if (Parent != null)
                return Parent.GetVariableAnywhere(id);

            return null;
        }

        public Datatype GetVariableDataType(string id)
        {
            var theSymbol = GetVariableAnywhere(id);
            if (theSymbol != null)
            {
                if (theSymbol is Scope.Symbol.LocalVariableSymbol)
                    return (theSymbol as Scope.Symbol.LocalVariableSymbol)!.DataType;
                if (theSymbol is Scope.Symbol.LocalVariableSymbol)
                    return (theSymbol as Scope.Symbol.FunctionParameterSymbol)!.DataType;
            }
            return Datatype.GetDatatype("i64");
        }


        public Symbol.StringConstantSymbol? GetString(string str)
        {
            string id = IdFor(str, "const str");
            return GetStringById(id);
        }

        public Symbol.FunctionSymbol? GetFunction(string name)
        {
            string id = IdFor(name, "function");
            return Symboltable[id] as Symbol.FunctionSymbol;
        }

        public Symbol.StringConstantSymbol? GetStringById(string id)
        {
            return Symboltable[id] as Symbol.StringConstantSymbol;
        }

        public Symbol.FloatConstantSymbol? GetFloatById(string id)
        {
            return Symboltable[id] as Symbol.FloatConstantSymbol;
        }

        public List<Symbol.LocalVariableSymbol> GetVariableSymbols()
        {
            List<Symbol.LocalVariableSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as Symbol.LocalVariableSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<Symbol.LocalVariableSymbol> GetInstanceVariableSymbols()
        {
            List<Symbol.LocalVariableSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as Symbol.LocalVariableSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<Symbol.FloatConstantSymbol> GetLiteralFloatSymbols()
        {
            List<Symbol.FloatConstantSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as Symbol.FloatConstantSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<Symbol.StringConstantSymbol> GetStringSymbols()
        {
            List<Symbol.StringConstantSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as Symbol.StringConstantSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<Symbol.FunctionSymbol> GetFunctionSymbols()
        {
            List<Symbol.FunctionSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                if (symbol is Symbol.HardcodedFunctionSymbol)
                    continue;
                if (symbol is Symbol.FunctionSymbol)
                    result.Add((symbol as Symbol.FunctionSymbol)!);
            }
            return result;
        }

        public List<Symbol.ClassSymbol> GetClassSymbols()
        {
            List<Symbol.ClassSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                if (symbol is Symbol.HardcodedFunctionSymbol)
                    continue;
                if (symbol is Symbol.ClassSymbol)
                    result.Add((symbol as Symbol.ClassSymbol)!);
            }
            return result;
        }

        public string IdFor(string name, string datatype)
        {
            if (datatype == "const str")
                return "str_" + name;

            if (datatype == "const float")
                return "float_" + name.Replace(".","_");

            return name;
        }

        public Symbol.LocalVariableSymbol DefineVariable(string name, Datatype datatype)
        {
            string id = IdFor(name, datatype.Name);
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Symbol.LocalVariableSymbol(name, datatype);
            Symboltable[id] = newElement;
            return newElement;
        }

        public Symbol.HardcodedVariable DefineHardcodedVariable(string name, Datatype datatype)
        {
            string id = IdFor(name, datatype.Name);
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Symbol.HardcodedVariable(name, datatype);
            Symboltable[id] = newElement;
            return newElement;
        }

        public Symbol.FunctionSymbol DefineFunction(Statement.FunctionStatement functionStatement)
        {
            string name = functionStatement.Name.Lexeme;
            string id = IdFor(name, "function");
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Scope.Symbol.FunctionSymbol(name, functionStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public Symbol.ClassSymbol DefineClass(Statement.ClassStatement classStatement)
        {
            string name = classStatement.Name.Lexeme;
            string id = IdFor(name, "class");
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Scope.Symbol.ClassSymbol(name, classStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public Symbol.GroupSymbol DefineGroup(Statement.GroupStatement groupStatement)
        {
            string name = groupStatement.Name.Lexeme;
            string id = IdFor(name, "group");
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Scope.Symbol.GroupSymbol(name, groupStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public HardcodedFunctionSymbol DefineHardcodedFunction(string name, Datatype? resultDatatype = null)
        {
            string id = IdFor(name, "function");
            if (Symboltable.ContainsKey(id))
                Compiler.Error($"{name} already defined.");

            var newElement = new Scope.Symbol.HardcodedFunctionSymbol(name, resultDatatype);
            Symboltable[name] = newElement;
            return newElement;
        }

        public void DefineFunctionParameters(Statement.FunctionStatement functionStatement)
        {
            string classPrefix = (functionStatement.classStatement != null) ? functionStatement.classStatement.Name.Lexeme : "";
            foreach (var par in functionStatement.Parameters) {
                string id = IdFor($"{classPrefix}_{par.Name}", "function par");
                if (Symboltable.ContainsKey(id))
                    Compiler.Error($"{par.Name} already defined.");

                var newElement = new Scope.Symbol.FunctionParameterSymbol(par.Name, par, functionStatement);
                Symboltable[par.Name] = newElement;
            }
        }

        public Symbol DefineParentScopeParameter(string name, Datatype datatype, int levelsDeep, IScopeStatement scopeStatement)
        {
            var newElement = new Scope.Symbol.ParentScopeVariable(name, datatype, levelsDeep, scopeStatement);
            Symboltable[name] = newElement;
            return newElement;
        }


        public static int StringCounter = 0;
        public Symbol.StringConstantSymbol? DefineString(string str)
        {
            Scope rootScope = GetRootScope();

            string id = IdFor(str, "const str");
            if (rootScope.Contains(id))
                return rootScope.GetStringById(id);

            var newElement = new Symbol.StringConstantSymbol(str, $"str{StringCounter++}");
            rootScope.Symboltable[id] = newElement;
            return newElement;
        }


        public Symbol.FloatConstantSymbol? DefineFloatingpoint(double d)
        {
            Scope rootScope = GetRootScope();

            string id = IdFor(d.ToString(CultureInfo.InvariantCulture), "const float");
            if (rootScope.Contains(id))
                return rootScope.GetFloatById(id);
            
            var newElement = new Symbol.FloatConstantSymbol(d, id);
            rootScope.Symboltable[id] = newElement;
            return newElement;
        }


        public Scope GetRootScope()
        {
            Scope rootScope = this;
            while (rootScope.Parent != null)
                rootScope = rootScope.Parent;

            return rootScope;
        }


        public class Symbol
        {
            public string Name = "";
            public string Symboltype = "";
            public Dictionary<string, object?> Properties = new Dictionary<string, object?>();

            public virtual ClassStatement? GetClassStatement() => null;
            public virtual GroupStatement? GetGroupStatement() => null;

            public virtual Datatype? GetDatatype() => null;

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

                public ParentScopeVariable(string name, Datatype datatype, int levelsDeep, IScopeStatement theScopeStatement) : base(name, datatype)
                {
                    Symboltype = "parent scope var";
                    LevelsDeep = levelsDeep;
                    TheScopeStatement = theScopeStatement;
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
                public Statement.ClassStatement ClassStatement;
                public ClassSymbol(string name, Statement.ClassStatement classStatement)
                {
                    Name = name;
                    ClassStatement = classStatement;
                    Symboltype = "class";
                }
            }

            public class GroupSymbol : Symbol
            {
                public Statement.GroupStatement GroupStatement;
                public GroupSymbol(string name, Statement.GroupStatement groupStatement)
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
                public Statement.FunctionStatement FunctionStatement;

                public FunctionSymbol(string name, Statement.FunctionStatement functionStatement)
                {
                    Name = name;
                    FunctionStatement = functionStatement;
                    Symboltype = "function";
                }
            }


            public class HardcodedFunctionSymbol : FunctionSymbol
            {
                public HardcodedFunctionSymbol(string name, Datatype? resultDatatype) : base(name, new FunctionStatement()) {
                    this.FunctionStatement.Name.Lexeme = name;
                    if (resultDatatype != null)
                        this.FunctionStatement.ResultDatatype = resultDatatype;
                }
            }


            public class FunctionParameterSymbol : VariableSymbol
            {
                public Statement.FunctionStatement.FunctionParameter FunctionParameter;
                public Statement.FunctionStatement TheFunction;

                public FunctionParameterSymbol(string name, Statement.FunctionStatement.FunctionParameter par, Statement.FunctionStatement theFunction) : base(name, par.TheType)
                {
                    Name = name;
                    FunctionParameter = par;
                    TheFunction = theFunction;
                    Symboltype = "function par";
                }
            }

        }

    }
}
