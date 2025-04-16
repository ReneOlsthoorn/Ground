using GroundCompiler.AstNodes;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static GroundCompiler.AstNodes.Statement;

namespace GroundCompiler
{
    public class TypeChecker
    {
        public class NodeReplace
        {
            public NodeReplace(AstNode theParent, AstNode theOldNode, AstNode theNewNode) { this.ParentNode = theParent; this.OldNode = theOldNode; this.NewNode = theNewNode; }
            public AstNode ParentNode;
            public AstNode OldNode;
            public AstNode NewNode;
        }

        public static void Initialize(ProgramNode programNode)
        {
            /* We are going to initialize the nodes, which fills the symboltables, etc... */
            programNode.Initialize();
        }

        public static void Evaluate(ProgramNode rootNode)
        {
            /* Evaluate the sizeof() function, etc... */

            List<NodeReplace> toReplace = new();
            foreach (Expression.FunctionCall functionCall in rootNode.FindAllNodes(typeof(Expression.FunctionCall)))
                ResolveSizeOf(functionCall, ref toReplace);

            foreach (var obj in toReplace)
                obj.ParentNode.ReplaceNode(obj.OldNode, obj.NewNode);
        }


        public static void ResolveSizeOf(Expression.FunctionCall functionCall, ref List<NodeReplace> toReplace)
        {
            if (functionCall.FunctionNameNode is GroundCompiler.AstNodes.Expression.Variable functionVar)
            {
                if (functionVar.Name.Lexeme.ToLower() == "sizeof")
                {
                    UInt64 theSizeOf = 0;

                    if (functionCall.ArgumentNodes[0] is GroundCompiler.AstNodes.Expression.Literal literalExpr)
                    {
                        theSizeOf = (UInt64)literalExpr.ExprType.SizeInBytes;
                    }
                    else if (functionCall.ArgumentNodes[0] is GroundCompiler.AstNodes.Expression.Variable exprVar)
                    {
                        var theVar = exprVar.GetScope()?.GetVariableAnywhere(exprVar.Name.Lexeme);

                        if (Datatype.ContainsDatatype(exprVar.Name.Lexeme))
                        {
                            var classExprType = Datatype.GetDatatype(exprVar.Name.Lexeme);
                            theSizeOf = (UInt64)classExprType.SizeInBytes;
                        }
                        else if (theVar != null)
                        {
                            if (theVar is Scope.Symbol.ParentScopeVariable parentVar)
                                theVar = parentVar.TheLocalVariable;

                            if (theVar.Properties.ContainsKey("assigned element"))
                            {
                                AstNode assignedElement = (AstNode)theVar.Properties["assigned element"]!;
                                if (assignedElement is Expression.List listExpr)
                                    theSizeOf = (UInt64)listExpr.SizeInBytes();
                            }
                        }
                        else
                        {
                            theSizeOf = (UInt64)exprVar.ExprType.SizeInBytes;
                        }
                    }
                    var theResultLiteral = new Expression.Literal("int", theSizeOf);
                    if (functionCall.Parent != null)
                        toReplace.Add(new NodeReplace(functionCall.Parent!, functionCall, theResultLiteral));
                }
            }
        }


    }
}
