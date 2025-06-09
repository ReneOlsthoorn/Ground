using GroundCompiler.AstNodes;
using static GroundCompiler.AstNodes.Expression;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Datatype;
using static GroundCompiler.Scope;

namespace GroundCompiler
{
    public partial class Compiler : Statement.IVisitor<object?>, Expression.IVisitor<object?>
    {

        public Symbol? GetSymbol(string name, Scope scope)
        {
            var symbol = scope.GetVariable(name);
            if (symbol == null)
            {
                symbol = scope.GetVariableAnywhere(name);
                if (symbol == null)
                    Compiler.Error($"Symbol {name} does not exist.");
            }
            return symbol;
        }


        public static void Error(String message)
        {
            Console.WriteLine("ERROR: " + message);
            Environment.Exit(0);
        }


        public void PrintAst(Expression expr) { emitter.Writeline(";" + AstPrint.Print(expr)); }
        public void PrintAst(Statement stmt) { emitter.Writeline(";" + AstPrint.Print(stmt)); }


        public void EmitExpression(Expression expr, Datatype targetType)
        {
            if (expr is Expression.Literal exprLiteral && targetType.Name == "byte")
                exprLiteral.ConvertToByteValue();

            this.EmitExpression(expr);
        }


        public void EmitFunctions(List<FunctionStatement> usedFunctions)
        {
            foreach (var funcStatement in usedFunctions)
            {
                var emittedProcedure = new EmittedProcedure(functionStatement: funcStatement, classStatement: null, emitter);
                emittedProcedure.MainCallback = () =>
                {
                    VisitorBlock(funcStatement.BodyNode);
                };
                emittedProcedure.Emit();
            }
        }

        public void EmitClasses(List<Symbol.ClassSymbol> usedClasses)
        {
            foreach (var aClass in usedClasses)
            {
                var classStatement = aClass.ClassStatement;
                var emittedClass = new EmittedClass(classStatement, emitter);
                emittedClass.MethodCallback = (aMethod) =>
                {
                    VisitorBlock(aMethod.BodyNode);
                };
                emittedClass.Emit();
            }
        }


        public void VariableRead(Expression.Variable variableExpr)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
                emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
            else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
                emitter.LoadFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
            {
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement), parentSymbol.DataType);
                cpu.FreeRegister(reg);
            }
            else if (symbol is Scope.Symbol.FunctionSymbol funcSymbol)
                emitter.LoadFunction(emitter.ConvertToAssemblyFunctionName(funcSymbol.Name));
            else if (symbol is Scope.Symbol.HardcodedVariable hardcodedSymbol)
            {
                if (symbol.Name == "GC_ScreenText")
                    emitter.LoadSystemVarsVariable("screentext1_p");

                if (symbol.Name == "GC_ScreenColors")
                    emitter.LoadSystemVarsVariable("font32_charcolor_p");

                if (symbol.Name == "GC_ScreenText_U32")
                    emitter.LoadSystemVarsVariable("screentext4_p");

                if (symbol.Name == "GC_Colortable")
                    emitter.LoadSystemVarsVariable("colortable_p");

                if (symbol.Name == "GC_ScreenFont")
                    emitter.LoadSystemVarsVariable("font256_p");

                if (symbol.Name == "GC_Screen_TextRows")
                    emitter.LoadAssemblyConstant("GC_Screen_TextRows");

                if (symbol.Name == "GC_CurrentExeDir")
                    emitter.LoadAssemblyVariable("currentExeDir");

                if (symbol.Name == "GC_Screen_TextColumns")
                    emitter.LoadAssemblyConstant("GC_Screen_TextColumns");
            }
            else if (symbol is Scope.Symbol.GroupSymbol groupSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
        }


        public void VariableWrite(Expression.Variable variableExpr)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);

            if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
                emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
            else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
                emitter.StoreFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
                emitter.StoreParentFunctionParameter64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement), parentSymbol.DataType);
            else if (symbol is Scope.Symbol.FunctionSymbol funcSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
            else if (symbol is Scope.Symbol.HardcodedVariable hardcodedSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
            else if (symbol is Scope.Symbol.GroupSymbol groupSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
        }


        public void VariableAssignment(Expression.Variable variableExpr, Expression.Assignment assignment)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
            {
                EmitExpression(assignment.RightOfEqualSignNode);
                EmitConversionCompatibleType(assignment.RightOfEqualSignNode, assignment.LeftOfEqualSignNode.ExprType);
                if (localVarSymbol!.DataType.IsReferenceType)
                {
                    reg = emitter.Gather_CurrentStackframe();
                    emitter.AddReference(assignment.RightOfEqualSignNode);
                    cpu.FreeRegister(reg);
                }
                emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
            }
            else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
            {
                EmitExpression(assignment.RightOfEqualSignNode);
                emitter.StoreFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            }
            else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
            {
                var assemblyVarName = emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement);
                if (parentSymbol.DataType.IsReferenceType)
                {
                    reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                    emitter.LoadParentFunctionVariable64(assemblyVarName, parentSymbol.DataType);
                    emitter.RemoveReference();
                    cpu.FreeRegister(reg);
                }
                EmitExpression(assignment.RightOfEqualSignNode);
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                if (parentSymbol.DataType.IsReferenceType)
                    emitter.AddReference(assignment.RightOfEqualSignNode);

                emitter.StoreParentFunctionParameter64(assemblyVarName, parentSymbol.DataType);
                cpu.FreeRegister(reg);
            }
            else if (symbol is Scope.Symbol.FunctionSymbol funcSymbol)
                Compiler.Error("Not implemented yet. See VariableAccessAssignment.");
            else if (symbol is Scope.Symbol.HardcodedVariable hardcodedSymbol)
                EmitExpression(assignment.RightOfEqualSignNode);
            else if (symbol is Scope.Symbol.GroupSymbol groupSymbol)
                Compiler.Error("Not implemented yet. See VariableAccessAssignment.");
        }


        public void VariableAddressOf(Expression.Variable variableExpr)
        {
            // A reference type must always return the memory location, and never the Lea of the variable.
            if (variableExpr.ExprType.IsReferenceType)
            {
                VariableRead(variableExpr);
                emitter.GetMemoryPointerFromIndex();
                return;
            }

            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
                emitter.LeaFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
            else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
                emitter.LeaFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol));
            else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
            {
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                emitter.LeaParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement));
                cpu.FreeRegister(reg);
            }
            else if (symbol is Scope.Symbol.FunctionSymbol funcSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
            else if (symbol is Scope.Symbol.HardcodedVariable hardcodedSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
            else if (symbol is Scope.Symbol.GroupSymbol groupSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
        }


        public void UnaryAssignment(Expression.Unary expr, Expression.Assignment assignment)
        {
            EmitExpression(assignment.RightOfEqualSignNode);
            EmitConversionCompatibleType(assignment.RightOfEqualSignNode, assignment.LeftOfEqualSignNode.ExprType);
            emitter.Push();

            Datatype exprDatatype = Datatype.Default;

            if (expr.RightNode is Expression.Grouping groupStmt)
            {
                EmitExpression(expr.RightNode);
                exprDatatype = groupStmt.ExprType;
            }
            else if (expr.RightNode is Expression.Variable theVariable)
            {
                VariableRead(theVariable);
                exprDatatype = theVariable.ExprType;
            }

            if (expr.Operator.Contains(TokenType.Asterisk))
            {
                // *a  (a = int*)
                if (exprDatatype.Contains(TypeEnum.Pointer) && expr.Operator.Contains(TokenType.Asterisk))
                    emitter.StorePointingTo((exprDatatype.Base == null) ? Datatype.Default : exprDatatype.Base);
                // *a  (a = ptr)
                else if (exprDatatype.Contains(TypeEnum.Integer) && expr.Operator.Contains(TokenType.Asterisk))
                    emitter.StorePointingTo(exprDatatype);
            } else
                Compiler.Error("UnaryAssignment must pop the assignment-value of the stack.");
        }


        // Array value is loaded (usually to register RAX) or stored (as part of an assignment)
        public void ArrayAccess(Expression.ArrayAccess arrayExpr, Expression.Assignment? assignment = null, bool addressOf = false)
        {
            var currentScope = arrayExpr.GetScope();
            var symbol = GetSymbol(arrayExpr.GetMemberVariable()!.Name.Lexeme, currentScope!);
            var targetType = Datatype.Default;

            if (arrayExpr.IndexNodes != null)
            {
                var varSymbol = symbol as Scope.Symbol.VariableSymbol;
                string indexReg = cpu.GetRestoredRegister(arrayExpr);
                for (int i = 0; i < arrayExpr.IndexNodes.Count; i++)
                {
                    if (i > 0)
                        emitter.Push();  // save old index temp

                    var expr = arrayExpr.IndexNodes[i];
                    EmitExpression(expr);
                    UInt64 multiplier = 1;

                    if (i > 0)
                        for (int j = i - 1; j < (varSymbol!.DataType.ArrayNrs!.Count - 1); j++)
                            multiplier *= varSymbol.DataType.ArrayNrs[j];

                    if (multiplier > 1)
                    {
                        cpu.ReserveRegister("rdx");
                        emitter.Codeline($"mov   rdx, {multiplier}");
                        emitter.Codeline($"mul   rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
                        cpu.FreeRegister("rdx");
                    }
                    if (i > 0)
                        emitter.PopAdd(expr, expr.ExprType);
                }
                emitter.MoveCurrentToRegister(indexReg);
                int elementSizeInBytes = 0;

                if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
                {
                    targetType = localVarSymbol!.DataType.Base;
                    elementSizeInBytes = localVarSymbol!.DataType.Base!.SizeInBytes;
                    emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
                }
                else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
                {
                    targetType = parentSymbol!.DataType.Base;
                    elementSizeInBytes = parentSymbol!.DataType.Base!.SizeInBytes;
                    var reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                    emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol.TheScopeStatement), parentSymbol.DataType);
                    cpu.FreeRegister(reg);
                }
                else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
                {
                    targetType = funcParSymbol!.DataType.Base;
                    elementSizeInBytes = funcParSymbol!.DataType.Base!.SizeInBytes;
                    emitter.LoadFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol));
                }

                if (varSymbol!.DataType.IsReferenceType)
                    emitter.GetMemoryPointerFromIndex();

                string baseReg = cpu.GetRestoredRegister(arrayExpr);
                emitter.MoveCurrentToRegister(baseReg);
                if (assignment != null)
                {
                    EmitExpression(assignment.RightOfEqualSignNode, targetType);
                    EmitConversionCompatibleType(assignment.RightOfEqualSignNode, targetType, copyDatatypeToSource: false);
                    emitter.StoreCurrentInBasedIndex(elementSizeInBytes, baseReg, indexReg, targetType);
                }
                else
                {
                    if (addressOf)
                        emitter.LeaBasedIndex(elementSizeInBytes, baseReg, indexReg);
                    else
                        emitter.LoadBasedIndexToCurrent(elementSizeInBytes, baseReg, indexReg, targetType);
                }
                cpu.FreeRegister(baseReg);
                cpu.FreeRegister(indexReg);
            }
        }


        public void EmitConversionCompatibleType(Expression sourceExpr, Datatype destinationDatatype, bool copyDatatypeToSource = true)
        {
            if (sourceExpr is Expression.Literal literalExpr)
            {
                if (literalExpr.Value == null)
                    return;
            }

            Datatype sourceDatatype = sourceExpr.ExprType;

            if (destinationDatatype.Name == "string")
            {
                if (sourceDatatype.Contains(Datatype.TypeEnum.Integer))
                    emitter.IntegerToString(sourceExpr);
                else if (sourceDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                    emitter.FloatToString(sourceExpr);
                else if (sourceDatatype.Contains(Datatype.TypeEnum.Boolean))
                    emitter.BooleanToString(sourceExpr);

                if (copyDatatypeToSource)
                    sourceExpr.ExprType = destinationDatatype;
            }
            else if (destinationDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && sourceDatatype.Contains(Datatype.TypeEnum.Integer))
            {
                emitter.IntegerToFloat(destinationDatatype.SizeInBytes);
                if (copyDatatypeToSource)
                    sourceExpr.ExprType = destinationDatatype;
            }
            else if (destinationDatatype.Contains(Datatype.TypeEnum.Integer) && sourceDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                emitter.FloatToInteger();
                if (copyDatatypeToSource)
                    sourceExpr.ExprType = destinationDatatype;
            }
            else if (sourceDatatype.Contains(Datatype.TypeEnum.Integer) && destinationDatatype.Contains(Datatype.TypeEnum.Integer) && destinationDatatype.SizeInBytes < sourceDatatype.SizeInBytes)
            {
                emitter.resizeCurrent(destinationDatatype.SizeInBytes);
            }
            else if (sourceDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && destinationDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && destinationDatatype.SizeInBytes < sourceDatatype.SizeInBytes)
            {
                emitter.resizeCurrentFloatingPoint(sourceDatatype.SizeInBytes, destinationDatatype.SizeInBytes);
            }
        }

        public bool IsUnaryAddressOf(Expression expr)
        {
            if (expr is Expression.Unary unaryExpr)
                return unaryExpr.Operator.Contains(TokenType.Ampersand);
            return false;
        }

    }
}
