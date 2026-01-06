
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class Utils
    {
        public static string StringAsDebug(string? str)
        {
            if (str == null)
                return "null";

            return str.Replace("\r", "\\r").Replace("\n", "\\n");
        }

        public static Statement? FindStatementUptree(AstNode? node)
        {
            while (node != null)
            {
                if (node is Statement stmt)
                    return stmt;

                node = node.Parent;
            }
            return null;
        }

    }
}
