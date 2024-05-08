using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using static GroundCompiler.Scope.Symbol;

namespace GroundCompiler.AstNodes
{
    public abstract class Statement : AstNode
    {
        public Statement() { }

        public abstract R Accept<R>(IVisitor<R> visitor);

        public interface IVisitor<R>
        {
            R VisitorProgramNode(ProgramNode prog);
            R VisitorBlock(BlockStatement stmt);
            R VisitorVariableDeclaration(VarStatement stmt);
            R VisitorPoke(PokeStatement stmt);
            R VisitorWhile(WhileStatement stmt);
            R VisitorIf(IfStatement stmt);
            R VisitorExpression(ExpressionStatement stmt);
            R VisitorFunction(FunctionStatement stmt);
            R VisitorClass(ClassStatement stmt);
            R VisitorDll(DllStatement stmt);
            R VisitorGroup(GroupStatement stmt);
            R VisitorReturn(ReturnStatement stmt);
            R VisitorBreak(BreakStatement stmt);
            R VisitorAssembly(AssemblyStatement stmt);
        }


        public class BlockStatement : Statement
        {
            public bool shouldCleanTmpDereferenced = false;
            public bool shouldCleanDereferenced = false;

            public BlockStatement() {
            }

            public BlockStatement(List<Statement> statements) : this()
            {
                Nodes.AddRange(statements);
            }

            public override void Initialize()
            {
                UpdateParentInNodes();
                base.Initialize();
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorBlock(this);
            }
        }


        public class ProgramNode : FunctionStatement
        {
            public void AddHardcodedFunctions()
            {
                // group msvcrt
                var nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "msvcrt";

                List<FunctionStatement> functionStmts = new List<FunctionStatement>();
                GroupStatement group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);

                HardcodedFunctionSymbol fn = group.Scope.DefineHardcodedFunction("fgets", Datatype.GetDatatype("string"));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("stream", Datatype.GetDatatype("int")));
                fn.FunctionStmt.Parent = group;



                // group gc
                nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "gc";

                functionStmts = new List<FunctionStatement>();
                group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);

                group.Scope.DefineHardcodedFunction("input_int");
                group.Scope.DefineHardcodedFunction("input_string", Datatype.GetDatatype("string"));

                fn = group.Scope.DefineHardcodedFunction("ReadAllText", Datatype.GetDatatype("string"));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("filepath", Datatype.GetDatatype("string")));
                fn.FunctionStmt.Parent = group;

                fn = this.Scope.DefineHardcodedFunction("print");
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("string")));

                fn = this.Scope.DefineHardcodedFunction("println");
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("string")));

                fn = this.Scope.DefineHardcodedFunction("chr$", Datatype.GetDatatype("string"));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("intvalue", Datatype.GetDatatype("int")));

                fn = this.Scope.DefineHardcodedFunction("GC_Replace", Datatype.GetDatatype("string"));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("source", Datatype.GetDatatype("string")));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("search", Datatype.GetDatatype("string")));
                fn.FunctionStmt.Parameters.Add(new FunctionParameter("replace", Datatype.GetDatatype("string")));

                this.Scope.DefineHardcodedFunction("GC_WaitVBL");
                this.Scope.DefineHardcodedVariable("GC_CurrentExeDir", Datatype.GetDatatype("string"));
                this.Scope.DefineHardcodedVariable("GC_Screen_TextRows", Datatype.GetDatatype("int"));
                this.Scope.DefineHardcodedVariable("GC_Screen_TextColumns", Datatype.GetDatatype("int"));

                // Usage:   byte[61,36] screenArray = GC_ScreenText;
                var screenPtrDatatype = Datatype.GetDatatype("byte[]", new List<UInt64> { 61, 36 });
                screenPtrDatatype.IsValueType = true;
                this.Scope.DefineHardcodedVariable("GC_ScreenText", screenPtrDatatype);

                // Usage:   byte[61,36] colorsArray = GC_ScreenColors;
                screenPtrDatatype = Datatype.GetDatatype("byte[]", new List<UInt64> { 61, 36 });
                screenPtrDatatype.IsValueType = true;
                this.Scope.DefineHardcodedVariable("GC_ScreenColors", screenPtrDatatype);

                // Usage:   u32[61,36] screenArray = GC_ScreenText_U32;
                screenPtrDatatype = Datatype.GetDatatype("u32[]", new List<UInt64> { 61, 36 });
                screenPtrDatatype.IsValueType = true;
                this.Scope.DefineHardcodedVariable("GC_ScreenText_U32", screenPtrDatatype);

                // Usage:   u32[256] colortable = GC_Colortable;
                var colortablePtrDatatype = Datatype.GetDatatype("u32[]", new List<UInt64> { 256 });
                colortablePtrDatatype.IsValueType = true;
                this.Scope.DefineHardcodedVariable("GC_Colortable", colortablePtrDatatype);

                // Usage:   u16[16,256] screenFont = GC_ScreenFont;
                // or       byte[256,256] screenFont = GC_ScreenFont;
                var fontPtrDatatype = Datatype.GetDatatype("byte[]", new List<UInt64> { 256, 256 });
                fontPtrDatatype.IsValueType = true;
                this.Scope.DefineHardcodedVariable("GC_ScreenFont", fontPtrDatatype);



                // group sdl2
                nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "sdl2";

                functionStmts = new List<FunctionStatement>();
                group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);



                // group kernel32
                nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "kernel32";

                functionStmts = new List<FunctionStatement>();
                group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);



                // group sidelib
                nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "sidelib";

                functionStmts = new List<FunctionStatement>();
                group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);



                // group g
                /*
                nameToken = new Token(TokenType.Identifier);
                nameToken.Lexeme = "g";

                functionStmts = new List<FunctionStatement>();
                group = new GroupStatement(nameToken, functionStmts);
                group.Properties["don't generate"] = true;
                group.Parent = this;
                this.Scope.DefineGroup(group);
                */
            }

            public override void Initialize()
            {
                AddHardcodedFunctions();
                if (Body != null)
                {
                    Body.Parent = this;
                    Body.Initialize();
                }
            }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                foreach (AstNode node in Nodes)
                    foreach (AstNode child in node.FindAllNodes(typeToFind))
                        yield return child;

                if (Body != null)
                    foreach (AstNode child in Body.FindAllNodes(typeToFind))
                        yield return child;
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorProgramNode(this);
            }
        }


        public class VarStatement : Statement
        {
            public VarStatement(Datatype theType, Token name, Expression? initializer)
            {
                ResultType = theType;
                Name = name;
                Initializer = initializer;
            }

            public Datatype ResultType;
            public Token Name;
            public Expression? Initializer;

            public override void Initialize()
            {
                var scope = GetScope();
                Scope.Symbol.VariableSymbol varSymbol = scope?.DefineVariable(Name.Lexeme, ResultType);
                if (Initializer != null) { 
                    Initializer.Parent = this;
                    Initializer.Initialize();

                    // Hardcoded Arrays are valuetype. That must be respected in assigned variables.
                    //if (ResultType.Contains(Datatype.TypeEnum.Array) && Initializer.ExprType.Contains(Datatype.TypeEnum.Array) && (!Initializer.ExprType.IsReferenceType))
                    // Why is the line above removed: when we call a DLL function, the result is never a array type, because function have no result type.
                    // We should declare a returntype for a function, but the solution beneath is a shortcut.
                    if (ResultType.Contains(Datatype.TypeEnum.Array) && (!Initializer.ExprType.IsReferenceType))
                    {
                        ResultType.IsValueType = true;
                        varSymbol!.DataType = ResultType;
                    }
                }
                base.Initialize();
            }

            public override bool ReplaceInternalAstNode(AstNode oldNode, AstNode newNode)
            {
                if (Object.ReferenceEquals(Initializer, oldNode))
                {
                    newNode.Parent = this;
                    Initializer = (Expression)newNode;
                    return true;
                }
                return base.ReplaceInternalAstNode(oldNode, newNode);
            }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                foreach (AstNode node in Nodes)
                    foreach (AstNode child in node.FindAllNodes(typeToFind))
                        yield return child;

                if (Initializer != null)
                    foreach (AstNode child in Initializer.FindAllNodes(typeToFind))
                        yield return child;
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorVariableDeclaration(this);
            }
        }


        public class IfStatement : Statement
        {
            public IfStatement(Expression condition, Statement thenBranch, Statement? elseBranch)
            {
                Condition = condition;
                ThenBranch = thenBranch;
                ElseBranch = elseBranch;
            }

            public override void Initialize()
            {
                if (Condition != null) { Condition.Parent = this; Condition.Initialize(); }
                if (ThenBranch != null) { ThenBranch.Parent = this; ThenBranch.Initialize(); }
                if (ElseBranch != null) { ElseBranch.Parent = this; ElseBranch.Initialize(); }
                base.Initialize();
            }

            public Expression Condition { get; }
            public Statement ThenBranch { get; }
            public Statement? ElseBranch { get; }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorIf(this);
            }
        }


        public class AssemblyStatement : Statement
        {
            public AssemblyStatement(Token asmToken)
            {
                LiteralAsmCode = asmToken;
            }

            public Token LiteralAsmCode;

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorAssembly(this);
            }
        }


        public class PokeStatement : Statement
        {
            public PokeStatement(Datatype theSize, string variableName, Expression valueExpr)
            {
                SizeType = theSize;
                VariableName = variableName;
                ValueExpression = valueExpr;
            }

            public Datatype SizeType;
            public string VariableName;
            public Expression? ValueExpression;

            public override void Initialize()
            {
                if (ValueExpression != null) { ValueExpression.Parent = this; ValueExpression.Initialize(); }
                base.Initialize();
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorPoke(this);
            }
        }


        public class WhileStatement : Statement
        {
            public WhileStatement(Expression condition, Statement body)
            {
                Condition = condition;
                Body = body;
            }

            public override void Initialize()
            {
                if (Condition != null) { Condition.Parent = this; Condition.Initialize(); }
                if (Body != null) { Body.Parent = this; Body.Initialize(); }
                base.Initialize();
            }

            public Expression Condition { get; }
            public Statement Body { get; }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorWhile(this);
            }
        }


        public class DllStatement : Statement
        {
            public DllStatement(string groupName, FunctionStatement fStmt)
            {
                GroupName = groupName;
                FunctionStmt = fStmt;
                FunctionStmt.Properties["group"] = GroupName;
            }

            public override void Initialize()
            {
                if (FunctionStmt != null) {
                    FunctionStmt.Properties["dll"] = true;
                    FunctionStmt.Parent = this;
                    FunctionStmt.Initialize();
                }
                base.Initialize();

                var scope = this.GetScope();
                var theGroup = scope?.GetVariable(GroupName);
                if (theGroup != null)
                {
                    theGroup.GetGroupStatement().Scope.DefineDllFunction(FunctionStmt!);
                }

                //scope!.DefineDllFunction(FunctionStmt!);
            }

            public string GroupName { get; }
            public FunctionStatement FunctionStmt { get; }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorDll(this);
            }
        }


        public class ClassStatement : Statement, IScopeStatement
        {
            public ClassStatement(Token name, List<VarStatement> instanceVariables, List<FunctionStatement> methods)
            {
                Name = name;
                InstanceVariables = instanceVariables;
                Methods = methods;
                this.Scope = new Scope(this);
            }

            public override void Initialize()
            {
                UpdateParentInNodes();
                this.Scope.Parent = Parent?.GetScope() ?? null;

                Scope.Parent?.DefineClass(this);
                base.Initialize();

                foreach (var aFunctionStatement in Methods)
                {
                    aFunctionStatement.Parent = this;
                    aFunctionStatement.Initialize();
                }
                foreach (var aVarStatement in InstanceVariables)
                {
                    aVarStatement.Parent = this;
                    aVarStatement.Initialize();
                }
            }

            public Scope Scope;
            public Token Name;
            public List<VarStatement> InstanceVariables;
            public List<FunctionStatement> Methods;

            public Scope GetScopeFromStatement() => this.Scope;
            public Token GetScopeName() => this.Name;

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorClass(this);
            }
        }



        public class GroupStatement : Statement, IScopeStatement
        {
            public GroupStatement(Token name, List<FunctionStatement> methods)
            {
                Name = name;
                Methods = methods;
                this.Scope = new Scope(this);
            }

            public override void Initialize()
            {
                UpdateParentInNodes();
                this.Scope.Parent = Parent?.GetScope() ?? null;

                Scope.Parent?.DefineGroup(this);
                base.Initialize();

                foreach (var aFunctionStatement in Methods)
                {
                    aFunctionStatement.Parent = this;
                    aFunctionStatement.Initialize();
                }
            }

            public Scope Scope;
            public Token Name;
            public List<FunctionStatement> Methods;

            public Scope GetScopeFromStatement() => this.Scope;
            public Token GetScopeName() => this.Name;

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorGroup(this);
            }
        }



        public class ReturnStatement : Statement
        {
            public ReturnStatement(Expression? value)
            {
                Value = value;
            }

            public Expression? Value;

            public override void Initialize()
            {
                if (Value != null) { Value.Parent = this; Value.Initialize(); }
                base.Initialize();
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorReturn(this);
            }
        }


        public class BreakStatement : Statement
        {
            public BreakStatement(Token keyword)
            {
                Keyword = keyword;
            }

            public Token Keyword;

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorBreak(this);
            }
        }


        public class ExpressionStatement : Statement
        {
            public ExpressionStatement(Expression expression)
            {
                InnerExpression = expression;
            }

            public override void Initialize()
            {
                if (InnerExpression != null) { InnerExpression.Parent = this; InnerExpression.Initialize(); }
                base.Initialize();
            }

            public Expression InnerExpression { get; }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                if (InnerExpression != null)
                {
                    foreach (AstNode child in InnerExpression.FindAllNodes(typeToFind))
                        yield return child;
                }
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorExpression(this);
            }
        }


        public class FunctionParameter
        {
            public string Name { get; }

            public Datatype TheType { get; }

            public FunctionParameter(string theName, Datatype theType)
            {
                Name = theName;
                TheType = theType;
            }
        }


        public class FunctionStatement : Statement, IScopeStatement
        {
            public Scope Scope;
            public ClassStatement? classStatement = null;
            public GroupStatement? groupStatement = null;

            public FunctionStatement()
            {
                Name = new();
                Name.Lexeme = "main";
                Parameters = new();
                Body = new();
                this.Scope = new Scope(this);
            }

            public FunctionStatement(Token name, List<FunctionParameter> parameters, Statement.BlockStatement? body = null)
            {
                Name = name;
                Parameters = parameters;
                if (body != null)
                    body.Parent = this;
                Body = body;
                this.Scope = new Scope(this);
            }

            public override void Initialize()
            {
                UpdateParentInNodes();
                this.Scope.Parent = Parent?.GetScope() ?? null;

                classStatement = Parent as ClassStatement;
                groupStatement = Parent as GroupStatement;
                if (!this.Properties.ContainsKey("dll"))
                    Scope.Parent?.DefineFunction(this);

                base.Initialize();

                if (Body != null) {
                    Body.GetScope()?.DefineFunctionParameters(this);
                    Body.Parent = this;
                    Body.Initialize();
                }
            }

            public Scope GetScopeFromStatement() => this.Scope;
            public Token GetScopeName() => this.Name;

            public string? GetGroupOrClassName()
            {
                if (this.Parent is GroupStatement groupStatement)
                    return groupStatement.Name.Lexeme;

                if (this.Parent is ClassStatement classStatement)
                    return classStatement.Name.Lexeme;

                return null;
            }

            public Token Name { get; }
            public List<FunctionParameter> Parameters { get; set; }
            public Datatype? ResultDatatype;

            public Statement.BlockStatement? Body { get; }

            public bool AssemblyOnlyFunctionWithNoParameters() => this.Properties.ContainsKey("assembly only function") && this.Properties.ContainsKey("zero parameters");

            public bool NeedsRefcountStructure()
            {
                if (this.Properties.ContainsKey("assembly only function"))
                    return false;

                return true;
                /*  je kunt een statement als print("a"+1) maken en je hebt al reference counting.
                var varSymbols = this._functionStatement!.Body.GetScope()!.GetVariableSymbols();
                foreach (var varSymbol in varSymbols)
                    if (varSymbol.DataType.IsReferenceType)
                        return true;

                return false;
                */
            }


            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorFunction(this);
            }
        }


    }
}
