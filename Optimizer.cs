using System;
using GroundCompiler.AstNodes;

namespace GroundCompiler
{
    public class Optimizer
    {
        public static void Optimize(AstNode rootNode)
        {
            foreach (Expression? expression in rootNode.FindAllNodes(typeof(Expression.Binary)))
                SimplifyExpression(expression);
        }


        public static void SimplifyExpression(Expression? expr)
        {
            if (expr == null) {  return; }
            bool foundSimplification;
            do { 
                foundSimplification = SimplifyExpressionOnce(expr);
                EnsureValidGrouping(expr);

                // maybe the expression
            } while (foundSimplification);
        }


        public static bool SimplifyExpressionOnce(Expression expr)
        {
            foreach (Expression.Binary binaryExpr in expr.FindAllNodes(typeof(Expression.Binary)))
            {
                if (binaryExpr.CanBothSidesBeCombined())
                {
                    var combinedLiteral = binaryExpr.CombineBothSideSameTypeLiterals();
                    bool updated = binaryExpr?.Parent?.ReplaceInternalAstNode(binaryExpr, combinedLiteral) ?? false;
                    if (updated)
                        return true;
                }
            }
            return false;
        }

        public static void EnsureValidGrouping(Expression expr)
        {
            foreach (Expression.Grouping groupingExpr in expr.FindAllNodes(typeof(Expression.Grouping)))
            {
                var theLiteral = groupingExpr.Expression as Expression.Literal;
                if (theLiteral != null)
                {
                    bool updated = groupingExpr?.Parent?.ReplaceInternalAstNode(groupingExpr, theLiteral) ?? false;
                }
            }
        }


    }
}
