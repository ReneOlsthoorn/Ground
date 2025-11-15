using System.Diagnostics;
using GroundCompiler.Statements;

namespace GroundCompiler.Expressions
{
    public abstract class Expression : AstNode
    {
        public Datatype ExprType = Datatype.Default;    // This is the result datatype for this expression. In the initialize phase, the type is determined.

        public abstract T Accept<T>(IVisitor<T> visitor);

        public interface IVisitor<T>
        {
            T VisitorPropertyGet(PropertyExpression expr);
            T VisitorPropertySet(PropertySet expr);
            T VisitorAssignment(Assignment expr);
            T VisitorBinary(Binary expr);
            T VisitorFunctionCall(FunctionCall expr);
            T VisitorGrouping(Grouping expr);
            T VisitorLiteral(Literal expr);
            T VisitorUnary(Unary expr);
            T VisitorVariable(Variable expr);
            T VisitorList(List expr);
            T VisitorArrayAccess(ArrayAccess expr);
        }

        public string getScopeName() => ((IScopeStatement)(this.GetScope()?.Owner))?.GetScopeName()?.Lexeme ?? "";

        public Symbol? GetSymbol(string name, Scope scope)
        {
            if (name == "g")
                return new GroupSymbol("g");

            var symbol = scope.GetVariable(name);
            if (symbol == null)
            {
                symbol = scope.GetVariableAnywhere(name);
                if (symbol == null)
                    Step6_Compiler.Error($"Symbol {name} does not exist.");

                if (symbol is HardcodedVariable || symbol is HardcodedFunctionSymbol || symbol is FunctionSymbol || symbol is GroupSymbol || symbol is ClassSymbol)
                    return symbol;

                // At this point, the symbol is available but it is in a parent scope, so a ParentScopeVariable must be inserted in the symboltable.
                LocalVariableSymbol? variableSymbol = symbol as LocalVariableSymbol;
                int levelsDeep = 0;
                var needleScope = scope;
                IScopeStatement? ownerScope = needleScope.Owner;
                while (!needleScope.Contains(name))
                {
                    if (!(ownerScope is ClassStatement || ownerScope is GroupStatement || ownerScope is ProgramNode))   // Dit zijn niet echte calling scopes.
                        levelsDeep++;

                    needleScope = needleScope.Parent;
                    if (needleScope == null)
                        break;

                    ownerScope = needleScope.Owner;
                }
                if (ownerScope == null)
                    Step6_Compiler.Error("Expression>>GetSymbol error.");

                return scope.DefineParentScopeParameter(name, variableSymbol!.DataType, levelsDeep, ownerScope!, variableSymbol!);
            }

            return symbol;
        }


        public static bool CombinationContaining(List<Expression> nodes, List<Datatype.TypeEnum> theTypes)
        {
            foreach (Datatype.TypeEnum theType in theTypes)
            {
                bool found = false;
                foreach (Expression node in nodes)
                {
                    found = node.ExprType.Contains(theType);
                    if (found)
                        break;
                }

                if (!found)
                    return false;
            }
            return true;
        }

        public static bool HasNodeWithDatatype(List<Expression> nodes, Datatype.TypeEnum theType)
        {
            foreach (Expression node in nodes)
                if (node.ExprType.Contains(theType))
                    return true;
            return false;
        }


        public static Expression? GetNodeWithDatatype(List<Expression> nodes, Datatype.TypeEnum theType)
        {
            List<Expression> matches = new List<Expression>();
            foreach (Expression node in nodes)
                if (node.ExprType.Contains(theType))
                    matches.Add(node);

            // als er meerdere nodes gevonden zijn, haal dan de literal nodes eruit. Een literal heeft namelijk minder zwaarte dan een variabele om ExprType te bepalen.
            if (matches.Count >= 2)
            {
                var newMatches = matches.Where(el => !(el is Literal)).ToList();
                if (newMatches.Count > 0)
                    matches = newMatches;
            }

            // als er nu nog steeds meerdere zijn, dan moet je de grootste SizeInBytes pakken.
            //if (matches.Count >= 2)
            //    matches.OrderByDescending(el => el.ExprType.SizeInBytes);

            if (matches.Count >= 1)
                return matches.First();
            return null;
        }

    }

    public class ThisExpression : Expression
    {
        public Token Keyword;

        public ThisExpression(Token keyword)
        {
            this.Keyword = keyword;
        }

        public override void Initialize()
        {
            var scope = GetScope();

            var classStmt = this.FindParentType(typeof(ClassStatement)) as ClassStatement;
            if (classStmt != null)
                ExprType = Datatype.GetDatatype(classStmt.Name.Lexeme);
        }

        public override T Accept<T>(IVisitor<T> visitor) => default!;
    }


    // identifier.identifier
    public class PropertyExpression : Expression
    {
        public Expression ObjectNode;
        public Token Name;

        public PropertyExpression(Expression @object, Token name)
        {
            ObjectNode = @object;
            Name = name;
        }

        public override void Initialize()
        {
            base.Initialize();

            ClassStatement? classStatement = null;
            if (ObjectNode.ExprType.isClass() || Datatype.IsPointerType(ObjectNode.ExprType))
            {
                if (Datatype.IsPointerType(ObjectNode.ExprType))
                    classStatement = ObjectNode.ExprType.Base.Properties["classStatement"] as ClassStatement;
                else
                    classStatement = ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;

                var classScope = classStatement!.GetScope();
                var theVar = classScope!.GetVariable(Name.Lexeme);

                // method
                if (theVar is FunctionSymbol funcSymbol)
                {
                    var resultDatatype = funcSymbol.FunctionStmt.ResultDatatype;
                    if (resultDatatype != null)
                        ExprType = resultDatatype;
                }
                else if (theVar is LocalVariableSymbol localVariableSymbol)
                {
                    var resultDatatype = localVariableSymbol.DataType;
                    if (resultDatatype != null)
                        ExprType = resultDatatype;
                }
                else
                {
                    var instVarList = classStatement.InstanceVariableNodes.Find((instVariable) => instVariable.Name.Lexeme == Name.Lexeme);
                    if (instVarList != null)
                    {
                        ExprType = instVarList.ResultType;
                    }
                }
            }
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ObjectNode != null)
                    yield return ObjectNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ObjectNode, oldNode))
            {
                newNode.Parent = this;
                ObjectNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        public string? GetNameIncludingLocalScope() => this.GetScope()?.GetNameIncludingLocalScope(Name.Lexeme);

        [DebuggerStepThrough]
        public override T Accept<T>(IVisitor<T> visitor)
        {
            return visitor.VisitorPropertyGet(this);
        }
    }


    // identifier.identifier = Value
    public class PropertySet : Expression
    {
        public Expression ObjectNode;
        public Token Name;
        public Token AssignmentOperation;
        public Expression ValueNode;

        public PropertySet(Expression theObject, Token theName, Token theAssignmentOperation, Expression theValue)
        {
            ObjectNode = theObject;
            Name = theName;
            ValueNode = theValue;
            AssignmentOperation = theAssignmentOperation;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (ObjectNode != null)
                    yield return ObjectNode;

                if (ValueNode != null)
                    yield return ValueNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(ObjectNode, oldNode))
            {
                newNode.Parent = this;
                ObjectNode = (Expression)newNode;
                return true;
            }
            if (Object.ReferenceEquals(ValueNode, oldNode))
            {
                newNode.Parent = this;
                ValueNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override T Accept<T>(IVisitor<T> visitor)
        {
            return visitor.VisitorPropertySet(this);
        }
    }


    // 1  or  "string"  
    public class Literal : Expression
    {
        public object? Value;

        public Literal(object? value)
        {
            Value = value;
        }
        public Literal(string theType, object? value) : this(value)
        {
            ExprType = Datatype.GetDatatype(theType);
        }

        public Literal(Datatype theType, object? value) : this(value)
        {
            ExprType = theType;
        }

        public Literal DeepCopy()
        {
            Literal result = new Literal(this.ExprType.DeepCopy(), this.Value);
            return result;
        }

        public override void Initialize()
        {
            if (ExprType.Name == "string")
                GetScope()?.DefineString((string)Value!);

            if (ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                GetScope()?.DefineFloatingpoint(Convert.ToDouble(Value));
        }

        public void ConvertToByteValue()
        {
            byte? byteValue = GetByteValue();
            if (byteValue != null)
            {
                Value = byteValue.Value;
                ExprType = Datatype.GetDatatype("byte");
            }
            else
                Step6_Compiler.Error("Literal: ConvertToByteValue error");
        }

        public byte? GetByteValue()
        {
            if ((ExprType.Name == "string") && (Value is string strValue) && (strValue.Length == 1))
                return Convert.ToByte(strValue[0]);

            if (ExprType.Contains(Datatype.TypeEnum.Integer))
            {
                byte byteVal = 0;
                try
                {
                    byteVal = Convert.ToByte(Value);
                }
                catch (OverflowException oe)
                {
                    Step6_Compiler.Error(oe.Message);
                }
                return byteVal;
            }

            return null;
        }

        [DebuggerStepThrough]
        public override T Accept<T>(IVisitor<T> visitor)
        {
            return visitor.VisitorLiteral(this);
        }
    }


    // i++ or -i
    public class Unary : Expression
    {
        public Token Operator;
        public Expression RightNode;
        public bool Postfix;

        public Unary(Token @operator, Expression right, bool postfix = false)
        {
            Operator = @operator;
            RightNode = right;
            Postfix = postfix;
        }

        public override void Initialize()
        {
            if (RightNode != null)
            {
                RightNode.Parent = this;
                RightNode.Initialize();
                this.ExprType = RightNode.ExprType;

                if (Operator.Contains(TokenType.Asterisk))
                    if (this.ExprType.Base != null)
                        this.ExprType = this.ExprType.Base;
            }
            if (Operator.Types.Contains(TokenType.Ampersand))
            {
                Datatype dt = Datatype.GetDatatype(ExprType.Name + "*");
                ExprType = dt;
            }
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (RightNode != null)
                    yield return RightNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(RightNode, oldNode))
            {
                newNode.Parent = this;
                RightNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorUnary(this);
        }
    }


    // Identifier
    public class Variable : Expression
    {
        public Token Name;

        public Variable(Token name)
        {
            Name = name;
        }

        public override void Initialize()
        {
            var scope = GetScope();
            var symbol = GetSymbol(Name.Lexeme, scope!);
            if (symbol is ParentScopeVariable)
                ExprType = (symbol as ParentScopeVariable)!.DataType;
            else if (symbol is LocalVariableSymbol)
                ExprType = (symbol as LocalVariableSymbol)!.DataType;
            else if (symbol is FunctionParameterSymbol)
                ExprType = (symbol as FunctionParameterSymbol)!.DataType;
            else if (symbol is HardcodedVariable)
                ExprType = (symbol as HardcodedVariable)!.DataType;
            else if (symbol is FunctionSymbol)
                ExprType = Datatype.GetDatatype("ptr");
            else
                ExprType = Datatype.Default;
        }

        public string? GetNameIncludingLocalScope() => this.GetScope()?.GetNameIncludingLocalScope(Name.Lexeme);

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorVariable(this);
        }
    }


    // [ 1, 2, 4 ]
    public class List : Expression
    {
        public readonly List<Expression> ElementsNodes;

        public List(List<Expression> elements)
        {
            ElementsNodes = elements;
        }

        public override void Initialize()
        {
            Datatype? elementType = null;

            //if (this.Parent is VarStatement varStmt)
            //    if (varStmt.ResultType.Contains(Datatype.TypeEnum.Array))
            //        elementType = varStmt.ResultType.Base;

            if (ElementsNodes != null)
            {
                foreach (var element in ElementsNodes)
                {
                    element.Parent = this;
                    element.Initialize();
                    if (elementType == null)
                        elementType = element.ExprType;
                    else if (!Datatype.IsCompatible(elementType, element.ExprType))
                        Step6_Compiler.Error("All elements in a List must have the same type");
                    else
                        element.ExprType = elementType;
                }
            }

            if (elementType != null)
                this.ExprType = Datatype.GetDatatype($"{elementType.Name}[]");
            else
                this.ExprType = Datatype.GetDatatype($"i64[]");
        }

        public UInt64 SizeInBytes()
        {
            UInt64 result = 80;  //default: 10 elements of 8 bytes.

            int sizeEachElement = this.ExprType.Base!.SizeInBytes;
            if (this.ExprType.hasArrayDefinition)
                result = this.ExprType.BytesToAllocate();
            else
            {
                UInt64 nrElements = (UInt64)this.Nodes.Count();
                if (nrElements > 0)
                    result = nrElements * (UInt64)sizeEachElement;
            }
            return result;
        }


        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                foreach (AstNode node in ElementsNodes)
                    yield return node;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < ElementsNodes.Count; i++)
            {
                AstNode node = ElementsNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    ElementsNodes[i] = (Expression)newNode;
                    return true;
                }
            }
            return false;
        }

        [DebuggerStepThrough]
        public override T Accept<T>(IVisitor<T> visitor)
        {
            return visitor.VisitorList(this);
        }
    }


    // tmp[2,3]
    public class ArrayAccess : Expression
    {
        public Expression MemberNode;
        public List<Expression> IndexNodes;

        public ArrayAccess(Expression member, List<Expression> theIndexes)
        {
            MemberNode = member;
            IndexNodes = theIndexes;
        }

        public override void Initialize()
        {
            base.Initialize();
            this.ExprType = MemberNode?.ExprType.Base ?? Datatype.Default;
        }

        public Variable? GetMemberVariable()
        {
            if (this.MemberNode is Variable)
                return (Variable)this.MemberNode;

            if (this.MemberNode is ArrayAccess)
            {
                var memberAccess = (ArrayAccess)this.MemberNode;
                return memberAccess.GetMemberVariable();
            }
            return null;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (MemberNode != null)
                    yield return MemberNode;

                foreach (AstNode node in IndexNodes)
                    yield return node;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(MemberNode, oldNode))
            {
                newNode.Parent = this;
                MemberNode = (Expression)newNode;
                return true;
            }
            for (int i = 0; i < IndexNodes.Count; i++)
            {
                AstNode node = IndexNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    IndexNodes[i] = (Expression)newNode;
                    return true;
                }
            }
            return false;
        }

        [DebuggerStepThrough]
        public override T Accept<T>(IVisitor<T> visitor)
        {
            return visitor.VisitorArrayAccess(this);
        }
    }


    // tmp = 10;
    public class Assignment : Expression
    {
        public Expression LeftOfEqualSignNode;
        public Expression RightOfEqualSignNode;
        public Token Operator;

        public Assignment(Expression left, Expression right, Token operatorToken)
        {
            LeftOfEqualSignNode = left;
            RightOfEqualSignNode = right;
            Operator = operatorToken;  // = or later perhaps += and -=
        }
        public override void Initialize()
        {
            if (LeftOfEqualSignNode is Variable variableExpr)
                GetSymbol(variableExpr.Name.Lexeme, GetScope()!);  // Define pass-through parameters

            base.Initialize();
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (LeftOfEqualSignNode != null)
                    yield return LeftOfEqualSignNode;

                if (RightOfEqualSignNode != null)
                    yield return RightOfEqualSignNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(LeftOfEqualSignNode, oldNode))
            {
                newNode.Parent = this;
                LeftOfEqualSignNode = (Expression)newNode;
                return true;
            }
            if (Object.ReferenceEquals(RightOfEqualSignNode, oldNode))
            {
                newNode.Parent = this;
                RightOfEqualSignNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorAssignment(this);
        }
    }


    // 10 + 10   or   2 * 2
    public class Binary : Expression
    {
        public Expression LeftNode;
        public Token Operator;
        public Expression RightNode;

        public Binary(Expression left, Token @operator, Expression right)
        {
            LeftNode = left;
            Operator = @operator;
            RightNode = right;
        }

        public Datatype DetermineConversionDatatype()
        {
            Datatype result = Datatype.Default;
            if (HasNodeWithDatatype([LeftNode, RightNode], Datatype.TypeEnum.String))
                result = Datatype.GetDatatype("string");
            else if (HasNodeWithDatatype([LeftNode, RightNode], Datatype.TypeEnum.FloatingPoint))
                result = Datatype.GetDatatype(GetNodeWithDatatype([LeftNode, RightNode], Datatype.TypeEnum.FloatingPoint)!.ExprType.Name);
            else if (HasNodeWithDatatype([LeftNode, RightNode], Datatype.TypeEnum.Pointer))
                result = Datatype.GetDatatype(GetNodeWithDatatype([LeftNode, RightNode], Datatype.TypeEnum.Pointer)!.ExprType.Name);
            return result;
        }

        public Datatype DetermineResultDatatype()
        {
            Datatype result = DetermineConversionDatatype();
            if (Operator.Contains(TokenType.BooleanResultOperator))
                result = Datatype.GetDatatype("bool");
            return result;
        }

        public override void Initialize()
        {
            // In de Left en Right expressions kan van alles zitten, maar ook Expression.Variabele
            var leftVar = LeftNode as Variable;
            var rightVar = RightNode as Variable;

            if (leftVar != null)
            {
                var scope = GetScope();
                leftVar.ExprType = scope?.GetVariableDataType(leftVar.Name.Lexeme) ?? Datatype.Default;
            }
            if (rightVar != null)
            {
                var scope = GetScope();
                rightVar.ExprType = scope?.GetVariableDataType(rightVar.Name.Lexeme) ?? Datatype.Default;
            }

            this.ExprType = DetermineResultDatatype();

            LeftNode.Parent = this;
            LeftNode.Initialize();

            RightNode.Parent = this;
            RightNode.Initialize();

            /* After initialisation of the Left and Right a change in the underlying ExprType could be done. Bring it back up the tree. */
            this.ExprType = DetermineResultDatatype();
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (LeftNode != null)
                    yield return LeftNode;

                if (RightNode != null)
                    yield return RightNode;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(LeftNode, oldNode))
            {
                newNode.Parent = this;
                LeftNode = (Expression)newNode;
                return true;
            }
            if (Object.ReferenceEquals(RightNode, oldNode))
            {
                newNode.Parent = this;
                RightNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        public bool BothSidesLiteral()
        {
            return ((LeftNode is Literal) && (RightNode is Literal));
        }

        public bool BothSideSameType()
        {
            Datatype leftDatatype = LeftNode.ExprType;
            Datatype rightDatatype = RightNode.ExprType;

            if (leftDatatype.Contains(Datatype.TypeEnum.Integer) && rightDatatype.Contains(Datatype.TypeEnum.Integer))
                return true;

            if ((leftDatatype.Name == "string") && (rightDatatype.Name == "string"))
                return false;   // not supported yet

            return false;
        }

        public bool BothSidesOfTypeEnum(Datatype.TypeEnum theTypeEnum)
        {
            Datatype leftDatatype = LeftNode.ExprType;
            Datatype rightDatatype = RightNode.ExprType;
            return leftDatatype.Contains(theTypeEnum) && rightDatatype.Contains(theTypeEnum);
        }

        public bool CanBothSidesBeCombined()
        {
            return (BothSidesLiteral() && BothSideSameType() &&
                (Operator.Contains(TokenType.Plus) || Operator.Contains(TokenType.Minus) || Operator.Contains(TokenType.Asterisk) || Operator.Contains(TokenType.Slash)));
        }

        public Literal CombineBothSideSameTypeLiterals()
        {
            Datatype leftDatatype = LeftNode.ExprType;
            Datatype rightDatatype = RightNode.ExprType;
            var leftLiteral = LeftNode as Literal;
            var rightLiteral = RightNode as Literal;

            if (leftDatatype.Contains(Datatype.TypeEnum.Integer) && rightDatatype.Contains(Datatype.TypeEnum.Integer))
            {
                var valueLeft = Convert.ToInt64(leftLiteral!.Value);
                var valueRight = Convert.ToInt64(rightLiteral!.Value);

                if (Operator.Contains(TokenType.Plus))
                    return new Literal(leftLiteral.ExprType, valueLeft + valueRight);

                if (Operator.Contains(TokenType.Minus))
                    return new Literal(leftLiteral.ExprType, valueLeft - valueRight);

                if (Operator.Contains(TokenType.Asterisk))
                    return new Literal(leftLiteral.ExprType, valueLeft * valueRight);

                if (Operator.Contains(TokenType.Slash))
                    return new Literal(leftLiteral.ExprType, valueLeft / valueRight);
            }

            return new Literal("string", leftLiteral!.Value.ToString() + rightLiteral!.Value.ToString());
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorBinary(this);
        }
    }


    // test(10);   this.test();    array[2].method(1);
    public class FunctionCall : Expression
    {
        public Expression FunctionNameNode;
        public List<Expression> ArgumentNodes;

        public FunctionCall(Expression functionName, List<Expression> arguments)
        {
            FunctionNameNode = functionName;
            ArgumentNodes = arguments;
        }

        public override void Initialize()
        {
            string functionName = "";

            foreach (var arg in ArgumentNodes)
            {
                arg.Parent = this;
                arg.Initialize();
            }

            // normally, the scope of the functioncall is used.
            var scope = GetScope();
            if (FunctionNameNode is Variable functionNameVariable)
                functionName = functionNameVariable.Name.Lexeme;

            // When we have an methodcall, we use the scope from the class
            if (FunctionNameNode is PropertyExpression functionNameGet)
            {
                Expression propGetObjectNode = functionNameGet.ObjectNode;

                functionNameGet.Parent = this;
                functionNameGet.Initialize();
                functionName = functionNameGet.Name.Lexeme;

                if (functionNameGet.ObjectNode is Variable functionNameVar)
                {
                    string funcName = functionNameVar.Name.Lexeme;
                    var theSymbol = scope.GetVariableAnywhere(funcName);

                    var theClass = theSymbol.GetClassStatement();
                    if (theClass != null)
                        scope = theClass.GetScope();

                    var theGroupStmt = theSymbol.GetGroupStatement();
                    if (theGroupStmt != null)
                        scope = theGroupStmt.GetScope();
                }

                if (functionNameGet.ObjectNode is ArrayAccess objectNodeArray)
                {
                    ClassStatement? classStatement = (propGetObjectNode.ExprType.Properties.ContainsKey("classStatement")) ? propGetObjectNode.ExprType.Properties["classStatement"] as ClassStatement : null;
                    if (classStatement != null)
                        scope = classStatement.GetScope();
                }
            }

            var symbol = GetSymbol(functionName, scope!);

            if (symbol is ClassSymbol classConstructorFunction)
            {
                var dt = Datatype.GetDatatype(classConstructorFunction.Name);
                this.ExprType = dt;
            }

            if (symbol is HardcodedFunctionSymbol hardCodedFunction)
            {
                if (hardCodedFunction.FunctionStmt.ResultDatatype != null)
                    ExprType = hardCodedFunction.FunctionStmt.ResultDatatype!;
            }

            if (symbol is DllFunctionSymbol dllFunction)
            {
                if (dllFunction.FunctionStmt.ResultDatatype != null)
                    ExprType = dllFunction.FunctionStmt.ResultDatatype!;
            }
            if (symbol is FunctionSymbol theFunction)
            {
                if (theFunction.FunctionStmt.ResultDatatype != null)
                    ExprType = theFunction.FunctionStmt.ResultDatatype!;
            }

            foreach (var arg in ArgumentNodes)
            {
                if (arg is PropertyExpression exprGet)
                {
                    var currentScope = exprGet.GetScope();
                    var objectNodeVar = exprGet.ObjectNode as Variable;
                    var objectNodeArray = exprGet.ObjectNode as ArrayAccess;

                    if (objectNodeVar != null)
                    {
                        var variableSymbol = currentScope!.GetVariable(objectNodeVar!.Name.Lexeme);

                        if (objectNodeVar!.Name.Lexeme == "g")
                            arg.ExprType = Datatype.Default;
                        else if (variableSymbol is GroupSymbol groupSymbol)
                        {
                            var groupScope = groupSymbol.GroupStatement.GetScope();
                            var groupVar = groupScope.GetVariable(exprGet.Name.Lexeme);
                            arg.ExprType = groupVar.GetDatatype();
                        }
                        else
                        {
                            var classStatement = objectNodeVar!.ExprType.Properties["classStatement"] as ClassStatement;
                            var instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == exprGet.Name.Lexeme);
                            arg.ExprType = instVar.ResultType;
                        }
                    }
                    if (objectNodeArray != null)
                    {
                        var classStatement = exprGet.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                        var instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == exprGet.Name.Lexeme);
                        arg.ExprType = instVar.ResultType;
                    }
                }
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < ArgumentNodes.Count; i++)
            {
                AstNode node = ArgumentNodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    ArgumentNodes[i] = (Expression)newNode;
                    return true;
                }
            }
            if (Object.ReferenceEquals(FunctionNameNode, oldNode))
            {
                newNode.Parent = this;
                FunctionNameNode = (Expression)newNode;
                return true;
            }
            return false;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                foreach (AstNode node in ArgumentNodes)
                    yield return node;

                if (FunctionNameNode != null)
                    yield return FunctionNameNode;
            }
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorFunctionCall(this);
        }
    }


    // (1+2)
    public class Grouping : Expression
    {
        public Expression expression;

        public Grouping(Expression expression)
        {
            this.expression = expression;
        }

        public override void Initialize()
        {
            if (expression != null)
            {
                expression.Parent = this;
                expression.Initialize();
                this.ExprType = expression.ExprType;
            }
        }

        public override bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            if (Object.ReferenceEquals(expression, oldNode))
            {
                newNode.Parent = this;
                expression = (Expression)newNode;
                return true;
            }
            return false;
        }

        public override IEnumerable<AstNode> Nodes
        {
            get
            {
                if (expression != null)
                    yield return expression;
            }
        }

        [DebuggerStepThrough]
        public override R Accept<R>(IVisitor<R> visitor)
        {
            return visitor.VisitorGrouping(this);
        }
    }


}
