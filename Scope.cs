using GroundCompiler.Statements;
using GroundCompiler.Symbols;

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

        public string? GetNameIncludingLocalScope(string id)
        {
            if (Contains(id) && Symboltable[id] is LocalVariableSymbol)
                return $"{id}@{Owner.GetScopeName().Lexeme}";

            if (Parent != null)
                return Parent.GetNameIncludingLocalScope(id);

            return null;
        }


        public Datatype GetVariableDataType(string id)
        {
            var theSymbol = GetVariableAnywhere(id);
            if (theSymbol != null)
            {
                if (theSymbol is LocalVariableSymbol)
                    return (theSymbol as LocalVariableSymbol)!.DataType;
                if (theSymbol is LocalVariableSymbol)
                    return (theSymbol as FunctionParameterSymbol)!.DataType;
            }
            return Datatype.GetDatatype("i64");
        }

        public StringConstantSymbol? GetString(string str)
        {
            string id = IdFor(str, "const str");
            return GetStringById(id);
        }

        public FunctionSymbol? GetFunction(string name)
        {
            string id = IdFor(name, "function");
            return Symboltable[id] as FunctionSymbol;
        }

        public FunctionSymbol? GetFunctionAnywhere(string name)
        {
            if (Contains(name))
                return Symboltable[name] as FunctionSymbol;

            if (Parent != null)
                return Parent.GetFunctionAnywhere(name);

            return null;
        }

        public StringConstantSymbol? GetStringById(string id)
        {
            return Symboltable[id] as StringConstantSymbol;
        }

        public FloatConstantSymbol? GetFloatById(string id)
        {
            return Symboltable[id] as FloatConstantSymbol;
        }

        public List<LocalVariableSymbol> GetVariableSymbols()
        {
            List<LocalVariableSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as LocalVariableSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<LocalVariableSymbol> GetInstanceVariableSymbols()
        {
            List<LocalVariableSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as LocalVariableSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<FloatConstantSymbol> GetLiteralFloatSymbols()
        {
            List<FloatConstantSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as FloatConstantSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<StringConstantSymbol> GetStringSymbols()
        {
            List<StringConstantSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                var aVar = symbol as StringConstantSymbol;
                if (aVar != null)
                    result.Add(aVar);
            }
            return result;
        }

        public List<FunctionStatement> GetFunctionStatements()
        {
            List<FunctionStatement> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                if (symbol is HardcodedFunctionSymbol)
                    continue;
                if (symbol is DllFunctionSymbol)
                    continue;
                if (symbol is FunctionSymbol)
                {
                    FunctionSymbol theFunction = (FunctionSymbol)symbol;
                    result.Add(theFunction.FunctionStmt);
                    var childFunctionSymbols = theFunction.FunctionStmt.GetScope()!.GetFunctionStatements();
                    foreach (var childFunctionSymbol in childFunctionSymbols)
                        result.Add(childFunctionSymbol);
                }
                if (symbol is GroupSymbol groupSymbol)
                {
                    if (groupSymbol.GroupStatement.Properties.ContainsKey("don't generate"))
                        continue;

                    foreach (var groupFunction in groupSymbol.GroupStatement.FunctionNodes)
                        result.Add(groupFunction);
                }
            }
            return result;
        }

        public List<ClassSymbol> GetClassSymbols()
        {
            List<ClassSymbol> result = new();
            foreach (var symbol in Symboltable.Values)
            {
                if (symbol is HardcodedFunctionSymbol)
                    continue;
                if (symbol is ClassSymbol)
                    result.Add((symbol as ClassSymbol)!);
            }
            return result;
        }

        public string IdFor(string name, string datatype)
        {
            if (datatype == "const str")
                return "str_" + name;

            if (datatype == "const float")
                return "float_" + name.Replace(".","_").Replace("-","min");

            return name;
        }

        public LocalVariableSymbol DefineVariable(string name, Datatype datatype, bool allowSameType=false)
        {
            string id = IdFor(name, datatype.Name);
            if (Symboltable.ContainsKey(id))
            {
                if (allowSameType && Symboltable[id] is LocalVariableSymbol localVariable)
                    return localVariable;

                Step6_Compiler.Error($"{name} already defined.");
            }

            var newElement = new LocalVariableSymbol(name, datatype);
            Symboltable[id] = newElement;
            return newElement;
        }

        public void RemoveVariable(string name, string datatype = "i64")
        {
            string id = IdFor(name, datatype);
            Symboltable.Remove(id);
        }

        public HardcodedVariable DefineHardcodedVariable(string name, Datatype datatype)
        {
            string id = IdFor(name, datatype.Name);
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new HardcodedVariable(name, datatype);
            Symboltable[id] = newElement;
            return newElement;
        }

        public FunctionSymbol DefineFunction(FunctionStatement functionStatement)
        {
            string name = functionStatement.Name.Lexeme;
            string id = IdFor(name, "function");
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new FunctionSymbol(name, functionStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public ClassSymbol DefineClass(ClassStatement classStatement)
        {
            string name = classStatement.Name.Lexeme;
            string id = IdFor(name, "class");
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new ClassSymbol(name, classStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public GroupSymbol DefineGroup(GroupStatement groupStatement)
        {
            string name = groupStatement.Name.Lexeme;
            string id = IdFor(name, "group");
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new GroupSymbol(name, groupStatement);
            Symboltable[name] = newElement;
            return newElement;
        }

        public DllFunctionSymbol DefineDllFunction(FunctionStatement functionStatement, Datatype? resultDatatype = null)
        {
            string name = functionStatement.Name.Lexeme;
            string id = IdFor(name, "function");
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new DllFunctionSymbol(name, functionStatement, resultDatatype);
            Symboltable[name] = newElement;
            return newElement;
        }

        public HardcodedFunctionSymbol DefineHardcodedFunction(string name, Datatype? resultDatatype = null)
        {
            string id = IdFor(name, "function");
            if (Symboltable.ContainsKey(id))
                Step6_Compiler.Error($"{name} already defined.");

            var newElement = new HardcodedFunctionSymbol(name, resultDatatype);
            Symboltable[name] = newElement;
            return newElement;
        }

        public void DefineFunctionParameters(FunctionStatement functionStatement)
        {
            string classPrefix = (functionStatement.classStatement != null) ? functionStatement.classStatement.Name.Lexeme : "";
            foreach (var par in functionStatement.Parameters) {
                string id = IdFor($"{classPrefix}_{par.Name}", "function par");
                if (Symboltable.ContainsKey(id))
                    Step6_Compiler.Error($"{par.Name} already defined.");

                var newElement = new FunctionParameterSymbol(par.Name, par, functionStatement);
                Symboltable[par.Name] = newElement;
            }
        }

        public Symbol DefineParentScopeParameter(string name, Datatype datatype, int levelsDeep, IScopeStatement scopeStatement, LocalVariableSymbol localVar)
        {
            var newElement = new ParentScopeVariable(name, datatype, levelsDeep, scopeStatement, localVar);
            Symboltable[name] = newElement;
            return newElement;
        }


        public static int StringCounter = 0;
        public StringConstantSymbol? DefineString(string str)
        {
            Scope rootScope = GetRootScope();

            string id = IdFor(str, "const str");
            if (rootScope.Contains(id))
                return rootScope.GetStringById(id);

            var newElement = new StringConstantSymbol(str, $"str{StringCounter++}");
            rootScope.Symboltable[id] = newElement;
            return newElement;
        }

        public FloatConstantSymbol? DefineFloatingpoint(double d)
        {
            Scope rootScope = GetRootScope();

            string id = IdFor(d.ToString(System.Globalization.CultureInfo.InvariantCulture), "const float");
            if (rootScope.Contains(id))
                return rootScope.GetFloatById(id);
            
            var newElement = new FloatConstantSymbol(d, id);
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
    }
}
