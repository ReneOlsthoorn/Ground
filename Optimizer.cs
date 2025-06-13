using GroundCompiler.Statements;
using GroundCompiler.Expressions;
using GroundCompiler.Symbols;

namespace GroundCompiler
{
    public class Optimizer
    {
        public class NodeReplace
        {
            public NodeReplace(AstNode theParent, AstNode theOldNode, AstNode theNewNode) { this.ParentNode = theParent; this.OldNode = theOldNode; this.NewNode = theNewNode; }
            public AstNode ParentNode;
            public AstNode OldNode;
            public AstNode NewNode;
        }


        public static void Optimize(AstNode rootNode)
        {
            List<NodeReplace> toReplace = new();

            bool continueSimplify = true;
            while (continueSimplify)
            {
                continueSimplify = false;
                foreach (Expression? expression in rootNode.FindAllNodes(typeof(Binary)))
                    if (SimplifyExpression(expression, ref toReplace))
                    {
                        continueSimplify = true;
                        break;
                    }
            }
        }

        public static bool SimplifyExpression(Expression? expr, ref List<NodeReplace> toReplace)
        {
            bool onceTrue = false;
            if (expr == null) { return false; }
            bool foundSimplification;
            do { 
                foundSimplification = SimplifyExpressionOnce(expr);
                EnsureValidGrouping(expr);

                if (foundSimplification)
                    onceTrue = true;
            } while (foundSimplification);
            return onceTrue;
        }

        public static bool SimplifyExpressionOnce(Expression expr)
        {
            foreach (Binary binaryExpr in expr.FindAllNodes(typeof(Binary)))
            {
                if (binaryExpr.CanBothSidesBeCombined())
                {
                    var combinedLiteral = binaryExpr.CombineBothSideSameTypeLiterals();
                    bool updated = binaryExpr?.Parent?.ReplaceNode(binaryExpr, combinedLiteral) ?? false;
                    if (updated)
                        return true;
                }
            }
            return false;
        }

        public static void EnsureValidGrouping(Expression expr)
        {
            foreach (Grouping groupingExpr in expr.FindAllNodes(typeof(Grouping)))
            {
                var theLiteral = groupingExpr.expression as Literal;
                if (theLiteral != null)
                {
                    bool updated = groupingExpr?.Parent?.ReplaceNode(groupingExpr, theLiteral) ?? false;
                }
            }
        }

    }
}
