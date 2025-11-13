using System.Diagnostics;
using GroundCompiler.Expressions;

namespace GroundCompiler.Statements
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
            R VisitorReturn(ReturnStatement stmt);
            R VisitorBreak(BreakStatement stmt);
            R VisitorContinue(ContinueStatement stmt);
            R VisitorAssembly(AssemblyStatement stmt);
        }

        public string getScopeName() => ((IScopeStatement)(this.GetScope()!.Owner)).GetScopeName().Lexeme;
    }


    public class ProgramNode : FunctionStatement
    {
        // The inheritance from FunctionStatement is not a very good match. For instance, the base.initializer cannot be called.

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

            fn = group.Scope.DefineHardcodedFunction("strlen", Datatype.GetDatatype("int"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("filepath", Datatype.GetDatatype("string")));

            fn = group.Scope.DefineHardcodedFunction("cstr_len", Datatype.GetDatatype("int"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("filepath", Datatype.GetDatatype("string")));

            fn = group.Scope.DefineHardcodedFunction("cstr_linelen", Datatype.GetDatatype("int"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("filepath", Datatype.GetDatatype("string")));

            fn = group.Scope.DefineHardcodedFunction("ReadAllText", Datatype.GetDatatype("string"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("filepath", Datatype.GetDatatype("string")));
            fn.FunctionStmt.Parent = group;

            fn = group.Scope.DefineHardcodedFunction("BitValue", Datatype.GetDatatype("int"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("value", Datatype.GetDatatype("int")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("bitnr", Datatype.GetDatatype("int")));
            fn.FunctionStmt.Parent = group;

            fn = this.Scope.DefineHardcodedFunction("print");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("string")));

            fn = this.Scope.DefineHardcodedFunction("colorprint");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("color", Datatype.GetDatatype("byte")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("string")));

            fn = this.Scope.DefineHardcodedFunction("println");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("string")));

            fn = this.Scope.DefineHardcodedFunction("assert");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("input", Datatype.GetDatatype("bool")));

            fn = this.Scope.DefineHardcodedFunction("chr$", Datatype.GetDatatype("string"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("intvalue", Datatype.GetDatatype("int")));

            fn = this.Scope.DefineHardcodedFunction("PlotSprite");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("source", Datatype.GetDatatype("ptr")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("destination", Datatype.GetDatatype("ptr")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("width", Datatype.GetDatatype("int")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("height", Datatype.GetDatatype("int")));

            fn = this.Scope.DefineHardcodedFunction("PlotSheetSprite");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("source", Datatype.GetDatatype("ptr")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("destination", Datatype.GetDatatype("ptr")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("width", Datatype.GetDatatype("int")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("height", Datatype.GetDatatype("int")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("sheetwidth", Datatype.GetDatatype("int")));

            fn = this.Scope.DefineHardcodedFunction("GC_Replace", Datatype.GetDatatype("string"));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("source", Datatype.GetDatatype("string")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("search", Datatype.GetDatatype("string")));
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("replace", Datatype.GetDatatype("string")));

            this.Scope.DefineHardcodedFunction("GC_CreateThread", Datatype.GetDatatype("ptr"));
            this.Scope.DefineHardcodedVariable("GC_CurrentExeDir", Datatype.GetDatatype("string"));
            this.Scope.DefineHardcodedFunction("zero");
            this.Scope.DefineHardcodedFunction("sizeof", Datatype.GetDatatype("int"));
            this.Scope.DefineHardcodedFunction("countof", Datatype.GetDatatype("int"));

            fn = this.Scope.DefineHardcodedFunction("SDL3_ClearScreenPixels");
            fn.FunctionStmt.Parameters.Add(new FunctionParameter("color", Datatype.GetDatatype("int")));

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

            var dllStatements = this.AllNodes().OfType<DllStatement>().ToList();
            foreach (var dllStmt in dllStatements)
            {
                string groupName = dllStmt.GroupName;
                if (!this.Scope.Contains(groupName))
                    AddDynamicDLL(groupName);
            }
        }

        public void AddDynamicDLL(string dllName)
        {
            var nameToken = new Token(TokenType.Identifier);
            nameToken.Lexeme = dllName;

            var functionStmts = new List<FunctionStatement>();
            var group = new GroupStatement(nameToken, functionStmts);
            group.Properties["don't generate"] = true;
            group.Parent = this;
            this.Scope.DefineGroup(group);
        }

        public override void Initialize()
        {
            AddHardcodedFunctions();
            if (BodyNode != null)
            {
                BodyNode.Parent = this;
                BodyNode.Initialize();
            }
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorProgramNode(this);
        }
    }


    public class BlockStatement : Statement
    {
        public bool shouldCleanTmpDereferenced = false;
        public bool shouldCleanDereferenced = false;

        public BlockStatement()
        {
        }

        public BlockStatement(List<Statement> statements) : this()
        {
            foreach (Statement s in statements)
                AddNode(s);
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorBlock(this);
        }
    }


    // Models a variable declaration like: int i = 10;   Or class instance like:  AClass inst;  (no constructor possible at this moment in time)
    public class VarStatement : Statement
    {
        public Expression? InitializerNode;

        public Datatype ResultType;
        public Token Name;

        public VarStatement(Datatype theType, Token name, Expression? initializer)
        {
            ResultType = theType;
            Name = name;
            InitializerNode = initializer;
        }

        public override void Reinitialize()
        {
            SpecializedInitialize(allowRedefine: true);
        }

        public override void Initialize()
        {
            SpecializedInitialize();
        }


        public void SpecializedInitialize(bool allowRedefine = false)
        {
            var scope = GetScope();
            VariableSymbol varSymbol = scope?.DefineVariable(Name.Lexeme, ResultType, allowSameType: Properties.ContainsKey("for-loop-variable") || allowRedefine);

            if (InitializerNode != null)
            {
                InitializerNode.Parent = this;
                InitializerNode.Initialize();

                if (InitializerNode is Expressions.List listExpr)
                {
                    varSymbol.Properties["assigned element"] = listExpr;
                    InitializerNode.ExprType = ResultType;
                    if (listExpr.Properties.ContainsKey("fixed"))
                        varSymbol.Properties["asm array"] = true;
                }

                // Hardcoded Arrays (ASM arrays) are valuetype. That must be respected in assigned variables.
                //if (ResultType.Contains(Datatype.TypeEnum.Array) && Initializer.ExprType.Contains(Datatype.TypeEnum.Array) && (!Initializer.ExprType.IsReferenceType))
                // Why is the line above removed: when we call a DLL function, the result is never a array type, because function have no result type.
                // We should declare a returntype for a function, but the solution beneath is a shortcut.
                if (ResultType.Contains(Datatype.TypeEnum.Array) && (!InitializerNode.ExprType.IsReferenceType))
                {
                    ResultType.IsValueType = true;
                    varSymbol!.DataType = ResultType;
                }
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(InitializerNode, oldNode))
            {
                newNode.Parent = this;
                InitializerNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (InitializerNode != null)
                    yield return InitializerNode;
            }
        }

        public string? GetNameIncludingLocalScope() => this.GetScope()?.GetNameIncludingLocalScope(Name.Lexeme);

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorVariableDeclaration(this);
        }
    }



    public class IfStatement : Statement
    {
        public Expression ConditionNode;
        public Statement ThenBranchNode;
        public Statement? ElseBranchNode;

        public IfStatement(Expression condition, Statement thenBranch, Statement? elseBranch)
        {
            ConditionNode = condition;
            ThenBranchNode = thenBranch;
            ElseBranchNode = elseBranch;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ConditionNode != null)
                    yield return ConditionNode;

                if (ThenBranchNode != null)
                    yield return ThenBranchNode;

                if (ElseBranchNode != null)
                    yield return ElseBranchNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ConditionNode, oldNode))
            {
                newNode.Parent = this;
                ConditionNode = (Expression)newNode;
                return true;
            }
            if (Object.ReferenceEquals(ThenBranchNode, oldNode))
            {
                newNode.Parent = this;
                ThenBranchNode = (Statement)newNode;
                return true;
            }
            if (Object.ReferenceEquals(ElseBranchNode, oldNode))
            {
                newNode.Parent = this;
                ElseBranchNode = (Statement)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorIf(this);
        }
    }


    // Models assembly code. It is just a literal insert into the generated code.
    public class AssemblyStatement : Statement
    {
        public Token LiteralAsmCode;

        public AssemblyStatement(Token asmToken)
        {
            LiteralAsmCode = asmToken;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorAssembly(this);
        }
    }


    //Set a value direct into an assembly variable.   poke.q next_copperline, 0;
    public class PokeStatement : Statement
    {
        public Expression? ValueExpressionNode;
        public Datatype SizeType;
        public string VariableName;

        public PokeStatement(Datatype theSize, string variableName, Expression valueExpr)
        {
            SizeType = theSize;
            VariableName = variableName;
            ValueExpressionNode = valueExpr;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ValueExpressionNode != null)
                    yield return ValueExpressionNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ValueExpressionNode, oldNode))
            {
                newNode.Parent = this;
                ValueExpressionNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorPoke(this);
        }
    }


    public class WhileStatement : Statement
    {
        public Expression ConditionNode;
        public Statement BodyNode;
        public Statement? IncrementNode;     // for-loop situation if available

        public WhileStatement(Expression condition, Statement body, Statement? incrementNode = null)
        {
            ConditionNode = condition;
            BodyNode = body;
            IncrementNode = incrementNode;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ConditionNode != null)
                    yield return ConditionNode;

                if (BodyNode != null)
                    yield return BodyNode;

                if (IncrementNode != null)
                    yield return IncrementNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ConditionNode, oldNode))
            {
                newNode.Parent = this;
                ConditionNode = (Expression)newNode;
                return true;
            }
            if (Object.ReferenceEquals(BodyNode, oldNode))
            {
                newNode.Parent = this;
                BodyNode = (Statement)newNode;
                return true;
            }
            if (Object.ReferenceEquals(IncrementNode, oldNode))
            {
                newNode.Parent = this;
                IncrementNode = (Statement)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorWhile(this);
        }
    }


    // Models a call to an external DLL, like:  dll sdl3_image function IMG_Load(string filename) : ptr;
    public class DllStatement : Statement
    {
        public FunctionStatement FunctionStmtNode;
        public string GroupName;

        public DllStatement(string groupName, FunctionStatement fStmt)
        {
            GroupName = groupName;
            FunctionStmtNode = fStmt;
            FunctionStmtNode.Properties["group"] = GroupName;
        }

        public override void Initialize()
        {
            if (FunctionStmtNode != null)
            {
                FunctionStmtNode.Properties["dll"] = true;
                FunctionStmtNode.Parent = this;
                FunctionStmtNode.Initialize();
            }

            var scope = this.GetScope();
            var theGroup = scope?.GetVariable(GroupName);
            if (theGroup != null)
                theGroup.GetGroupStatement()?.Scope.DefineDllFunction(FunctionStmtNode!);
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (FunctionStmtNode != null)
                    yield return FunctionStmtNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(FunctionStmtNode, oldNode))
            {
                newNode.Parent = this;
                FunctionStmtNode = (FunctionStatement)newNode;
                return true;
            }
            return false;
        }

        public override T Accept<T>(IVisitor<T> visitor) => default!;
    }


    // Models a Class, including instance variables and functions.
    // In WIN32 programming, you can define instance variables and use an instance of the class as a structure that can be filled.
    public class ClassStatement : Statement, IScopeStatement
    {
        public List<VarStatement> InstanceVariableNodes;
        public List<FunctionStatement> FunctionNodes;

        public Scope Scope;
        public Token Name;

        public ClassStatement(Token name, List<VarStatement> instanceVariables, List<FunctionStatement> theFunctions)
        {
            Name = name;
            InstanceVariableNodes = instanceVariables;
            FunctionNodes = theFunctions;
            this.Scope = new Scope(this);
        }

        public override void Initialize()
        {
            this.Scope.Parent = Parent?.GetScope() ?? null;
            Scope.Parent?.DefineClass(this);
            base.Initialize();
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                foreach (AstNode node in InstanceVariableNodes)
                    yield return node;

                foreach (AstNode node in FunctionNodes)
                    yield return node;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < InstanceVariableNodes.Count; i++)
            {
                AstNode node = InstanceVariableNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    InstanceVariableNodes[i] = (VarStatement)newNode;
                    return true;
                }
            }
            for (int i = 0; i < FunctionNodes.Count; i++)
            {
                AstNode node = FunctionNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    FunctionNodes[i] = (FunctionStatement)newNode;
                    return true;
                }
            }
            return false;
        }

        public int Align(int sizeOfVariable, int currentIndex)
        {
            if (this.IsPacked())
                return 0;
            int bytesOutOfAlignment = currentIndex % sizeOfVariable;
            if (bytesOutOfAlignment == 0)
                return 0;
            int toAdd = sizeOfVariable - bytesOutOfAlignment;
            return toAdd;
        }

        public int SizeInBytes()
        {
            // Every instance must be aligned on it's natural size (2,4,8) according the x64 ABI (Application Binary Interface)
            // However, a struct like BitmapFileHeader is an old format that uses no alignment.
            // When the "alignment" property is "packed", it will use no alignment. 
            int result = 0;

            foreach (var inst in this.InstanceVariableNodes)
            {
                int sizeOfVariable = inst.ResultType.SizeInBytes;
                int sizeAddedForAlignment = this.Align(sizeOfVariable, result);
                result += sizeAddedForAlignment;
                result += sizeOfVariable;
            }

            return result;
        }

        public void SetPacked() => this.Properties["alignment"] = "packed";
        public bool IsPacked() => (this.Properties.ContainsKey("alignment") && ((string)this.Properties["alignment"]!) == "packed");

        public Scope GetScopeFromStatement() => this.Scope;
        public Token GetScopeName() => this.Name;

        public override T Accept<T>(IVisitor<T> visitor) => default!;
    }


    // groups multiple functions, so you can avoid name collisions.
    // group msvcrt { function read() { }  function write() {} }
    public class GroupStatement : Statement, IScopeStatement
    {
        public List<FunctionStatement> FunctionNodes;

        public Scope Scope;
        public Token Name;

        public GroupStatement(Token name, List<FunctionStatement> theFunctions)
        {
            Name = name;
            FunctionNodes = theFunctions;
            this.Scope = new Scope(this);
        }

        public override void Initialize()
        {
            this.Scope.Parent = Parent?.GetScope() ?? null;
            Scope.Parent?.DefineGroup(this);

            base.Initialize();
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                foreach (AstNode node in FunctionNodes)
                    yield return node;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < FunctionNodes.Count; i++)
            {
                AstNode node = FunctionNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    FunctionNodes[i] = (FunctionStatement)newNode;
                    return true;
                }
            }
            return false;
        }

        public Scope GetScopeFromStatement() => this.Scope;
        public Token GetScopeName() => this.Name;

        public override T Accept<T>(IVisitor<T> visitor) => default!;
    }


    // Models a Return statement, the last statement of a function() to return the result.
    public class ReturnStatement : Statement
    {
        public Expression? ReturnValueNode;

        public ReturnStatement(Expression? value)
        {
            ReturnValueNode = value;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ReturnValueNode != null)
                    yield return ReturnValueNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ReturnValueNode, oldNode))
            {
                newNode.Parent = this;
                ReturnValueNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorReturn(this);
        }
    }


    // Models a Break statement, which can be used to break a While loop.
    public class BreakStatement : Statement
    {
        public Token Keyword;

        public BreakStatement(Token keyword)
        {
            Keyword = keyword;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorBreak(this);
        }
    }


    public class ContinueStatement : Statement
    {
        public Token Keyword;

        public ContinueStatement(Token keyword)
        {
            Keyword = keyword;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorContinue(this);
        }
    }


    // A statement that contains an expression, which can be an assignment or other expression. It is the last resort in Parser.ParseStatement.
    public class ExpressionStatement : Statement
    {
        public Expression ExpressionNode;

        public ExpressionStatement(Expression expression)
        {
            ExpressionNode = expression;
        }
        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ExpressionNode != null)
                    yield return ExpressionNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ExpressionNode, oldNode))
            {
                newNode.Parent = this;
                ExpressionNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorExpression(this);
        }
    }


    // A helper for FunctionStatement
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


    // Models functions like: function name(int i) { println("code"); }
    public class FunctionStatement : Statement, IScopeStatement
    {
        public BlockStatement? BodyNode;

        public Token Name;
        public List<FunctionParameter> Parameters;
        public Datatype? ResultDatatype;

        public Scope Scope;
        public ClassStatement? classStatement = null;
        public GroupStatement? groupStatement = null;

        public FunctionStatement()
        {
            Name = new();
            Name.Lexeme = "main";
            Parameters = new();
            BodyNode = new();
            this.Scope = new Scope(this);
        }

        public FunctionStatement(Token name, List<FunctionParameter> theParameters, BlockStatement? body = null)
        {
            Name = name;
            Parameters = theParameters;
            BodyNode = body;
            UpdateParentInNodes();
            this.Scope = new Scope(this);
        }

        public void AddUsedRegister(string reg)
        {
            if (Properties.ContainsKey("in EmittedProcedure"))
            {
                if (!Properties.ContainsKey("used registers"))
                    Properties["used registers"] = new HashSet<string>();

                var regs = Properties["used registers"] as HashSet<string>;
                regs.Add(reg);
            }
        }

        public List<string> UsedRegisters()
        {
            if (Properties.ContainsKey("used registers"))
            {
                var regs = Properties["used registers"] as HashSet<string>;
                return new List<string>(regs);
            }
            return new List<string>();
        }

        public override void Initialize()
        {
            UpdateParentInNodes();
            this.Scope.Parent = Parent?.GetScope() ?? null;

            classStatement = Parent as ClassStatement;
            groupStatement = Parent as GroupStatement;
            if (!this.Properties.ContainsKey("dll"))
                Scope.Parent?.DefineFunction(this);

            if (BodyNode != null)
            {
                BodyNode.GetScope()?.DefineFunctionParameters(this);
                BodyNode.Initialize();
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

        public bool AssemblyOnlyFunctionWithNoParameters() => this.Properties.ContainsKey("assembly only function") && this.Properties.ContainsKey("zero parameters");

        public bool NeedsRefcountStructure()
        {
            if (this.Properties.ContainsKey("assembly only function"))
                return false;

            return true;
            /*  je kunt een statement als print("a"+1) maken en je hebt al reference counting. Dus voorlopig doen we true. Later kunnen we doen:
            var varSymbols = this._functionStatement!.Body.GetScope()!.GetVariableSymbols();
            foreach (var varSymbol in varSymbols)
                if (varSymbol.DataType.IsReferenceType)
                    return true;
            return false;
            */
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (BodyNode != null)
                    yield return BodyNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(BodyNode, oldNode))
            {
                newNode.Parent = this;
                BodyNode = (BlockStatement)newNode;
                return true;
            }
            return false;
        }

        public override T Accept<T>(IVisitor<T> visitor) => default!;
    }


}
