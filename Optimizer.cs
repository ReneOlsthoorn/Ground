using GroundCompiler.Statements;
using GroundCompiler.Expressions;
using GroundCompiler.Symbols;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Optimizer
    {
        public static void Optimize(AstNode rootNode)
        {
            bool optimizeAgain = false;

            // Literal folding
            bool continueSimplify = true;
            while (continueSimplify)
            {
                continueSimplify = false;
                foreach (Expression? expression in rootNode.FindAllNodes(typeof(Binary)).ToList())
                    if (SimplifyExpression(expression))
                    {
                        continueSimplify = true;
                        break;
                    }
            }

            // Welke variabelen worden gedefinieerd en zijn Literal?
            var literalVarsList = rootNode.AllNodes()
                .OfType<VarStatement>()
                .Where(e => e.InitializerNode is Literal).ToList();

            var literalVars = new Dictionary<string, (Literal, Datatype)>();
            foreach (var variable in literalVarsList)
            {
                var initNode = variable.InitializerNode as Literal;
                var resultType = variable.ResultType;

                // f32 is different than a f64. It needs convertion when putting a literal as a function argument. This is not implemented at this moment.
                if (resultType.Contains(Datatype.TypeEnum.FloatingPoint) && resultType.SizeInBytes == 4)
                    continue;

                literalVars[variable.GetNameIncludingLocalScope()!] = (initNode!, resultType);
            }

            var assignedVarsDict = new Dictionary<string, int>();

            var exprStatements = rootNode.AllNodes()
                .OfType<ExpressionStatement>()
                .Where(e => (e.ExpressionNode is Assignment assignExpr)
                            && (assignExpr.LeftOfEqualSignNode is Variable varExpr))
                .Select(e => e.ExpressionNode as Assignment)
                .Select(e => e.LeftOfEqualSignNode as Variable).ToList();
            foreach (var exprStmt in exprStatements)
            {
                var theVar = exprStmt?.GetNameIncludingLocalScope();
                if (theVar != null)
                    assignedVarsDict[theVar] = 1;
            }

            var unaryStatements = rootNode.AllNodes()
                .OfType<Unary>()
                .Where(e => e.RightNode is Variable)
                .Select(e => e.RightNode as Variable).ToList();
            foreach (var unaryStmt in unaryStatements)
            {
                var theVar = unaryStmt?.GetNameIncludingLocalScope();
                if (theVar != null)
                    assignedVarsDict[theVar] = 1;
            }

            var unAssignedVars = literalVars.Keys.Where(e => !assignedVarsDict.ContainsKey(e)).ToList();

            // Vervang de niet opnieuw toegewezen variabelen met de Literal en optimize opnieuw.
            foreach (var unAssigned in unAssignedVars)
            {
                var variableUsages = rootNode.AllNodes().OfType<Variable>().Where(e => e.GetNameIncludingLocalScope() == unAssigned).ToList();
                foreach (var varUsage in variableUsages)
                {
                    var theLiteral = literalVars[unAssigned].Item1!;
                    if (theLiteral is Literal literalExpr)
                        theLiteral = literalExpr.DeepCopy();

                    theLiteral.ExprType = literalVars[unAssigned].Item2.DeepCopy(); // we zetten de ExprType naar de ResultType, anders wordt de literal van "float f = 60;" niet goed vervangen.

                    bool updated = varUsage?.Parent?.ReplaceNode(varUsage, theLiteral) ?? false;
                    Console.WriteLine($"Optimzer: Replaced with Literal: {unAssigned}");

                    if (updated)
                    {
                        varUsage?.Parent?.Initialize();
                        optimizeAgain = true;
                    }
                }
            }

            // Find never used variables and remove them.
            var allVarsList = rootNode.AllNodes()
                .OfType<VarStatement>()
                .Where(e => e.Parent is not ClassStatement);

            var allVarsUnused = new Dictionary<string, VarStatement>();
            foreach (var allVar in allVarsList)
                allVarsUnused[allVar.GetNameIncludingLocalScope()!] = allVar;

            var allVarUsage = rootNode.AllNodes().OfType<Variable>();
            foreach (var allVarUse in allVarUsage)
            {
                var theVar = allVarUse.GetNameIncludingLocalScope();
                if (theVar != null)
                    allVarsUnused.Remove(theVar);
            }

            var thisProps = rootNode.AllNodes().OfType<PropertyExpression>().ToList();
            foreach (var thisProp in thisProps)
            {
                var theVar = thisProp.GetNameIncludingLocalScope();
                if (theVar != null)
                    allVarsUnused.Remove(theVar);
            }

            var asmCode = rootNode.AllNodes().OfType<AssemblyStatement>().ToList();
            var asmKeyDictionary = new Dictionary<string, bool>();
            foreach (var asm in asmCode)
            {
                string text = asm.LiteralAsmCode.StringValue;
                var matches = Regex.Matches(text, "\\[(.+\\@.+)\\]", RegexOptions.IgnoreCase);
                foreach (Match match in matches)
                    asmKeyDictionary[match.Groups[1].Value] = true;
            }

            foreach (var unusedVar in allVarsUnused)
            {
                string asmVariableName = unusedVar.Key;
                if (asmKeyDictionary.ContainsKey(asmVariableName))
                    continue;

                unusedVar.Value?.Parent?.GetScope()?.RemoveVariable(unusedVar.Value.Name.Lexeme);
                unusedVar.Value?.Parent?.RemoveNode(unusedVar.Value!);
                Console.WriteLine($"Optimzer: Removed variable: {unusedVar.Value?.Name.Lexeme}  {asmVariableName}");
            }

            if (optimizeAgain)
                Optimize(rootNode);
        }


        public static bool SimplifyExpression(Expression? expr)
        {
            if (expr == null)
                return false;

            bool onceTrue = false;
            foreach (Binary binaryExpr in expr.FindAllNodes(typeof(Binary)))
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
                EnsureValidGrouping(expr);

            return onceTrue;
        }

        // Als een groep alleen maar uit een Literal bestaat, dan kun je de group verwijderen.
        public static void EnsureValidGrouping(Expression expr)
        {
            foreach (Grouping groupingExpr in expr.FindAllNodes(typeof(Grouping)))
                if (groupingExpr.expression is Literal theLiteral)
                    groupingExpr?.Parent?.ReplaceNode(groupingExpr, theLiteral.DeepCopy());
        }

    }
}
