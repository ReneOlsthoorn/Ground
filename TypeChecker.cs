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

        public static string GenerationLabelForAsmArray(string name) => $"fixed_gen_{name}";

        public static void Evaluate(ProgramNode rootNode)
        {
            /* Transform [12] fixed */
            foreach (Statement.VarStatement varStatement in rootNode.FindAllNodes(typeof(Statement.VarStatement)).ToList())
            {
                if (varStatement.InitializerNode is Expression.List list)
                {
                    if (list.Properties.ContainsKey("fixed"))
                    {
                        string theGeneratedLabel = GenerationLabelForAsmArray(varStatement.Name.Lexeme);

                        varStatement.ResultType.IsValueType = true;
                        var labelNameToken = new Token(TokenType.Identifier);
                        labelNameToken.Lexeme = theGeneratedLabel;
                        var gToken = new Token(TokenType.Identifier);
                        gToken.Lexeme = "g";

                        Expression.Variable newVar = new Expression.Variable(gToken);
                        var propExpr = new Expression.PropertyExpression(newVar, labelNameToken);
                        newVar.Parent = varStatement;
                        varStatement.InitializerNode = propExpr;

                        var theValues = new List<string>();
                        foreach (var expr in list.ElementsNodes)
                        {
                            if (expr is Expression.Literal literal)
                                theValues.Add(Convert.ToString(literal.Value)!);
                        }

                        string asmDataSize;
                        switch (list.ExprType!.Base!.SizeInBytes)
                        {
                            case 8:
                                asmDataSize = "dq";
                                break;
                            case 4:
                                asmDataSize = "dd";
                                break;
                            case 2:
                                asmDataSize = "dw";
                                break;
                            case 1:
                                asmDataSize = "db";
                                break;
                            default:
                                asmDataSize = "dq";
                                break;
                        }

                        Token asmStrToken = new Token();
                        String asmStr = "";

                        if (list.ElementsNodes.Count == 0)
                        {
                            UInt64 nrBytes = list.SizeInBytes();                           
                            asmStr = $"{theGeneratedLabel} db {nrBytes} dup(0)";
                        } else
                            asmStr = $"{theGeneratedLabel} {asmDataSize} {string.Join(",", theValues)}";

                        asmStrToken.Value = asmStr;
                        asmStrToken.Properties["attributes"] = "data";
                        var asmStatement = new AssemblyStatement(asmStrToken);

                        var theRootBlocknode = rootNode.Nodes.First();
                        theRootBlocknode.AddNode(asmStatement);
                        asmStatement.Parent = theRootBlocknode;
                    }
                }
            }


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
