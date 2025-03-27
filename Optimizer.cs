using System;
using System.Text;
using GroundCompiler.AstNodes;

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
            foreach (Expression.FunctionCall functionCall in rootNode.FindAllNodes(typeof(Expression.FunctionCall)))
                ResolveSizeOf(functionCall, ref toReplace);

            foreach (var obj in toReplace)
                obj.ParentNode.ReplaceInternalAstNode(obj.OldNode, obj.NewNode);

            bool continueSimplify = true;
            while (continueSimplify)
            {
                continueSimplify = false;
                foreach (Expression? expression in rootNode.FindAllNodes(typeof(Expression.Binary)))
                    if (SimplifyExpression(expression, ref toReplace))
                    {
                        continueSimplify = true;
                        break;
                    }
            }
        }


        public static void ResolveSizeOf(Expression.FunctionCall functionCall, ref List<NodeReplace> toReplace)
        {
            if (functionCall.FunctionName is GroundCompiler.AstNodes.Expression.Variable functionVar)
            {
                if (functionVar.Name.Lexeme.ToLower() == "sizeof")
                {
                    int theSizeOf = 0;
                    if (functionCall.Arguments[0] is GroundCompiler.AstNodes.Expression.Variable exprVar)
                    {
                        if (Datatype.ContainsDatatype(exprVar.Name.Lexeme))
                        {
                            var classExprType = Datatype.GetDatatype(exprVar.Name.Lexeme);
                            theSizeOf = classExprType.SizeInBytes;
                        } else
                            theSizeOf = exprVar.ExprType.SizeInBytes;
                    }
                    var theResultLiteral = new Expression.Literal("int", theSizeOf);
                    if (functionCall.Parent != null)
                        toReplace.Add(new NodeReplace(functionCall.Parent!, functionCall, theResultLiteral));
                }
            }
        }


        public static bool SimplifyExpression(Expression? expr, ref List<NodeReplace> toReplace)
        {
            bool onceTrue = false;
            if (expr == null) {  return false; }
            bool foundSimplification;
            do { 
                foundSimplification = SimplifyExpressionOnce(expr);
                EnsureValidGrouping(expr);

                if (foundSimplification)
                    onceTrue = true;

                // maybe the expression
            } while (foundSimplification);
            return onceTrue;
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
