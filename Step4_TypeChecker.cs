using GroundCompiler.Statements;
using GroundCompiler.Expressions;
using GroundCompiler.Symbols;

namespace GroundCompiler
{
    public class Step4_TypeChecker
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
            foreach (VarStatement varStatement in rootNode.FindAllNodes(typeof(VarStatement)).ToList())
            {
                if (varStatement.InitializerNode is Expressions.List list)
                {
                    if (list.Properties.ContainsKey("fixed"))
                    {
                        string theGeneratedLabel = GenerationLabelForAsmArray(varStatement.Name.Lexeme);

                        varStatement.ResultType.IsValueType = true;
                        var labelNameToken = new Token(TokenType.Identifier);
                        labelNameToken.Lexeme = theGeneratedLabel;
                        var gToken = new Token(TokenType.Identifier);
                        gToken.Lexeme = "g";

                        Variable newVar = new Variable(gToken);
                        var propExpr = new PropertyExpression(newVar, labelNameToken);
                        newVar.Parent = varStatement;
                        varStatement.InitializerNode = propExpr;

                        var theValues = new List<string>();
                        foreach (var expr in list.ElementsNodes)
                        {
                            if (expr is Literal literal)
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
            foreach (FunctionCall functionCall in rootNode.FindAllNodes(typeof(FunctionCall)))
                ResolveSizeOf(functionCall, ref toReplace);

            foreach (var obj in toReplace)
                obj.ParentNode.ReplaceNode(obj.OldNode, obj.NewNode);
        }


        public static void ResolveSizeOf(FunctionCall functionCall, ref List<NodeReplace> toReplace)
        {
            if (functionCall.FunctionNameNode is Variable functionVar)
            {
                if (functionVar.Name.Lexeme.ToLower() == "sizeof")
                {
                    UInt64 theSizeOf = 0;

                    if (functionCall.ArgumentNodes[0] is Literal literalExpr)
                    {
                        theSizeOf = (UInt64)literalExpr.ExprType.SizeInBytes;
                    }
                    else if (functionCall.ArgumentNodes[0] is Variable exprVar)
                    {
                        var theVar = exprVar.GetScope()?.GetVariableAnywhere(exprVar.Name.Lexeme);

                        if (Datatype.ContainsDatatype(exprVar.Name.Lexeme))
                        {
                            var classExprType = Datatype.GetDatatype(exprVar.Name.Lexeme);
                            theSizeOf = (UInt64)classExprType.SizeInBytes;
                        }
                        else if (theVar != null)
                        {
                            if (theVar is ParentScopeVariable parentVar)
                                theVar = parentVar.TheLocalVariable;

                            if (theVar.Properties.ContainsKey("assigned element"))
                            {
                                AstNode assignedElement = (AstNode)theVar.Properties["assigned element"]!;
                                if (assignedElement is Expressions.List listExpr)
                                    theSizeOf = (UInt64)listExpr.SizeInBytes();
                            }
                        }
                        else
                        {
                            theSizeOf = (UInt64)exprVar.ExprType.SizeInBytes;
                        }
                    }
                    var theResultLiteral = new Literal("int", theSizeOf);
                    if (functionCall.Parent != null)
                        toReplace.Add(new NodeReplace(functionCall.Parent!, functionCall, theResultLiteral));
                }
            }
        }


    }
}
