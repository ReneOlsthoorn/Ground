using GroundCompiler.AstNodes;
using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Linq;
using static GroundCompiler.AstNodes.Statement;
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
                    VisitorBlock(funcStatement.Body);
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
                    VisitorBlock(aMethod.Body);
                };
                emittedClass.Emit();
            }
        }


        // Variable value is loaded (usually to register RAX) or stored (as part of an assignment)
        public void VariableAccess(Expression.Variable variableExpr, Expression.Assignment? assignment = null)
        {
            var currentScope = variableExpr.GetScope();
            var symbol = GetSymbol(variableExpr.Name.Lexeme, currentScope!);
            string reg;

            if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
            {
                if (assignment != null)
                {
                    EmitExpression(assignment.RightOfEqualSign);
                    EmitConversionCompatibleType(assignment.RightOfEqualSign, assignment.LeftOfEqualSign.ExprType);
                    if (localVarSymbol!.DataType.IsReferenceType)
                    {
                        reg = emitter.Gather_CurrentStackframe();
                        emitter.AddReference(assignment.RightOfEqualSign);
                        cpu.FreeRegister(reg);
                    }
                    emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
                }
                else
                {
                    if (localVarSymbol.DataType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.LoadFunctionVariableFloat64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
                    else
                        emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
                }
            }
            else if (symbol is Scope.Symbol.FunctionParameterSymbol funcParSymbol)
            {
                if (assignment != null)
                {
                    EmitExpression(assignment.RightOfEqualSign);
                    emitter.StoreFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol), funcParSymbol.DataType);
                }
                else
                    emitter.LoadFunctionParameter64(emitter.AssemblyVariableName(funcParSymbol));
            }
            else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
            {
                if (assignment != null)
                {
                    var assemblyVarName = emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement);
                    if (parentSymbol.DataType.IsReferenceType)
                    {
                        reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                        emitter.LoadParentFunctionVariable64(assemblyVarName);
                        emitter.RemoveReference();
                        cpu.FreeRegister(reg);
                    }
                    EmitExpression(assignment.RightOfEqualSign);
                    reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                    if (parentSymbol.DataType.IsReferenceType)
                        emitter.AddReference(assignment.RightOfEqualSign);

                    emitter.StoreParentFunctionParameter64(assemblyVarName);
                    cpu.FreeRegister(reg);
                }
                else
                {
                    reg = emitter.Gather_LexicalParentStackframe(parentSymbol.LevelsDeep);
                    emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement));
                    cpu.FreeRegister(reg);
                }
            }
            else if (symbol is Scope.Symbol.FunctionSymbol funcSymbol)
            {
                emitter.LoadFunction(emitter.ConvertToAssemblyFunctionName(funcSymbol.Name));
            }
            else if (symbol is Scope.Symbol.HardcodedVariable hardcodedSymbol)
            {
                if (assignment != null)
                    EmitExpression(assignment.RightOfEqualSign);
                else
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
            }
            else if (symbol is Scope.Symbol.GroupSymbol groupSymbol)
            {
                Compiler.Error("Not implemented yet.");
            }
        }


        // Array value is loaded (usually to register RAX) or stored (as part of an assignment)
        public void ArrayAccess(Expression.ArrayAccess arrayExpr, Expression.Assignment? assignment = null, bool addressOf = false)
        {
            var currentScope = arrayExpr.GetScope();
            var symbol = GetSymbol(arrayExpr.GetMemberVariable()!.Name.Lexeme, currentScope!);
            var targetType = Datatype.Default;

            if (arrayExpr.Accessor != null)
            {
                var varSymbol = symbol as Scope.Symbol.VariableSymbol;
                string indexReg = cpu.GetTmpRegister();
                for (int i = 0; i < arrayExpr.Accessor.Count; i++)
                {
                    if (i > 0)
                        emitter.Push();  // save old index temp

                    var expr = arrayExpr.Accessor[i];
                    EmitExpression(expr);
                    UInt64 multiplier = 1;

                    if (i > 0)
                        for (int j = i - 1; j < (varSymbol!.DataType.ArrayNrs!.Count - 1); j++)
                            multiplier *= varSymbol.DataType.ArrayNrs[j];

                    if (multiplier > 1)
                    {
                        emitter.Push(expr);
                        emitter.LoadConstantUInt64(multiplier);
                        emitter.PopMul(expr);
                    }
                    if (i > 0)
                        emitter.PopAdd(expr);
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
                    emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol.TheScopeStatement));
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

                string baseReg = cpu.GetTmpRegister();
                emitter.MoveCurrentToRegister(baseReg);
                if (assignment != null)
                {
                    EmitExpression(assignment.RightOfEqualSign, targetType);
                    emitter.StoreCurrentInBasedIndex(elementSizeInBytes, baseReg, indexReg);
                }
                else
                {
                    if (addressOf)
                        emitter.LeaBasedIndex(elementSizeInBytes, baseReg, indexReg);
                    else
                        emitter.LoadBasedIndexToCurrent(elementSizeInBytes, baseReg, indexReg);
                }
                cpu.FreeRegister(baseReg);
                cpu.FreeRegister(indexReg);
            }
        }


        public void EmitConversionCompatibleType(Expression sourceExpr, Datatype destinationDatatype)
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

                sourceExpr.ExprType = destinationDatatype;
            }
            else if (destinationDatatype.Contains(Datatype.TypeEnum.FloatingPoint) && sourceDatatype.Contains(Datatype.TypeEnum.Integer))
            {
                emitter.IntegerToFloat();
                sourceExpr.ExprType = destinationDatatype;
            }
            else if (destinationDatatype.Contains(Datatype.TypeEnum.Integer) && sourceDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                emitter.FloatToInteger();
                sourceExpr.ExprType = destinationDatatype;
            }

        }


    }
}
