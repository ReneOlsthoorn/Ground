using GroundCompiler.AstNodes;
using System.Text;
using static GroundCompiler.AstNodes.Expression;
using static GroundCompiler.AstNodes.Statement;

namespace GroundCompiler
{
    public class AstPrinter : Expression.IVisitor<string>, Statement.IVisitor<string>
    {
        public string VisitorProgramNode(Statement.ProgramNode stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(program ");

            foreach (Statement statement in stmt.Nodes)
                builder.Append(statement.Accept(this));

            builder.Append(")");
            return builder.ToString();
        }


        public string VisitorClass(Statement.ClassStatement stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(class " + stmt.Name.Lexeme);

            //if (stmt.Superclass != null)
            //    builder.Append(" < " + Print(stmt.Superclass));

            foreach (var method in stmt.FunctionNodes)
                builder.Append(" " + Print(method));

            builder.Append(")");
            return builder.ToString();
        }

        public string VisitorGroup(Statement.GroupStatement stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(group " + stmt.Name.Lexeme);

            foreach (var method in stmt.FunctionNodes)
                builder.Append(" " + Print(method));

            builder.Append(")");
            return builder.ToString();
        }

        public string VisitorBreak(Statement.BreakStatement stmt)
        {
            return "(break)";
        }

        public string VisitorAssembly(Statement.AssemblyStatement stmt)
        {
            return "(assembly)";
        }
        public string VisitorDll(Statement.DllStatement stmt)
        {
            return "(dll)";
        }

        public string VisitorPoke(Statement.PokeStatement stmt)
        {
            return "(poke)";
        }


        public string VisitorReturn(Statement.ReturnStatement stmt)
        {
            if (stmt.ReturnValueNode == null)
                return "(return)";

            return Parenthesize("return", stmt.ReturnValueNode);
        }


        public string VisitorBlock(Statement.BlockStatement stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(block ");

            foreach (Statement statement in stmt.Nodes)
                builder.Append(statement.Accept(this));

            builder.Append(")");
            return builder.ToString();
        }


        public string VisitorVariableDeclaration(Statement.VarStatement stmt)
        {
            if (stmt.InitializerNode == null)
                return Parenthesize2(stmt.ResultType.Name, stmt.Name);

            return Parenthesize2(stmt.ResultType.Name, stmt.Name, "=", stmt.InitializerNode);
        }


        public string VisitorIf(Statement.IfStatement statement)
        {
            if (statement.ElseBranchNode == null)
                return Parenthesize2("if", statement.ConditionNode, statement.ThenBranchNode);

            return Parenthesize2("if-else", statement.ConditionNode, statement.ThenBranchNode, statement.ElseBranchNode);
        }


        public string VisitorWhile(Statement.WhileStatement stmt)
        {
            return Parenthesize2("while", stmt.ConditionNode, stmt.BodyNode);
        }

        public string VisitorExpression(Statement.ExpressionStatement stmt)
        {
            return Parenthesize(";", stmt.ExpressionNode);
        }

        public string VisitorFunction(FunctionStatement stmt)
        {
            var builder = new StringBuilder();
            builder.Append("(function " + stmt.Name.Lexeme + "(");

            foreach (var param in stmt.Parameters)
            {
                if (param != stmt.Parameters[0])
                    builder.Append(" ");

                builder.Append(param.TheType + " " + param.Name);
            }

            builder.Append(") ");

            foreach (var body in stmt.BodyNode.Nodes)
                builder.Append(((Statement)body).Accept(this));

            builder.Append(")");
            return builder.ToString();
        }



        public string Print(Expression expr)
        {
            return expr.Accept(this);
        }

        public string Print(Statement stmt)
        {
            return stmt.Accept(this);
        }

        public string VisitorPropertyGet(Expression.PropertyGet expr)
        {
            return Parenthesize2(".", expr.ObjectNode, expr.Name.Lexeme);
        }

        public string VisitorAssignment(Expression.Assignment expr)
        {
            return Parenthesize2(expr.Operator.Lexeme, expr.LeftOfEqualSignNode, expr.RightOfEqualSignNode);
        }

        public string VisitorBinary(Expression.Binary expr)
        {
            return Parenthesize(expr.Operator.Lexeme, expr.LeftNode, expr.RightNode);
        }


        public string VisitorFunctionCall(Expression.FunctionCall expr)
        {
            return Parenthesize2("call", expr.FunctionNameNode, expr.ArgumentNodes);
        }

        public string VisitorGrouping(Expression.Grouping expr)
        {
            return Parenthesize("group", expr.expression);
        }

        public string VisitorLiteral(Expression.Literal expr)
        {
            if (expr.Value == null) return "nil";
            if (expr.ExprType.Name == "string")
                return $"\"{Utils.StringAsDebug(expr.Value.ToString()) }\"";

            return expr.Value.ToString() ?? "";
        }

        public string VisitorPropertySet(Expression.PropertySet expr)
        {
            return Parenthesize2("=", expr.ObjectNode, expr.Name.Lexeme, expr.ValueNode);
        }

        public string VisitorUnary(Expression.Unary expr)
        {
            return Parenthesize(expr.Operator.Lexeme, expr.RightNode);
        }

        public string VisitorVariable(Expression.Variable expr)
        {
            return expr.Name.Lexeme;
        }

        public string VisitorList(Expression.List expr)
        {
            return " [ LIST ] ";
        }

        public string VisitorArrayAccess(Expression.ArrayAccess access)
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
