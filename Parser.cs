using GroundCompiler.Statements;
using GroundCompiler.Expressions;


namespace GroundCompiler
{
    public class Parser
    {
        private TokenDispenser tokenDispenser;
        public Parser(IEnumerable<Token> tokens)
        {
            tokenDispenser = new TokenDispenser(tokens);
        }

        public Token Peek() { return tokenDispenser.PeekNextToken(); }
        public Token PeekPlus2() { return tokenDispenser.PeekNextToken2(); }
        public Token NextToken() { return tokenDispenser.GetNextToken(); }
        public bool IsAtEnd() { return Peek().Type == TokenType.EndOfFile; }

        private bool Check(params TokenType[] types)
        {
            if (IsAtEnd()) return false;
            Token peekToken = Peek();
            foreach (var type in types)
                if (peekToken.Contains(type))
                    return true;

            return false;
        }

        private bool Check(params Datatype.TypeEnum[] types)
        {
            if (IsAtEnd()) return false;
            Token peekToken = Peek();
            if (peekToken.Datatype == null)
                return false;

            foreach (var type in types)
                if (peekToken.Datatype.Contains(type))
                    return true;

            return false;
        }

        // the token after the current peek is checked.
        private bool CheckPlus2(params TokenType[] types)
        {
            if (IsAtEnd()) return false;
            Token peekToken = PeekPlus2();
            foreach (var type in types)
            {
                if (peekToken.Contains(type))
                    return true;
            }
            return false;
        }

        private bool Match(params TokenType[] types)
        {
            bool check = Check(types);
            if (check) { tokenDispenser.GetNextToken(); }
            return check;
        }

        private bool Match(params Datatype.TypeEnum[] types)
        {
            bool check = Check(types);
            if (check) { tokenDispenser.GetNextToken(); }
            return check;
        }

        //[DebuggerStepThrough]
        private Token Consume(TokenType type, String message = "Consume error.")
        {
            if (Check(type)) { return tokenDispenser.GetNextToken(); }
            Error(Peek(), message);
            return null!;
        }

        public static void Error(Token token, String message)
        {
            Compiler.Error(message, token);
        }

        public ProgramNode GetAbstractSyntaxTree()
        {
            ProgramNode programNode = new();
            while (!IsAtEnd())
                programNode.BodyNode?.AddNode(ParseStatement());

            /* At this point, the AST is an empty shell. It just exists. That can be handy in some situations. */
            return programNode;
        }

        public Datatype ConsumeDatatype(string failMessagePrefix)
        {
            var theType = Consume(TokenType.Type, failMessagePrefix + ": Expected type.");
            string datatypeStr = theType.Lexeme;
            List<UInt64>? arrayNrs = null;

            if (Match(TokenType.LeftSquareBracket))
            {
                arrayNrs = new List<UInt64>();
                do
                {
                    if (Check(Datatype.TypeEnum.Number))
                    {
                        Token numberToken = NextToken();
                        UInt64 sizeIndicator = Convert.ToUInt64(numberToken.Value);
                        arrayNrs.Add(sizeIndicator);

                        if (Check(TokenType.Asterisk) && CheckPlus2(TokenType.Literal))
                        {
                            Match(TokenType.Asterisk);
                            Token numberMultiplierToken = NextToken();
                            arrayNrs[arrayNrs.Count - 1] = arrayNrs[arrayNrs.Count - 1] * Convert.ToUInt64(numberMultiplierToken.Value);
                        }
                    }
                } while (Match(TokenType.Comma));
                if (!Match(TokenType.RightSquareBracket))
                    Compiler.Error("Unknown token at array: " + Peek().Lexeme);

                datatypeStr += "[]";
            }
            if (Match(TokenType.Asterisk))
                datatypeStr += "*";

            Datatype datatype = Datatype.GetDatatype(datatypeStr, arrayNrs);
            return datatype;
        }

        private VarStatement VariableDeclaration()
        {
            Datatype datatype = ConsumeDatatype("VarDeclaration");
            var name = Consume(TokenType.Identifier, "VarDeclaration: Expected variable name.");

            Expression? initializer = null;
            if (Match(TokenType.Assign))
                initializer = ParseExpression();

            if (Match(TokenType.Assembly))
                if (initializer is Expressions.List listItem)
                    listItem.Properties["fixed"] = true;

            Consume(TokenType.SemiColon, "VarDeclaration: Expected ';' after variable declaration.");
            return new VarStatement(datatype, name, initializer);
        }

        private Statement PokeStatement()
        {
            Consume(TokenType.Dot, "PokeStatement: Expected '.' to get the location size.");
            Token sizeToken = NextToken();
            Datatype sizeType = Datatype.GetDatatype("u64");
            switch (sizeToken.Lexeme)
            {
                case "b":
                    sizeType = Datatype.GetDatatype("u8");
                    break;
                case "w":
                    sizeType = Datatype.GetDatatype("u16");
                    break;
                case "d":
                    sizeType = Datatype.GetDatatype("u32");
                    break;
                case "q":
                    // sizeType is already set correctly
                    break;
                default:
                    Compiler.Error("PokeStatement: Size not recognized.");
                    break;
            }
            Token nameToken = NextToken();
            Consume(TokenType.Comma, "PokeStatement: Expected comma.");
            Expression? valueExpr = ParseExpression();
            Consume(TokenType.SemiColon, "PokeStatement: Expected ';' after value.");
            return new PokeStatement(sizeType, nameToken.Lexeme, valueExpr);
        }

        private Statement ReturnStatement()
        {
            Expression? valueExpr = null;
            if (!Check(TokenType.SemiColon))
                valueExpr = ParseExpression();

            Consume(TokenType.SemiColon, "ReturnStatement: Expected ';' after return value.");
            return new ReturnStatement(valueExpr);
        }

        private Statement AssemblyStatement()
        {
            var asmCode = NextToken();      // this token is a special at this moment: it contains all the assembly code as a string.
            return new AssemblyStatement(asmCode);
        }

        private Statement IfStatement()
        {
            Token? notToken = Check(TokenType.Not) ? NextToken() : null;
            Consume(TokenType.OpenBracket, "IfStatement: Expected '(' after 'if'.");
            var condition = ParseExpression();
            if (notToken != null)
                condition = new Unary(notToken, condition);

            Consume(TokenType.CloseBracket, "IfStatement: Expected ')' after if condition.");

            var thenBranch = ParseStatement();

            Statement? elseBranch = null;
            if (Match(TokenType.Else))
                elseBranch = ParseStatement();

            return new IfStatement(condition, thenBranch, elseBranch);
        }


        public static void RemoveVerboseGrouping(Expression expr)
        {
            var list = expr.FindAllNodes(typeof(Grouping)).ToList();
            if (expr is Grouping)
                list.Add(expr);

            foreach (Grouping groupingExpr in list)
                if (groupingExpr.expression is Literal theLiteral)
                    groupingExpr?.Parent?.ReplaceNode(groupingExpr, theLiteral.DeepCopy());
        }


        public static Literal? LiteralifyExpression(Expression expr)
        {
            var theGroup = new Grouping(expr);
            theGroup.UpdateParentRecursive();
            while (SimplifyExpression(theGroup));
            Literal theLiteral = theGroup.expression as Literal;
            return theLiteral;
        }


        public static bool SimplifyExpression(Expression? expr)
        {
            if (expr == null)
                return false;

            expr.UpdateParentInNodes();

            bool onceTrue = false;
            foreach (Binary binaryExpr in expr.FindAllNodes(typeof(Binary)).ToList())
            {
                if (binaryExpr.CanBothSidesBeCombined())
                {
                    var combinedLiteral = binaryExpr.CombineBothSideSameTypeLiterals();
                    bool updated = binaryExpr?.Parent?.ReplaceNode(binaryExpr, combinedLiteral) ?? false;
                    if (updated)
                        onceTrue = true;
                }
            }
            if (onceTrue)
                RemoveVerboseGrouping(expr);

            return onceTrue;
        }


        private Statement ForStatement()
        {
            Consume(TokenType.OpenBracket, "ForStatement: Expected '(' after 'for'.");

            Statement? initializer = null;
            if (Match(TokenType.SemiColon))
                initializer = null;
            else if (Check(TokenType.Type))
                initializer = VariableDeclaration();
            else if (Check(TokenType.Identifier) && CheckPlus2(TokenType.In))
            {
                // for (i in 1..10) { println(i); }
                // The Kotlin for-loop is used as inspiration.
                var rangeIdentifier = Consume(TokenType.Identifier, "For loop expected a identifier.");
                if (Match(TokenType.In))
                {
                    var rangeDatatype = Datatype.GetDatatype("int");
                    Binary? rangeExpr = ParseExpression() as Binary;

                    Literal? leftLiteral = rangeExpr?.LeftNode as Literal;
                    Literal? rightLiteral = rangeExpr?.RightNode as Literal;

                    // Is it beneath all the Grouping and Binary expressions just a Literal?
                    if (leftLiteral == null && rangeExpr?.LeftNode != null)
                    {
                        leftLiteral = LiteralifyExpression(rangeExpr.LeftNode);
                        if (leftLiteral != null)
                            rangeExpr.LeftNode = leftLiteral;
                    }

                    if (rightLiteral == null && rangeExpr?.RightNode != null)
                    {
                        rightLiteral = LiteralifyExpression(rangeExpr.RightNode);
                        if (rightLiteral != null)
                            rangeExpr.RightNode = rightLiteral;
                    }

                    bool ascending = true;
                    if (leftLiteral != null && rightLiteral != null)
                    {
                        if ((long)(leftLiteral.Value!) > (long)(rightLiteral.Value!))
                            ascending = false;
                    }

                    initializer = new VarStatement(rangeDatatype, rangeIdentifier, rangeExpr.LeftNode);
                    initializer.Properties["for-loop-variable"] = true;

                    Token rangeToOrUntilToken = new Token();
                    if (ascending)
                        rangeToOrUntilToken.Lexeme = rangeExpr.Operator.Lexeme == ".." ? "<=" : "<";
                    else
                        rangeToOrUntilToken.Lexeme = rangeExpr.Operator.Lexeme == ".." ? ">=" : ">";

                    rangeToOrUntilToken.Types = new List<TokenType> { TokenType.Operator, TokenType.BooleanResultOperator };
                    if (ascending)
                    {
                        if (rangeExpr.Operator.Lexeme == "..")
                            rangeToOrUntilToken.Types.Add(TokenType.LessEqual);
                        else
                            rangeToOrUntilToken.Types.Add(TokenType.Less);
                    }
                    else
                    {
                        if (rangeExpr.Operator.Lexeme == "..")
                            rangeToOrUntilToken.Types.Add(TokenType.GreaterEqual);
                        else
                            rangeToOrUntilToken.Types.Add(TokenType.Greater);
                    }

                    var rangeConditionVariable = new Variable(rangeIdentifier);
                    Expression rangeConditionExp = new Binary(rangeConditionVariable, rangeToOrUntilToken, rangeExpr.RightNode);

                    Token incrementToken = new Token();
                    if (ascending)
                    {
                        incrementToken.Lexeme = "++";
                        incrementToken.Types = new List<TokenType> { TokenType.Operator, TokenType.PlusPlus };
                    } else
                    {
                        incrementToken.Lexeme = "--";
                        incrementToken.Types = new List<TokenType> { TokenType.Operator, TokenType.MinusMinus };
                    }
                    Expression rangeIncrementExp = new Unary(incrementToken, rangeConditionVariable, postfix: true);

                    Consume(TokenType.CloseBracket, "ForStatement: Expect ')' after 'for' clauses");

                    var sugarBody = ParseStatement();
                    sugarBody = new WhileStatement(rangeConditionExp, sugarBody, new ExpressionStatement(rangeIncrementExp));
                    sugarBody = new BlockStatement(new List<Statement> { initializer, sugarBody });
                    return sugarBody;
                }
            }
            else
                initializer = ExpressionStatement();

            Expression? condition = null;
            if (!Check(TokenType.SemiColon))
                condition = ParseExpression();

            Consume(TokenType.SemiColon, "ForStatement: Expected ';' after loop condition.");

            Expression? increment = null;
            if (!Check(TokenType.CloseBracket))
                increment = ParseExpression();

            Consume(TokenType.CloseBracket, "ForStatement: Expect ')' after 'for' clauses");

            var body = ParseStatement();

            if (condition == null)
                condition = new Literal(true);

            body = new WhileStatement(condition, body, (increment != null) ? new ExpressionStatement(increment) : null);

            if (initializer != null)
                body = new BlockStatement(new List<Statement> { initializer, body });

            return body;
        }


        private Statement WhileStatement()
        {
            Consume(TokenType.OpenBracket, "Expected '(' after 'while'.");
            var condition = ParseExpression();
            Consume(TokenType.CloseBracket, "Expected ')' after condition.");
            var body = ParseStatement();

            return new WhileStatement(condition, body);
        }


        private Statement BreakStatement()
        {
            var token = NextToken();
            Consume(TokenType.SemiColon, "BreakStatement: Expected ';' after 'break'.");
            return new BreakStatement(token);
        }

        private Statement ContinueStatement()
        {
            var token = NextToken();
            Consume(TokenType.SemiColon, "ContinueStatement: Expected ';' after 'continue'.");
            return new ContinueStatement(token);
        }


        private Statement ExpressionStatement()
        {
            var expr = ParseExpression();
            Consume(TokenType.SemiColon, "Expected ';' after expression.");
            return new ExpressionStatement(expr);
        }

        public Statement ParseStatement()
        {
            if (Match(TokenType.Dll)) return DllDeclaration();
            if (Match(TokenType.Class)) return ClassDeclaration();
            if (Match(TokenType.Group)) return GroupDeclaration();
            if (Match(TokenType.Function)) return FunctionDeclaration("function");
            if (Check(TokenType.Type) || (Check(TokenType.Identifier) && IsCustomClass())) return VariableDeclaration();
            if (Match(TokenType.Poke)) return PokeStatement();
            if (Match(TokenType.Return)) return ReturnStatement();
            if (Check(TokenType.Assembly)) return AssemblyStatement();
            if (Check(TokenType.Break)) return BreakStatement();
            if (Check(TokenType.Continue)) return ContinueStatement();
            if (Match(TokenType.For)) return ForStatement();
            if (Match(TokenType.If)) return IfStatement();
            if (Match(TokenType.While)) return WhileStatement();
            if (Match(TokenType.LeftBrace)) return new BlockStatement(Block());

            return ExpressionStatement();
        }

        public bool IsCustomClass()
        {
            Token peekToken = Peek();
            bool isACustomClass = Datatype.ContainsDatatype(peekToken.Lexeme);
            if (isACustomClass && (!peekToken.Contains(TokenType.Type)))
                peekToken.AddType(TokenType.Type);

            return isACustomClass;
        }


        private List<Statement> Block()
        {
            var statements = new List<Statement>();

            while (!Check(TokenType.RightBrace) && !IsAtEnd())
                statements.Add(ParseStatement());

            Consume(TokenType.RightBrace, "Expected '}' after block.");
            return statements;
        }


        private Expression ParseExpression()
        {
            return Assignment();
        }

        private Expression Assignment()
        {
            var expr = Or();
            if (Check(TokenType.Assign))
            {
                var equals = NextToken();
                var rightValue = Assignment();

                if (expr is PropertyExpression getExpr)
                    return new PropertySet(getExpr.ObjectNode, getExpr.Name, equals, rightValue);

                return new Assignment(expr, rightValue, equals);
            }
            return expr;
        }

        private Expression Or() => ParseLeftAssociativeBinaryOperation(Range, TokenType.LogicalOr);
        private Expression Range() => ParseLeftAssociativeBinaryOperation(And, TokenType.RangeTo, TokenType.RangeUntil);
        private Expression And() => ParseLeftAssociativeBinaryOperation(Equality, TokenType.LogicalAnd);
        private Expression Equality() => ParseLeftAssociativeBinaryOperation(Comparison, TokenType.NotIsEqual, TokenType.IsEqual);
        private Expression Comparison() => ParseLeftAssociativeBinaryOperation(Shifting, TokenType.Greater, TokenType.GreaterEqual, TokenType.Less, TokenType.LessEqual);
        private Expression Shifting() => ParseLeftAssociativeBinaryOperation(Addition, TokenType.ShiftLeft, TokenType.ShiftRight);
        private Expression Addition() => ParseLeftAssociativeBinaryOperation(BitwiseOr, TokenType.Minus, TokenType.Plus);
        private Expression BitwiseOr() => ParseLeftAssociativeBinaryOperation(BitwiseAnd, TokenType.ArithmeticOr);
        private Expression BitwiseAnd() => ParseLeftAssociativeBinaryOperation(Multiplication, TokenType.Ampersand);
        private Expression Multiplication() => ParseLeftAssociativeBinaryOperation(Unary, TokenType.Slash, TokenType.Asterisk, TokenType.Modulo);

        private Expression ParseLeftAssociativeBinaryOperation(Func<Expression> higherPrecedence, params TokenType[] tokenTypes)
        {
            var expr = higherPrecedence();
            while (Check(tokenTypes))
            {
                var op = NextToken();
                var right = higherPrecedence();
                expr = new Binary(expr, op, right);
            }
            return expr;
        }

        private Expression Unary()
        {
            if (Check(TokenType.Not) || Check(TokenType.Minus) || Check(TokenType.Ampersand) || Check(TokenType.Asterisk))
            {
                var op = NextToken();
                var right = Unary();
                if (op.Contains(TokenType.Minus) && right is Literal literal)
                {
                    Type theType = literal.Value!.GetType();
                    if (literal.ExprType.Contains(Datatype.TypeEnum.Integer))
                        literal.Value = -((long)literal.Value!);
                    else if (literal.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        literal.Value = -((double)literal.Value!);
                    return right;
                }
                return new Unary(op, right);
            }
            return Postfix();
        }

        private Expression Postfix()
        {
            if (CheckPlus2(TokenType.PlusPlus, TokenType.MinusMinus))
            {
                var theValue = Primary();
                var op = NextToken();
                return new Unary(op, theValue, postfix: true);
            }
            var higherThanPostfix = Call();
            if (higherThanPostfix is PropertyExpression propGet)
            {
                if (Check(TokenType.PlusPlus, TokenType.MinusMinus)) {
                    var op = NextToken();
                    higherThanPostfix = new Unary(op, higherThanPostfix, postfix: true);
                }
            }
            return higherThanPostfix;
        }

        private Expression Call()
        {
            var expr = Primary();
            while (true)
            {
                if (Match(TokenType.OpenBracket))
                    expr = FunctionCall(expr);
                else if (Match(TokenType.Dot))
                {
                    if (Check(TokenType.Literal))
                    {
                        Token stringToken = Peek();
                        if (stringToken.Datatype != null && stringToken.Datatype.Contains(Datatype.TypeEnum.String))
                        {
                            stringToken = NextToken();
                            return new PropertyExpression(expr, stringToken);
                        }
                    }
                    if (Check(TokenType.LeftSquareBracket))
                    {
                        Token token = NextToken();
                        token = NextToken();
                        Consume(TokenType.RightSquareBracket, "Expected ]");

                        Token newToken = new Token();
                        newToken.Type = TokenType.Literal;
                        newToken.Datatype = Datatype.GetDatatype("string");
                        string s = $"[{token.Lexeme}]";
                        newToken.Value = s;
                        newToken.Lexeme = $"\"{s}\"";
                        return new PropertyExpression(expr, newToken);
                    }
                    var name = Consume(TokenType.Identifier, "Expected property name after '.'.");
                    expr = new PropertyExpression(expr, name);
                }
                else if (Match(TokenType.QuestionMark))
                {
                    var name = Consume(TokenType.Identifier, "Expected property name after '.'.");
                    expr = new PropertyExpression(expr, name);
                }
                else if (Match(TokenType.LeftSquareBracket))
                    expr = ArrayAccess(expr);
                else
                    break;
            }
            return expr;
        }

        private Expression ArrayAccess(Expression collection)
        {
            var accessorElements = new List<Expression>();
            if (!Check(TokenType.RightSquareBracket))
            {
                do
                {
                    if (Check(TokenType.RightSquareBracket))
                        break;
                    accessorElements.Add( Or() );
                } while (Match(TokenType.Comma));
            }

            Consume(TokenType.RightSquareBracket, "Expect ']' after accessing a collection.");
            return new ArrayAccess(collection, accessorElements);
        }

        private Expression FunctionCall(Expression functionName)
        {
            var arguments = new List<Expression>();
            if (!Check(TokenType.CloseBracket))
            {
                do {
                    arguments.Add(ParseExpression());
                } while (Match(TokenType.Comma));
            }

            Consume(TokenType.CloseBracket, "Expected ')' after arguments.");
            return new FunctionCall(functionName, arguments);
        }

        private Expression Primary()
        {
            if (Check(Datatype.TypeEnum.Boolean))
            {
                Token token = NextToken();
                return new Literal(token.Datatype!, (bool)token.Value!);
            }
            if (Match(TokenType.Null))
                return new Literal(null);

            if (Check(Datatype.TypeEnum.Number, Datatype.TypeEnum.String))
            {
                Token token = NextToken();
                return new Literal(token.Datatype!, token.Value!);
            }

            if (Check(TokenType.This))
                return new ThisExpression(NextToken());

            if (Check(TokenType.Identifier))
                return new Variable(NextToken());

            if (Match(TokenType.OpenBracket))
            {
                var expr = ParseExpression();
                Consume(TokenType.CloseBracket, "Expected ')' after expression.");
                return new Grouping(expr);
            }

            if (Match(TokenType.LeftSquareBracket))
                return ParseList();

            Error(Peek(), "Primary: Expected expression.");
            return null!;
        }


        private DllStatement DllDeclaration()
        {
            var groupname = Consume(TokenType.Identifier, "Expect groupname.");
            Consume(TokenType.Function, "Expect function keyword.");
            var functionStatement = FunctionDeclaration("function");

            var result = new DllStatement(groupname.Lexeme, functionStatement);
            return result;
        }


        private ClassStatement ClassDeclaration()
        {
            var name = Consume(TokenType.Identifier, "Expect class name before body.");
            bool isPacked = false;

            if (Check(TokenType.Identifier))
            {
                var alignment = Consume(TokenType.Identifier);
                if (alignment.Lexeme.ToLower() == "packed")
                    isPacked = true;
            }

            Consume(TokenType.LeftBrace, "Expect '{' before class body.");
            var methods = new List<FunctionStatement>();
            var instanceVariables = new List<VarStatement>();
            while (!Check(TokenType.RightBrace) && !IsAtEnd())
            {
                if (Match(TokenType.Function))
                    methods.Add(FunctionDeclaration("method"));

                if (Check(TokenType.Type))
                    instanceVariables.Add(VariableDeclaration());
            }
            Consume(TokenType.RightBrace, "Expect '}' after class body.");

            var result = new ClassStatement(name, instanceVariables, methods);
            if (isPacked)
                result.SetPacked();
            Datatype.AddClass(result);
            return result;
        }


        private GroupStatement GroupDeclaration()
        {
            var name = Consume(TokenType.Identifier, "Expect group name before body.");
            Consume(TokenType.LeftBrace, "Expect '{' before group body.");
            var methods = new List<FunctionStatement>();
            while (!Check(TokenType.RightBrace) && !IsAtEnd())
            {
                if (Match(TokenType.Function))
                    methods.Add(FunctionDeclaration("method"));
            }

            Consume(TokenType.RightBrace, "Expect '}' after group body.");
            var result = new GroupStatement(name, methods);
            return result;
        }


        private FunctionStatement FunctionDeclaration(string kind)
        {
            var name = Consume(TokenType.Identifier, $"Expected {kind} name.");
            Consume(TokenType.OpenBracket, $"Expected '(' after {kind} name.");
            var parameters = new List<FunctionParameter>();
            if (!Check(TokenType.CloseBracket))
            {
                do
                {
                    Datatype datatype = Datatype.Default;
                    if (Check(TokenType.Type) || (Check(TokenType.Identifier) && IsCustomClass()))
                        datatype = ConsumeDatatype("FunctionDeclaration parameter");

                    var parameterName = Consume(TokenType.Identifier, "FunctionDeclaration: Expected parameter name.");
                    FunctionParameter parameter = new FunctionParameter(parameterName.Lexeme, datatype);
                    parameters.Add(parameter);
                } while (Match(TokenType.Comma));
            }
            Consume(TokenType.CloseBracket, "FunctionDeclaration: Expected ')' after parameters.");

            // Special: If the keyword asm is after the parameters of the function, the whole method is considered assembly.
            if (Check(TokenType.Assembly))
            {
                var asmCode = NextToken();
                var asmBody = new BlockStatement(new List<Statement> { new AssemblyStatement(asmCode) });
                var theAsmFunction = new FunctionStatement(name, parameters, asmBody);
                theAsmFunction.Properties["assembly only function"] = true;
                if (parameters.Count == 0)
                    theAsmFunction.Properties["zero parameters"] = true;

                return theAsmFunction;
            }

            Token? resultType = null;

            if (Match(TokenType.Colon))
                if (Check(TokenType.Type))
                    resultType = NextToken();

            if (Match(TokenType.SemiColon))
            {
                var result = new FunctionStatement(name, parameters);
                if (resultType != null)
                    result.ResultDatatype = resultType.Datatype;
                return result;
            }

            Consume(TokenType.LeftBrace, "FunctionDeclaration: Expected '{' before " + kind + " body.");

            var body = new BlockStatement(Block());
            var theFunctionStatement = new FunctionStatement(name, parameters, body);
            if (resultType != null)
                theFunctionStatement.ResultDatatype = resultType.Datatype;
            return theFunctionStatement;
        }


        private Expression ParseList()
        {
            var elements = new List<Expression>();

            if (!Check(TokenType.RightSquareBracket))
            {
                do
                {
                    if (Check(TokenType.RightSquareBracket))
                        break;
                    elements.Add( Or() );
                } while (Match(TokenType.Comma));
            }

            Consume(TokenType.RightSquareBracket, "Expect ']' to close a list.");
            return new Expressions.List(elements);
        }


    }
}
