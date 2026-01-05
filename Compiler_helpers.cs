using GroundCompiler.Expressions;
using GroundCompiler.Statements;

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

        public static void Error(String message, Token? token = null)
        {
            Console.WriteLine("ERROR: " + message);
            if (token != null) { Console.WriteLine("LineNumber: " + token.LineNumber()); }
            Environment.Exit(0);
        }


        public void PrintAst(Expression expr) { emitter.Writeline(";" + AstPrint.Print(expr)); }
        public void PrintAst(Statement stmt) { emitter.Writeline(";" + AstPrint.Print(stmt)); }


        public void EmitExpression(Expression expr, Datatype targetType)
        {
            if (expr is Literal exprLiteral && targetType.Name == "byte")
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

        public void EmitClasses(List<ClassSymbol> usedClasses)
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


        public void VariableRead(Variable variableExpr)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is LocalVariableSymbol localVarSymbol)
                emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
            else if (symbol is FunctionParameterSymbol funcParSymbol)
                emitter.LoadFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            else if (symbol is ParentScopeVariable parentSymbol)
            {
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement), parentSymbol.DataType);
                cpu.FreeRegister(reg);
            }
            else if (symbol is FunctionSymbol funcSymbol)
                emitter.LoadFunction(emitter.ConvertToAssemblyFunctionName(funcSymbol.Name));
            else if (symbol is HardcodedVariable hardcodedSymbol)
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

                if (symbol.Name == "GC_CurrentExeDir")
                    emitter.LoadAssemblyVariable("currentExeDir");
            }
            else if (symbol is GroupSymbol groupSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
        }


        public void VariableWrite(Variable variableExpr)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);

            if (symbol is LocalVariableSymbol localVarSymbol)
                emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
            else if (symbol is FunctionParameterSymbol funcParSymbol)
                emitter.StoreFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            else if (symbol is ParentScopeVariable parentSymbol)
                emitter.StoreParentFunctionParameter64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement), parentSymbol.DataType);
            else if (symbol is FunctionSymbol funcSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
            else if (symbol is HardcodedVariable hardcodedSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
            else if (symbol is GroupSymbol groupSymbol)
                Compiler.Error("VariableAccessWrite >> Not implemented yet.");
        }


        public void VariableAssignment(Variable variableExpr, Assignment assignment)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is LocalVariableSymbol localVarSymbol)
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
            else if (symbol is FunctionParameterSymbol funcParSymbol)
            {
                EmitExpression(assignment.RightOfEqualSignNode);
                emitter.StoreFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
            }
            else if (symbol is ParentScopeVariable parentSymbol)
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
                EmitConversionCompatibleType(assignment.RightOfEqualSignNode, assignment.LeftOfEqualSignNode.ExprType);
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                if (parentSymbol.DataType.IsReferenceType)
                    emitter.AddReference(assignment.RightOfEqualSignNode);

                emitter.StoreParentFunctionParameter64(assemblyVarName, parentSymbol.DataType);
                cpu.FreeRegister(reg);
            }
            else if (symbol is FunctionSymbol funcSymbol)
                Compiler.Error("Not implemented yet. See VariableAccessAssignment.");
            else if (symbol is HardcodedVariable hardcodedSymbol)
                EmitExpression(assignment.RightOfEqualSignNode);
            else if (symbol is GroupSymbol groupSymbol)
                Compiler.Error("Not implemented yet. See VariableAccessAssignment.");
        }


        public void PropertyExpressionAddressOf(PropertyExpression expr)
        {
            var classStatement = expr.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
            var instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);

            var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
            string procName = functionStmt!.Name.Lexeme;
            string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
            emitter.LoadFunctionParameter64(theName);

            string instVarReg = cpu.GetTmpRegister();
            emitter.Codeline($"mov   {instVarReg}, rax");
            emitter.LeaInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);
        }


        public void VariableAddressOf(Variable variableExpr)
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

            if (symbol is LocalVariableSymbol localVarSymbol)
                emitter.LeaFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
            else if (symbol is FunctionParameterSymbol funcParSymbol)
                emitter.LeaFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol));
            else if (symbol is ParentScopeVariable parentSymbol)
            {
                reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                emitter.LeaParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement));
                cpu.FreeRegister(reg);
            }
            else if (symbol is FunctionSymbol funcSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
            else if (symbol is HardcodedVariable hardcodedSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
            else if (symbol is GroupSymbol groupSymbol)
                Compiler.Error("Not implemented yet. See Compiler_helper.cs>>VariableAccessAddressOf");
        }


        public void UnaryAssignment(Unary expr, Assignment assignment)
        {
            EmitExpression(assignment.RightOfEqualSignNode);
            EmitConversionCompatibleType(assignment.RightOfEqualSignNode, assignment.LeftOfEqualSignNode.ExprType);
            emitter.Push();

            Datatype exprDatatype = Datatype.Default;

            if (expr.RightNode is Grouping groupStmt)
            {
                EmitExpression(expr.RightNode);
                exprDatatype = groupStmt.ExprType;
            }
            else if (expr.RightNode is Variable theVariable)
            {
                VariableRead(theVariable);
                exprDatatype = theVariable.ExprType;
            }
            else if ((expr.RightNode is PropertyExpression propExpr) && expr.Operator.Contains(TokenType.Asterisk))
            {
                if (propExpr.ObjectNode is Variable objVar)
                {
                    PropertySet propSet = new PropertySet(propExpr.ObjectNode, propExpr.Name, assignment.Operator, assignment.RightOfEqualSignNode);
                    propSet.Parent = propExpr.Parent;
                    VisitorPropertySet(propSet);
                    return;
                }
            }

            if (expr.Operator.Contains(TokenType.Asterisk))
            {
                // *a  (a = int*)
                if (exprDatatype.Contains(Datatype.TypeEnum.Pointer) && expr.Operator.Contains(TokenType.Asterisk))
                    emitter.StorePointingTo((exprDatatype.Base == null) ? Datatype.Default : exprDatatype.Base);
                // *a  (a = ptr)
                else if (exprDatatype.Contains(Datatype.TypeEnum.Integer) && expr.Operator.Contains(TokenType.Asterisk))
                    emitter.StorePointingTo(exprDatatype);
            } else
                Compiler.Error("UnaryAssignment must pop the assignment-value of the stack.");
        }


        // Array value is loaded (usually to register RAX) or stored (as part of an assignment)
        public void ArrayAccess(ArrayAccess arrayExpr, Assignment? assignment = null, bool addressOf = false)
        {
            var currentScope = arrayExpr.GetScope();
            //TODO: this.prop.prop2[2] must be possible. The member must be an expression, not a variable.

            var symbol = GetSymbol(arrayExpr.GetMemberVariable()!.Name.Lexeme, currentScope!);
            var targetType = Datatype.Default;

            if (arrayExpr.IndexNodes != null)
            {
                var varSymbol = symbol as VariableSymbol;
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

                if (symbol is LocalVariableSymbol localVarSymbol)
                {
                    targetType = localVarSymbol!.DataType.Base;
                    elementSizeInBytes = localVarSymbol!.DataType.Base!.SizeInBytes;
                    emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
                }
                else if (symbol is ParentScopeVariable parentSymbol)
                {
                    targetType = parentSymbol!.DataType.Base;
                    elementSizeInBytes = parentSymbol!.DataType.Base!.SizeInBytes;
                    var reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                    emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol.TheScopeStatement), parentSymbol.DataType);
                    cpu.FreeRegister(reg);
                }
                else if (symbol is FunctionParameterSymbol funcParSymbol)
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
                    {
                        //if array[i] is a reference type, get the memoryPointer for that element. An array of class elements do not contain memory pointers, but the real instance.
                        if (targetType.IsReferenceType && (!targetType.isClass()))
                        {
                            emitter.LoadBasedIndexToCurrent(elementSizeInBytes, baseReg, indexReg, targetType);
                            emitter.GetMemoryPointerFromIndex();
                        }
                        else
                            emitter.LeaBasedIndex(elementSizeInBytes, baseReg, indexReg);
                    }
                    else
                    {
                        emitter.LoadBasedIndexToCurrent(elementSizeInBytes, baseReg, indexReg, targetType);
                        emitter.SignExtend(targetType);
                    }
                }
                cpu.FreeRegister(baseReg);
                cpu.FreeRegister(indexReg);
            }
        }


        public void EmitConversionCompatibleType(Expression sourceExpr, Datatype destinationDatatype, bool copyDatatypeToSource = true)
        {
            if (sourceExpr is Literal literalExpr)
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
                {
                    if (sourceDatatype.SizeInBytes == 4)
                        emitter.resizeCurrentFloatingPoint(4, 8); // convert from f32 to f64, because FloatToString only prints 64-bit float values.
                    emitter.FloatToString(sourceExpr);
                }
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
                emitter.FloatToInteger(sourceDatatype, destinationDatatype);
                if (copyDatatypeToSource)
                    sourceExpr.ExprType = destinationDatatype;
            }
            else if (sourceDatatype.Contains(Datatype.TypeEnum.Integer) && destinationDatatype.Contains(Datatype.TypeEnum.Integer) && destinationDatatype.SizeInBytes < sourceDatatype.SizeInBytes)
            {
                emitter.resizeCurrent(destinationDatatype.SizeInBytes);
            }
            else if (sourceDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && destinationDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && (destinationDatatype.SizeInBytes != sourceDatatype.SizeInBytes))
            {
                emitter.resizeCurrentFloatingPoint(sourceDatatype.SizeInBytes, destinationDatatype.SizeInBytes);
            }
        }

        public bool IsUnaryAddressOf(Expression expr)
        {
            if (expr is Unary unaryExpr)
                return unaryExpr.Operator.Contains(TokenType.Ampersand);
            return false;
        }

    }
}
