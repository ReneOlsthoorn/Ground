using System.Text;
using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class AstPrinter : Expression.IVisitor<string>, Statement.IVisitor<string>
    {
        public string VisitorProgramNode(ProgramNode stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(program ");

            foreach (Statement statement in stmt.Nodes)
                builder.Append(statement.Accept(this));

            builder.Append(")");
            return builder.ToString();
        }

        public string VisitorBreak(BreakStatement stmt)
        {
            return "(break)";
        }

        public string VisitorAssembly(AssemblyStatement stmt)
        {
            return "(assembly)";
        }

        public string VisitorPoke(PokeStatement stmt)
        {
            return "(poke)";
        }

        public string VisitorReturn(ReturnStatement stmt)
        {
            if (stmt.ReturnValueNode == null)
                return "(return)";

            return Parenthesize("return", stmt.ReturnValueNode);
        }


        public string VisitorBlock(BlockStatement stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(block ");

            foreach (Statement statement in stmt.Nodes)
                builder.Append(statement.Accept(this));

            builder.Append(")");
            return builder.ToString();
        }


        public string VisitorVariableDeclaration(VarStatement stmt)
        {
            if (stmt.InitializerNode == null)
                return Parenthesize2(stmt.ResultType.Name, stmt.Name);

            return Parenthesize2(stmt.ResultType.Name, stmt.Name, "=", stmt.InitializerNode);
        }


        public string VisitorIf(IfStatement statement)
        {
            if (statement.ElseBranchNode == null)
                return Parenthesize2("if", statement.ConditionNode, statement.ThenBranchNode);

            return Parenthesize2("if-else", statement.ConditionNode, statement.ThenBranchNode, statement.ElseBranchNode);
        }


        public string VisitorWhile(WhileStatement stmt)
        {
            return Parenthesize2("while", stmt.ConditionNode, stmt.BodyNode);
        }

        public string VisitorExpression(ExpressionStatement stmt)
        {
            return Parenthesize(";", stmt.ExpressionNode);
        }

        public string Print(AstNode node)
        {
            if (node is Expression expr)
                return expr.Accept(this);
            if (node is Statement statement)
                return statement.Accept(this);
            return "";
        }

        public string Print(Expression expr)
        {
            return expr.Accept(this);
        }

        public string Print(Statement stmt)
        {
            return stmt.Accept(this);
        }

        public string VisitorPropertyGet(PropertyExpression expr)
        {
            return Parenthesize2(".", expr.ObjectNode, expr.Name.Lexeme);
        }

        public string VisitorAssignment(Assignment expr)
        {
            return Parenthesize2(expr.Operator.Lexeme, expr.LeftOfEqualSignNode, expr.RightOfEqualSignNode);
        }

        public string VisitorBinary(Binary expr)
        {
            return Parenthesize(expr.Operator.Lexeme, expr.LeftNode, expr.RightNode);
        }


        public string VisitorFunctionCall(FunctionCall expr)
        {
            return Parenthesize2("call", expr.FunctionNameNode, expr.ArgumentNodes);
        }

        public string VisitorGrouping(Grouping expr)
        {
            return Parenthesize("group", expr.expression);
        }

        public string VisitorLiteral(Literal expr)
        {
            if (expr.Value == null) return "nil";
            if (expr.ExprType.Name == "string")
                return $"\"{Utils.StringAsDebug(expr.Value.ToString()) }\"";

            return expr.Value.ToString() ?? "";
        }

        public string VisitorPropertySet(PropertySet expr)
        {
            return Parenthesize2("=", expr.ObjectNode, expr.Name.Lexeme, expr.ValueNode);
        }

        public string VisitorUnary(Unary expr)
        {
            return Parenthesize(expr.Operator.Lexeme, expr.RightNode);
        }

        public string VisitorVariable(Variable expr)
        {
            return expr.Name.Lexeme;
        }

        public string VisitorList(Expressions.List expr)
        {
            return " [ LIST ] ";
        }

        public string VisitorArrayAccess(ArrayAccess access)
        {
            return " access ";
        }

        private string Parenthesize(string name, params Expression[] exprs)
        {
            var builder = new StringBuilder();
            builder.Append("(").Append(name);

            foreach (var expr in exprs)
            {
                if (expr != null)
                {
                    builder.Append(" ");
                    builder.Append(expr.Accept(this));
                }
            }

            builder.Append(")");
            return builder.ToString();
        }


        private string Parenthesize2(string name, params object[] parts)
        {
            var builder = new StringBuilder();
            builder.Append("(").Append(name);

            foreach (var part in parts)
            {
                builder.Append(" ");

                switch (part)
                {
                    case Expression expr:
                        builder.Append(expr.Accept(this));
                        break;

                    case Statement stmt:
                        builder.Append(stmt.Accept(this));
                        break;

                    case Token token:
                        builder.Append(token.Lexeme);
                        break;

                    case IEnumerable<Expression> expressions:
                        if (expressions.Any())
                        {
                            builder.Append("[");
                            foreach (var expr in expressions)
                            {
                                if (expr != expressions.First())
                                {
                                    builder.Append(", ");
                                }
                                builder.Append(expr.Accept(this));
                            }
                            builder.Append("]");
                        }
                        break;

                    default:
                        builder.Append(part.ToString());
                        break;
                }
            }

            builder.Append(")");
            return builder.ToString();
        }

    }

}
