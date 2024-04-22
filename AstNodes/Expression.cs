using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Xml.Linq;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Scope;

namespace GroundCompiler.AstNodes
{
    public abstract class Expression : AstNode
    {
        public Datatype ExprType = Datatype.Default;

        public abstract T Accept<T>(IVisitor<T> visitor);

        public interface IVisitor<T>
        {
            T VisitorGetExpr(Get expr);
            T VisitorSetExpr(Set expr);
            T VisitorAssignmentExpr(Assignment expr);
            T VisitorBinaryExpr(Binary expr);
            T VisitorFunctionCallExpr(FunctionCall expr);
            T VisitorGroupingExpr(Grouping expr);
            T VisitorLiteralExpr(Literal expr);
            T VisitorLogicalExpr(Logical expr);
            T VisitorUnaryExpr(Unary expr);
            T VisitorVariableExpr(Variable expr);
            T VisitorListExpr(List expr);
            T VisitorArrayAccessExpr(ArrayAccess expr);
        }


        // Get a property
        public class Get : Expression
        {
            public Get(Expression @object, Token name)
            {
                Object = @object;
                Name = name;
            }

            public override void Initialize()
            {
                if (Object != null) {
                    Object.Parent = this;
                    Object.Initialize();
                }
                base.Initialize();

                var currentScope = GetScope();
                var objVariableExpr = Object as Expression.Variable;
                ClassStatement? classStatement = null;
                if (objVariableExpr!.ExprType.isClass())
                {
                    classStatement = objVariableExpr!.ExprType.Properties["classStatement"] as ClassStatement;
                    var classScope = classStatement!.GetScope();
                    var theVar = classScope!.GetVariable(Name.Lexeme);

                    // method
                    if (theVar is Scope.Symbol.FunctionSymbol funcSymbol)
                    {
                        var resultDatatype = funcSymbol.FunctionStmt.ResultDatatype;
                        if (resultDatatype != null)
                            ExprType = resultDatatype;
                    }
                    else if (theVar is Scope.Symbol.LocalVariableSymbol localVariableSymbol)
                    {
                        var resultDatatype = localVariableSymbol.DataType;
                        if ( resultDatatype != null)
                            ExprType = resultDatatype;
                    }
                    else
                    {
                        var instVarList = classStatement.InstanceVariables.Find((instVariable) => instVariable.Name.Lexeme == Name.Lexeme);
                        if (instVarList != null) {
                            ExprType = instVarList.ResultType;
                        }
                    }
                }
            }

            public Expression Object;
            public Token Name;

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorGetExpr(this);
            }
        }


        // Set a property
        public class Set : Expression
        {
            public Expression Object;
            public Token Name;
            public List<Expression>? Accessor;
            public Expression Value;
            public Token AssignmentOp;

            public Set(Expression @object, Token name, Expression value, Token assignmentOp)
            {
                Object = @object;
                Name = name;
                Value = value;
                AssignmentOp = assignmentOp;
                Accessor = null;
            }

            public Set(Expression obj, Token name, List<Expression> accessor, Expression value, Token assignmentOp) : this(obj, name, value, assignmentOp)
            {
                Accessor = accessor;
            }

            public override void Initialize()
            {
                if (Object != null) { Object.Parent = this; Object.Initialize(); }
                if (Value != null) { Value.Parent = this; Value.Initialize(); }
                if (Accessor != null)
                {
                    foreach (var element in Accessor)
                    {
                        element.Parent = this;
                        element.Initialize();
                    }
                }
                base.Initialize();
            }

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorSetExpr(this);
            }
        }


        public class Literal : Expression
        {
            public Literal(object? value)
            {
                Value = value;
            }
            public Literal(string theType, object value) : this(value)
            {
                ExprType = Datatype.GetDatatype(theType);
            }

            public Literal(Datatype theType, object value) : this(value)
            {
                ExprType = theType;
            }

            public object? Value;

            public override void Initialize()
            {
                if (ExprType.Name == "string")
                    GetScope()!.DefineString((string)Value!);

                if (ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                    GetScope()!.DefineFloatingpoint((double)Value!);
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
                    Compiler.Error("Literal: ConvertToByteValue error");
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
                        Compiler.Error(oe.Message);
                    }
                    return byteVal;
                }

                return null;
            }

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorLiteralExpr(this);
            }
        }


        public class Logical : Expression
        {
            public Logical(Expression left, Token @operator, Expression right)
            {
                Left = left;
                Operator = @operator;
                Right = right;
            }

            public override void Initialize()
            {
                if (Left != null) { Left.Parent = this; Left.Initialize(); }
                if (Right != null) { Right.Parent = this; Right.Initialize(); }
                base.Initialize();
            }

            public Expression Left;
            public Token Operator;
            public Expression Right;

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorLogicalExpr(this);
            }
        }


        public class Unary : Expression
        {
            public Unary(Token @operator, Expression right, bool postfix = false)
            {
                Operator = @operator;
                Right = right;
                Postfix = postfix;
            }

            public Token Operator;
            public Expression Right;
            public bool Postfix;

            public override void Initialize()
            {
                if (Right != null) { Right.Parent = this; Right.Initialize(); }
                base.Initialize();
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorUnaryExpr(this);
            }
        }


        public Symbol? GetSymbol(string name, Scope scope)
        {
            var symbol = scope.GetVariable(name);
            if (symbol == null)
            {
                symbol = scope.GetVariableAnywhere(name);
                if (symbol == null)
                    Compiler.Error($"Symbol {name} does not exist.");

                if (symbol is Scope.Symbol.HardcodedVariable || symbol is Scope.Symbol.HardcodedFunctionSymbol || symbol is Symbol.FunctionSymbol)
                    return symbol;

                // At this point, the symbol is available but it is in a parent scope, so a ParentScopeVariable must be inserted in the symboltable.
                Symbol.LocalVariableSymbol? variableSymbol = symbol as Symbol.LocalVariableSymbol;
                int levelsDeep = 0;
                var needleScope = scope;
                IScopeStatement? ownerScope = null;
                while (!needleScope.Contains(name))
                {
                    needleScope = needleScope.Parent;
                    if (needleScope == null)
                        break;

                    ownerScope = needleScope.Owner;
                    levelsDeep++;
                }
                if (ownerScope == null)
                    Compiler.Error("Expression>>GetSymbol error.");

                return scope.DefineParentScopeParameter(name, variableSymbol!.DataType, levelsDeep, ownerScope!);
            }

            return symbol;
        }


        // Identifier
        public class Variable : Expression
        {
            public Variable(Token name)
            {
                Name = name;
            }

            public Token Name;

            public override void Initialize()
            {
                var scope = GetScope();

                if (Name.Lexeme == "this")
                {
                    var classStmt = this.FindParentType(typeof(ClassStatement)) as ClassStatement;
                    if (classStmt != null)
                        ExprType = Datatype.GetDatatype(classStmt.Name.Lexeme);
                }
                else
                {
                    var symbol = GetSymbol(Name.Lexeme, scope!);
                    if (symbol is Scope.Symbol.ParentScopeVariable)
                        ExprType = (symbol as Scope.Symbol.ParentScopeVariable)!.DataType;
                    else if (symbol is Scope.Symbol.LocalVariableSymbol)
                        ExprType = (symbol as Scope.Symbol.LocalVariableSymbol)!.DataType;
                    else if (symbol is Scope.Symbol.FunctionParameterSymbol)
                        ExprType = (symbol as Scope.Symbol.FunctionParameterSymbol)!.DataType;
                    else if (symbol is Scope.Symbol.HardcodedVariable)
                        ExprType = (symbol as Scope.Symbol.HardcodedVariable)!.DataType;
                    else
                        ExprType = Datatype.Default;
                }
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorVariableExpr(this);
            }
        }


        // [ 1, 2, 4 ]
        public class List : Expression
        {
            public readonly List<Expression> Elements;

            public List(List<Expression> elements)
            {
                Elements = elements;
            }

            public override void Initialize()
            {
                string? elementType = null;
                if (Elements != null) { 
                    foreach (var element in Elements)
                    {
                        element.Parent = this;
                        element.Initialize();
                        if (elementType == null)
                            elementType = element.ExprType.Name;
                        else if (element.ExprType.Name != elementType)
                            Compiler.Error("All elements in a List must have the same type");
                    }
                }
                base.Initialize();
                if (elementType != null)
                    this.ExprType = Datatype.GetDatatype($"{elementType}[]");
            }

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorListExpr(this);
            }
        }


        // tmp[2]
        public class ArrayAccess : Expression
        {
            public Expression Member;
            public List<Expression> Accessor;
            public Token Index;

            public ArrayAccess(Expression member, List<Expression> accessor, Token index)
            {
                Member = member;
                Accessor = accessor;
                Index = index;
            }

            public override void Initialize()
            {
                if (Member != null) { Member.Parent = this; Member.Initialize(); }
                if (Accessor != null) {
                    foreach (var expr in Accessor)
                    {
                        expr.Parent = this;
                        expr.Initialize();
                    }
                }
                this.ExprType = Member?.ExprType.Base ?? Datatype.Default;
                base.Initialize();
            }

            public Expression.Variable? GetMemberVariable()
            {
                if (this.Member is Expression.Variable)
                    return (Expression.Variable)this.Member;

                if (this.Member is Expression.ArrayAccess)
                {
                    var memberAccess = (Expression.ArrayAccess)this.Member;
                    return memberAccess.GetMemberVariable();
                }
                return null;
            }

            [DebuggerStepThrough]
            public override T Accept<T>(IVisitor<T> visitor)
            {
                return visitor.VisitorArrayAccessExpr(this);
            }
        }


        // tmp = 10;
        public class Assignment : Expression
        {
            public Assignment(Expression left, Expression right, Token operatorToken)
            {
                LeftOfEqualSign = left;
                RightOfEqualSign = right;
                Operator = operatorToken;  // = or later perhaps += and -=
            }
            public override void Initialize()
            {
                if (LeftOfEqualSign is Expression.Variable variableExpr)
                {
                    // Define pass-through parameters
                    GetSymbol(variableExpr.Name.Lexeme, GetScope()!);
                }

                if (LeftOfEqualSign != null) { LeftOfEqualSign.Parent = this; LeftOfEqualSign.Initialize(); }
                if (RightOfEqualSign != null) { RightOfEqualSign.Parent = this; RightOfEqualSign.Initialize(); }
                base.Initialize();
            }

            public Expression LeftOfEqualSign;
            public Expression RightOfEqualSign;
            public Token Operator;

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorAssignmentExpr(this);
            }
        }


        // tmp = 10 + 10
        public class Binary : Expression
        {
            public Binary(Expression left, Token @operator, Expression right)
            {
                Left = left;
                Operator = @operator;
                Right = right;
            }

            public Expression Left;
            public Token Operator;
            public Expression Right;

            public override void Initialize()
            {
                // In de Left en Right expressions kan van alles zitten, maar ook Expression.Variabele
                var leftVar = Left as Expression.Variable;
                var rightVar = Right as Expression.Variable;

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

                if (Left.ExprType.Name == "string" || Right.ExprType.Name == "string")
                    this.ExprType = Datatype.GetDatatype("string");
                else if (Left.ExprType.Contains(Datatype.TypeEnum.FloatingPoint) || Right.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                    this.ExprType = Datatype.GetDatatype("float");

                Left.Parent = this;
                Left.Initialize();

                Right.Parent = this;
                Right.Initialize();

                /* After initialisation of the Left and Right a change in the underlying ExprType could be done. Bring it back up the tree. */
                if (Left.ExprType.Name == "string" || Right.ExprType.Name == "string")
                    this.ExprType = Datatype.GetDatatype("string");
                else if (Left.ExprType.Contains(Datatype.TypeEnum.FloatingPoint) || Right.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                    this.ExprType = Datatype.GetDatatype("float");
            }

            public override IEnumerable<AstNode> AllNodes()
            {
                yield return this;
                foreach (var node in Left.AllNodes())
                    yield return node;

                foreach (var node in Right.AllNodes())
                    yield return node;
            }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                foreach (AstNode child in Left.FindAllNodes(typeToFind))
                    yield return child;

                foreach (AstNode child in Right.FindAllNodes(typeToFind))
                    yield return child;
            }

            public override bool ReplaceInternalAstNode(AstNode oldNode, AstNode newNode)
            {
                if (Object.ReferenceEquals(Left, oldNode))
                {
                    newNode.Parent = this;
                    Left = (Expression)newNode;
                    return true;
                }
                if (Object.ReferenceEquals(Right, oldNode))
                {
                    newNode.Parent = this;
                    Right = (Expression)newNode;
                    return true;
                }
                return false;
            }

            public bool BothSidesLiteral()
            {
                return ((Left is Literal) && (Right is Literal));
            }

            public bool BothSideSameType()
            {
                Datatype leftDatatype = Left.ExprType;
                Datatype rightDatatype = Right.ExprType;

                if (leftDatatype.Contains(Datatype.TypeEnum.Integer) && rightDatatype.Contains(Datatype.TypeEnum.Integer))
                    return true;

                if ((leftDatatype.Name == "string") && (rightDatatype.Name == "string"))
                    return false;   // not supported yet

                return false;
            }

            public bool CanBothSidesBeCombined()
            {
                return (BothSidesLiteral() && BothSideSameType() && 
                    ( Operator.Contains(TokenType.Plus) || Operator.Contains(TokenType.Minus) || Operator.Contains(TokenType.Asterisk) || Operator.Contains(TokenType.Slash) ));
            }

            public Expression.Literal CombineBothSideSameTypeLiterals()
            {
                Datatype leftDatatype = Left.ExprType;
                Datatype rightDatatype = Right.ExprType;
                var leftLiteral = Left as Expression.Literal;
                var rightLiteral = Right as Expression.Literal;

                if (leftDatatype.Contains(Datatype.TypeEnum.Integer) && rightDatatype.Contains(Datatype.TypeEnum.Integer))
                {
                    var valueLeft = (long)leftLiteral!.Value;
                    var valueRight = (long)rightLiteral!.Value;

                    if (Operator.Contains(TokenType.Plus))
                        return new Expression.Literal(leftLiteral.ExprType, valueLeft + valueRight);

                    if (Operator.Contains(TokenType.Minus))
                        return new Expression.Literal(leftLiteral.ExprType, valueLeft - valueRight);

                    if (Operator.Contains(TokenType.Asterisk))
                        return new Expression.Literal(leftLiteral.ExprType, valueLeft * valueRight);

                    if (Operator.Contains(TokenType.Slash))
                        return new Expression.Literal(leftLiteral.ExprType, valueLeft / valueRight);
                }

                return new Expression.Literal("string", leftLiteral!.Value.ToString() + rightLiteral!.Value.ToString());
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorBinaryExpr(this);
            }
        }


        // func(10);
        public class FunctionCall : Expression
        {
            public Expression FunctionName;
            public List<Expression> Arguments;

            public FunctionCall(Expression functionName, List<Expression> arguments)
            {
                FunctionName = functionName;
                Arguments = arguments;
            }

            public override void Initialize()
            {
                string functionName = "";

                //We don't initialize Callee, because it is simply a Name of the function packed in a Variable Expression
                foreach (var arg in Arguments)
                {
                    arg.Parent = this;
                    arg.Initialize();
                }

                // normally, the scope of the functioncall is used.
                var scope = GetScope();
                if (FunctionName is Expression.Variable functionNameVariable)
                    functionName = functionNameVariable.Name.Lexeme;

                // When we have an methodcall, we use the scope from the class
                if (FunctionName is Expression.Get functionNameGet)
                {

                    if (functionNameGet.Object is Expression.Variable functionNameVar)
                    {
                        string funcName = functionNameVar.Name.Lexeme;
                        var theSymbol = scope.GetVariable(funcName);

                        var theClass = theSymbol.GetClassStatement();
                        if (theClass != null)
                            scope = theClass.GetScope();

                        var theGroupStmt = theSymbol.GetGroupStatement();
                        if (theGroupStmt != null)
                            scope = theGroupStmt.GetScope();
                    }

                    functionNameGet.Parent = this;
                    functionNameGet.Initialize();
                    functionName = functionNameGet.Name.Lexeme;
                }

                base.Initialize();

                var symbol = GetSymbol(functionName, scope!);

                if (symbol is Scope.Symbol.HardcodedFunctionSymbol hardCodedFunction) { 
                    if (hardCodedFunction.FunctionStmt.ResultDatatype != null)
                        ExprType = hardCodedFunction.FunctionStmt.ResultDatatype!;
                }

                foreach (var arg in Arguments)
                {
                    if (arg is Expression.Get exprGet)
                    {
                        var currentScope = exprGet.GetScope();
                        var variableExpr = exprGet.Object as Expression.Variable;
                        var variableSymbol = currentScope!.GetVariable(variableExpr!.Name.Lexeme);

                        if (variableExpr!.Name.Lexeme == "g")
                            arg.ExprType = Datatype.Default;
                        else if (variableSymbol is Symbol.GroupSymbol groupSymbol)
                        {
                            var groupScope = groupSymbol.GroupStatement.GetScope();
                            var groupVar = groupScope.GetVariable(exprGet.Name.Lexeme);
                            arg.ExprType = groupVar.GetDatatype();
                        }
                        else
                        {
                            var classStatement = variableExpr!.ExprType.Properties["classStatement"] as ClassStatement;
                            var instVar = classStatement!.InstanceVariables.First((instVariable) => instVariable.Name.Lexeme == exprGet.Name.Lexeme);
                            arg.ExprType = instVar.ResultType;
                        }
                    }
                }
            }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                foreach (var arg in Arguments)
                {
                    foreach (AstNode child in arg.FindAllNodes(typeToFind))
                        yield return child;
                }
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorFunctionCallExpr(this);
            }
        }


        // (1+2)
        public class Grouping : Expression
        {
            public Grouping(Expression expression)
            {
                Expression = expression;
            }

            public Expression Expression;

            public override void Initialize()
            {
                if (Expression != null)
                {
                    Expression.Parent = this;
                    Expression.Initialize();
                    this.ExprType = Expression.ExprType;
                }
            }

            public override IEnumerable<AstNode> AllNodes()
            {
                yield return this;
                yield return Expression;
            }

            public override IEnumerable<AstNode> FindAllNodes(Type typeToFind)
            {
                if (this.GetType() == typeToFind)
                    yield return this;

                foreach (AstNode child in Expression.FindAllNodes(typeToFind))
                    yield return child;
            }

            public override bool ReplaceInternalAstNode(AstNode oldNode, AstNode newNode)
            {
                if (Object.ReferenceEquals(Expression, oldNode))
                {
                    newNode.Parent = this;
                    Expression = (Expression)newNode;
                    return true;
                }
                return false;
            }

            [DebuggerStepThrough]
            public override R Accept<R>(IVisitor<R> visitor)
            {
                return visitor.VisitorGroupingExpr(this);
            }
        }


    }
}
