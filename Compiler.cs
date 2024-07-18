﻿using GroundCompiler.AstNodes;
using System;
using System.Collections.Generic;
using System.ComponentModel.Design;
using System.Globalization;
using System.Text;
using System.Xml.Linq;
using static GroundCompiler.AstNodes.Expression;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Datatype;
using static GroundCompiler.Scope;

namespace GroundCompiler
{
    public partial class Compiler : Statement.IVisitor<object?>, Expression.IVisitor<object?>
    {
        public CPU_X86_64 cpu;
        CodeEmitterX64 emitter;
        AstPrinter AstPrint = new AstPrinter();
        readonly string CodeTemplateName;

        public Compiler(string template) {
            CodeTemplateName = template;
            cpu = new CPU_X86_64();
            emitter = new CodeEmitterX64(cpu);
        }

        public string GenerateAssembly(Statement stmt)
        {
            // Gather the codeblocks
            EmitStatement(stmt);

            // Read the codetemplate
            string tmpl = File.ReadAllText($"..\\..\\..\\Templates\\{this.CodeTemplateName}.fasm");

            // Fill in the blocks in the template
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_EQUATES", string.Join("", emitter.GeneratedCode_Equates));
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_MAIN", string.Join("", emitter.GeneratedCode_Main) );
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_PROCEDURES", string.Join("", emitter.GeneratedCode_Procedures));
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_DATA", string.Join("", emitter.GeneratedCode_Data));
            return tmpl;
        }

        public void EmitStatement(Statement? stmt) { stmt?.Accept(this); }
        public void EmitExpression(Expression? expr) { expr?.Accept(this); }


        public object? VisitorProgramNode(ProgramNode prog)
        {
            var mainProc = new EmittedProcedure(functionStatement: prog, classStatement: null, emitter, "main");
            mainProc.MainCallback = () =>
            {
                emitter.EmitFixedStringIndexSpaceEntries(prog.Scope.GetRootScope().GetStringSymbols());
                VisitorBlock(prog.Body!);
                emitter.CloseGeneratedCode_Main();

                EmitFunctions(prog.Scope.GetFunctionStatements());
                EmitClasses(prog.Scope.GetClassSymbols());
                emitter.CloseGeneratedCode_Procedures();

                emitter.EmitLiteralFloats(prog.Scope.GetLiteralFloatSymbols());
                emitter.EmitStrings(prog.Scope.GetStringSymbols());
                emitter.CloseGeneratedCode_Data();
            };
            mainProc.EmitMain();
            return null;
        }


        public object? VisitorBlock(BlockStatement stmt)
        {
            foreach (AstNode node in stmt.Nodes)
                EmitStatement(node as Statement);

            // We rather do the emitting of the returnLabel in the EmitProcedure, but then the cleaning of
            // the references is already done. The returnLabel must precede the cleaning, else no cleaning is done when the returnLabel is used.
            if (stmt.Parent is FunctionStatement funcStatement)
            {
                if (funcStatement.Properties.ContainsKey("returnLabel"))
                {
                    var returnLabel = (string)funcStatement.Properties["returnLabel"]!;
                    emitter.InsertLabel(returnLabel);
                }
            }

            if (stmt.shouldCleanTmpDereferenced)
                emitter.CleanTmpDereferenced();

            if (stmt.shouldCleanDereferenced && stmt.Parent is Statement.FunctionStatement)    // When CleanDereferenced() is done on normal loop blocks, the variables belonging to the same scope outside the loop will be freed. That is not wanted.
                emitter.CleanDereferenced();

            return null;
        }


        public object? VisitorVariableDeclaration(VarStatement stmt)
        {
            PrintAst(stmt);

            var name = stmt.Name.Lexeme;
            var currentScope = stmt.GetScope();
            var symbol = GetSymbol(name, currentScope!);

            // all declared variables are local to something, so we only know LocalVariableSymbols
            if (symbol is Scope.Symbol.LocalVariableSymbol  localVarSymbol)
            {
                if (localVarSymbol.DataType.Types.Contains(TypeEnum.CustomClass))
                {
                    UInt64 nrBytesToAllocate = (UInt64)localVarSymbol.DataType.SizeInBytes;
                    emitter.Allocate(nrBytesToAllocate);
                    emitter.Make_IndexSpaceNr_Current();
                    emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);

                    var reg = emitter.Gather_CurrentStackframe();
                    emitter.AddTmpReference(stmt);
                    cpu.FreeRegister(reg);

                    reg = emitter.Gather_CurrentStackframe();
                    emitter.AddReference(stmt);
                    cpu.FreeRegister(reg);
                }

                if (stmt.Initializer != null)
                {
                    // shortcut. A special list validator must be made.
                    if (stmt.Initializer is Expression.List)
                        stmt.Initializer!.ExprType = localVarSymbol.DataType;

                    EmitExpression(stmt.Initializer);
                    EmitConversionCompatibleType(stmt.Initializer!, localVarSymbol.DataType);

                    if (stmt.Initializer!.ExprType.IsReferenceType)
                    {
                        var reg = emitter.Gather_CurrentStackframe();
                        emitter.AddReference(stmt.Initializer);
                        cpu.FreeRegister(reg);
                    }

                    var assemblyVarName = emitter.AssemblyVariableName(localVarSymbol, stmt.GetScope()?.Owner);
                    emitter.StoreFunctionVariable64(assemblyVarName, localVarSymbol.DataType);
                }
            }
            return null;
        }
        
        public object? VisitorClass(Statement.ClassStatement stmt) => null;  // We do not generate the classes at the place it is defined. Compiler>>EmitClasses emits the classes.
        public object? VisitorGroup(Statement.GroupStatement stmt) => null;
        public object? VisitorDll(Statement.DllStatement stmt) => null;

        public object? VisitorReturn(Statement.ReturnStatement stmt)
        {
            EmitExpression(stmt.Value);
            if (stmt.FindParentType(typeof(FunctionStatement)) is FunctionStatement  fStmt)
            {
                string returnLabel;
                if (fStmt.Properties.ContainsKey("returnLabel"))
                    returnLabel = (string)fStmt.Properties["returnLabel"]!;
                else
                {
                    returnLabel = emitter.NewLabel();
                    fStmt.Properties["returnLabel"] = returnLabel;
                }
                emitter.JumpToLabel(returnLabel);
            }
            return null;
        }


        public object? VisitorAssembly(Statement.AssemblyStatement stmt)
        {
            string literal = stmt.LiteralAsmCode.StringValue.Trim('\r', '\n');  // assembly is passed as-is, so the \r\n must be removed in front and after the code.
            if (stmt.LiteralAsmCode.Properties.ContainsKey("attributes"))
            {
                string attr = (string)stmt.LiteralAsmCode.Properties["attributes"]!;
                if (attr == "data")
                    emitter.GeneratedCode_Data.Add(literal + "\r\n");
                else if (attr == "procedures")
                    emitter.GeneratedCode_Procedures.Add(literal + "\r\n");
                else if (attr == "main")
                    emitter.GeneratedCode_Main.Add(literal + "\r\n");
                else if (attr == "equates")
                    emitter.GeneratedCode_Equates.Add(literal + "\r\n");
            }
            else
                emitter.Writeline(literal);

            return null;
        }


        public object? VisitorBreak(Statement.BreakStatement stmt)
        {
            var whileStmt = stmt.FindParentType(typeof(Statement.WhileStatement)) as Statement.WhileStatement;
            if (whileStmt != null)
                emitter.JumpToLabel((string)whileStmt.Properties["breakLabel"]!);

            return null;
        }


        public object? VisitorIf(IfStatement stmt)
        {
            PrintAst(stmt);
            EmitExpression(stmt.Condition);
            string elseLabel = emitter.NewLabel();
            string doneLabel = emitter.NewLabel();
            emitter.JumpToLabelIfFalse(elseLabel);
            EmitStatement(stmt.ThenBranch);
            emitter.JumpToLabel(doneLabel);
            emitter.InsertLabel(elseLabel);
            if (stmt.ElseBranch != null)
                EmitStatement(stmt.ElseBranch);

            emitter.InsertLabel(doneLabel);
            return null;
        }


        public object? VisitorWhile(WhileStatement whileStmt)
        {
            string testLabel = emitter.NewLabel();
            string doneLabel = emitter.NewLabel();
            whileStmt.Properties["breakLabel"] = doneLabel;
            emitter.InsertLabel(testLabel);
            EmitExpression(whileStmt.Condition);
            emitter.JumpToLabelIfFalse(doneLabel);
            EmitStatement(whileStmt.Body);
            emitter.JumpToLabel(testLabel);
            emitter.InsertLabel(doneLabel);
            return null;
        }


        public object? VisitorExpression(ExpressionStatement stmt)
        {
            EmitExpression(stmt.InnerExpression);
            return null;
        }


        public object? VisitorFunction(FunctionStatement stmt)
        {
            // We do not generate the functions at the place it is defined.
            // The EmitFunctions in this class does it.
            return null;
        }


        // Direction: Read
        public object? VisitorPoke(PokeStatement stmt)
        {
            EmitExpression(stmt.ValueExpression);
            emitter.StoreSystemVarsVariable(stmt.VariableName, stmt.SizeType.SizeInBytes);
            return null;
        }


        // Expression like: [ 1, 2, 3, 4 ].  Direction: Read
        public object? VisitorListExpr(Expression.List list)
        {
            // ExprType in list contains the result datatype.
            // We need to fill RAX with an reference to the list
            // Allocate the number of elements in the memory manager.
            if (!list.ExprType.Contains(Datatype.TypeEnum.Array))
                Error("VisitListExpr: List is no Array");

            int sizeEachElement = list.ExprType.Base!.SizeInBytes;
            UInt64 nrBytesToAllocate = list.ExprType.BytesToAllocate(); //  sizeEachElement * list.Elements.Count;
            emitter.Allocate(nrBytesToAllocate);
            emitter.PushAllocateIndexElement();
            string baseReg = cpu.GetRestoredRegister(list);
            emitter.MoveCurrentToRegister(baseReg);
            for (int i = 0; i < list.Elements.Count; i++)
            {
                Expression expr = list.Elements[i];
                if(list.ExprType.Contains(Datatype.TypeEnum.Array))
                    expr.ExprType = list.ExprType.Base;

                EmitExpression(expr);
                emitter.StoreCurrentInBasedIndex(sizeEachElement, baseReg, i, expr.ExprType);
            }
            cpu.FreeRegister(baseReg);
            emitter.PopAllocateIndexElement();  // Now we have the INDEXSPACE rownr of the list in RAX
            var reg = emitter.Gather_CurrentStackframe();
            emitter.AddTmpReference(list);
            cpu.FreeRegister(reg);
            return null;
        }


        // Array Access. Direction: Read
        public object? VisitorArrayAccessExpr(Expression.ArrayAccess expr)
        {
            ArrayAccess(expr);
            return null;
        }


        // Get a class property. Direction: Read.
        public object? VisitorGetExpr(Expression.Get expr)
        {
            var currentScope = expr.GetScope();
            var variableExpr = expr.Object as Expression.Variable;

            ClassStatement? classStatement = null;
            VarStatement? instVar = null;

            if (variableExpr!.Name.Lexeme == "g")
            {
                string theVariable = expr.Name.Lexeme;
                if (expr.Name.Contains(TokenType.Literal) && expr.Name.Datatype!.Contains(TypeEnum.String))
                    theVariable = theVariable.Substring(1, (theVariable.Length - 2));

                emitter.LoadHardcodedGroupVariable(theVariable);
                return null;
            }

            var variableSymbol = currentScope!.GetVariable(variableExpr!.Name.Lexeme);
            if (variableSymbol is Symbol.GroupSymbol groupSymbol)
            {
                var groupScope = groupSymbol.GroupStatement.GetScope();
                var groupVar = groupScope.GetVariable(expr.Name.Lexeme);
                if (groupVar is Symbol.HardcodedVariable hardCodedVar)
                {
                    string varName = emitter.AssemblyVariableNameForHardcodedGroupVariable(groupSymbol.Name, hardCodedVar.Name);
                    emitter.LoadHardcodedGroupVariable(varName);
                }
                return null;
            }
            else
            {
                classStatement = variableExpr!.ExprType.Properties["classStatement"] as ClassStatement;
                instVar = classStatement!.InstanceVariables.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
            }

            if (variableExpr.Name.Lexeme == "this")
            {
                var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }
            else
                VariableRead(variableExpr);

            emitter.GetMemoryPointerFromIndex();
            string instVarReg = cpu.GetTmpRegister();
            emitter.Codeline($"mov   {instVarReg}, rax");
            emitter.LoadInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);

            return null;
        }


        // Set a class property. Direction: Write.
        public object? VisitorSetExpr(Expression.Set expr)
        {
            var currentScope = expr.GetScope();
            EmitExpression(expr.Value);

            var variableExpr = expr.Object as Expression.Variable;

            if (expr.Name.Contains(TokenType.Literal))
            {
                string theLiteralVariable = expr.Name.Lexeme;
                if (expr.Name.Contains(TokenType.Literal) && expr.Name.Datatype!.Contains(TypeEnum.String))
                    theLiteralVariable = theLiteralVariable.Substring(1, (theLiteralVariable.Length - 2));

                emitter.StoreCurrent(theLiteralVariable);
                return null;
            }

            if (variableExpr?.Name.Lexeme == "g")
            {
                string theLiteralVariable = expr.Name.Lexeme;
                emitter.StoreCurrent($"[{theLiteralVariable}]");
                return null;
            }

            emitter.Push(expr.Value);
            var classStatement = variableExpr!.ExprType.Properties["classStatement"] as ClassStatement;
            var instVar = classStatement!.InstanceVariables.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
            
            string reg;
            if (instVar!.ResultType.IsReferenceType)
            {
                reg = emitter.Gather_CurrentStackframe();
                emitter.AddReference(expr.Value);
                cpu.FreeRegister(reg);
            }

            VariableRead(variableExpr);
            emitter.GetMemoryPointerFromIndex();
            string instVarReg = cpu.GetTmpRegister();
            emitter.StoreCurrent(instVarReg);
            emitter.Pop(expr.Value);
            EmitConversionCompatibleType(expr.Value, instVar.ResultType);

            emitter.StoreInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);

            return null;
        }


        // Variable. Direction: Write.
        public object? VisitorAssignmentExpr(Expression.Assignment assignment)
        {
            PrintAst(assignment);

            if (assignment.LeftOfEqualSign is Expression.Variable variableExpr)
                VariableAssignment(variableExpr, assignment);
            else if (assignment.LeftOfEqualSign is Expression.ArrayAccess arrayExpr)
                ArrayAccess(arrayExpr, assignment);
            else if (assignment.LeftOfEqualSign is Expression.Unary unaryExpr)
                UnaryAssignment(unaryExpr, assignment);

            return null;
        }


        // 1+1. Direction: Read.
        public object? VisitorBinaryExpr(Expression.Binary expr)
        {
            PrintAst(expr);

            EmitExpression(expr.Right);
            EmitConversionCompatibleType(expr.Right, expr.ExprType);

            emitter.Push(expr);

            EmitExpression(expr.Left);
            EmitConversionCompatibleType(expr.Left, expr.ExprType);

            switch (expr.Operator.Type)
            {
                case TokenType.Plus:
                    emitter.PopAdd(expr);
                    break;
                case TokenType.Minus:
                    emitter.PopSub(expr);
                    break;
                case TokenType.Asterisk:
                    emitter.PopMul(expr);
                    break;
                case TokenType.Slash:
                    emitter.PopDiv(expr);
                    break;
                case TokenType.Ampersand:
                    emitter.PopBitwiseAnd();
                    break;
                case TokenType.Modulo:
                case TokenType.Percentage:
                    emitter.PopModulo();
                    break;
                case TokenType.ArithmeticOr:
                    emitter.PopBitwiseOr();
                    break;
                case TokenType.Greater:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "ja");
                    else
                        emitter.PopGreaterToBoolean();
                    break;
                case TokenType.GreaterEqual:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "jae");
                    else
                        emitter.PopGreaterEqualToBoolean();
                    break;
                case TokenType.Less:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "jb");
                    else
                        emitter.PopLessToBoolean();
                    break;
                case TokenType.LessEqual:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "jbe");
                    else
                        emitter.PopLessEqualToBoolean();
                    break;
                case TokenType.IsEqual:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "je");
                    else
                    {
                        emitter.PopSub(expr);
                        emitter.LogicalNot();
                    }
                    break;
                case TokenType.NotIsEqual:
                    if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompare(expr, "jne");
                    else
                    {
                        emitter.PopSub(expr);
                        emitter.Logical();
                    }
                    break;
                case TokenType.LogicalOr:
                    emitter.PopOr();
                    break;
                case TokenType.LogicalAnd:
                    emitter.PopAnd();
                    break;
                case TokenType.ShiftLeft:
                    emitter.PopShiftLeft();
                    break;
                case TokenType.ShiftRight:
                    emitter.PopShiftRight();
                    break;
            }

            return null;
        }


        public object? VisitorFunctionCallExpr(Expression.FunctionCall expr)
        {
            // normally, the scope of the functioncall is used.
            var currentScope = expr.GetScope();
            var scope = currentScope;
            Scope.Symbol.FunctionSymbol? theFunction = null;

            string? instVarName = null;
            int levelsDeep = 0;

            if (expr.ExprType.Contains(Datatype.TypeEnum.CustomClass))
            {
                // It is a constructor for a class. Allocate memory for this new temporary class instance.
                UInt64 nrBytesToAllocate = (UInt64)expr.ExprType.SizeInBytes;
                emitter.Allocate(nrBytesToAllocate);
                string indexSpaceRegister = cpu.GetRestoredRegister(expr);
                emitter.RegisterMove("rcx", indexSpaceRegister);
                string memPtrRegister = cpu.GetRestoredRegister(expr);
                emitter.RegisterMove("rax", memPtrRegister);
                emitter.Make_IndexSpaceNr_Current();
                emitter.Push();  // push the indexspacenr of the allocated memory

                var reg = emitter.Gather_CurrentStackframe();
                emitter.AddTmpReference(expr);
                cpu.FreeRegister(reg);

                var funcNameVar = expr.FunctionName as Expression.Variable;
                var theClassSymbol = scope!.GetVariable(funcNameVar!.Name.Lexeme) as Symbol.ClassSymbol;
                int nrFunctionArg = expr.Arguments.Count;
                int nrClassInstVars = theClassSymbol!.ClassStatement.InstanceVariables.Count;
                for (int argNr = 0; argNr < nrClassInstVars; argNr++)
                {
                    Expression argExpr = expr.Arguments[argNr];
                    EmitExpression(argExpr);

                    var instVarStmt = theClassSymbol!.ClassStatement.InstanceVariables[argNr];
                    emitter.StoreInstanceVar($"{instVarStmt.Name.Lexeme}@{theClassSymbol!.ClassStatement.Name.Lexeme}", memPtrRegister, argExpr.ExprType);
                }
                emitter.Pop();  // pop the indexspacenr of the allocated memory
                cpu.FreeRegister(memPtrRegister);
                cpu.FreeRegister(indexSpaceRegister);
                return null;
            }

            if (expr.FunctionName is Expression.Variable functionNameVariable)
            {
                theFunction = scope!.GetFunctionAnywhere(functionNameVariable.Name.Lexeme);
                if (theFunction == null)
                    Compiler.Error($"VisitorFunctionCallExpr: {functionNameVariable!.Name.Lexeme} not found!");

                string name = functionNameVariable.Name.Lexeme;
                var needleScope = scope;
                while (!needleScope!.Contains(name))
                {
                    needleScope = needleScope.Parent;
                    levelsDeep++;
                }

                if (functionNameVariable.Name.Lexeme == "GC_CreateThread")
                {
                    string threadName = ((Expression.Variable)expr.Arguments[0]).Name.Lexeme;

                    // Total exception to the rule: Creating a Thread.
                    emitter.Codeline($"invoke kernel32_CreateThread, 0, 0x10000, _f_Generated_{threadName}_Startup, 0, 0, 0");
                    emitter.Codeline($"jmp   _f_Generated_{threadName}_AfterStartup");
                    emitter.Writeline($"_f_Generated_{threadName}_Startup:");
                    emitter.Codeline($"push  rbp");
                    emitter.Codeline($"mov   rax, [main_rbp]");
                    emitter.Codeline($"mov   rbp, rax");
                    emitter.Codeline($"push  rax");
                    emitter.Codeline($"push  qword 0");
                    emitter.Codeline($"call  _f_{threadName}");
                    emitter.Codeline($"mov   rcx, 0");
                    emitter.Codeline($"mov   rdx, 0");
                    emitter.Codeline($"sub   rsp, 0x20");
                    emitter.Codeline($"call  [kernel32_ExitThread]");
                    emitter.Codeline($"add   rsp, 0x20");
                    emitter.Writeline($"_f_Generated_{threadName}_AfterStartup:");
                    return null;
                }
            }

            Expression.Variable? instVar = null;

            // When we have an methodcall, we use the scope from the class
            if (expr.FunctionName is Expression.Get functionNameGet)
            {
                if (functionNameGet.Object is Expression.Variable functionNameVar)
                {
                    instVar = functionNameVar;

                    string funcName = functionNameVar.Name.Lexeme;
                    var theSymbol = scope!.GetVariableAnywhere(funcName);

                    if (theSymbol is Scope.Symbol.ParentScopeVariable parentSymbol)
                        levelsDeep = parentSymbol.LevelsDeep;

                    var theClass = theSymbol!.GetClassStatement();
                    if (theClass != null)
                    {
                        scope = theClass.GetScope();
                        if (theSymbol != null)
                            instVarName = theSymbol.Name;
                    }

                    var theGroupStmt = theSymbol!.GetGroupStatement();
                    if (theGroupStmt != null)
                        scope = theGroupStmt.GetScope();


                    string functionName = functionNameGet.Name.Lexeme;
                    theFunction = GetSymbol(functionName, scope!) as Scope.Symbol.FunctionSymbol;
                }
            }
            var dllFunctionSymbol = theFunction as Symbol.DllFunctionSymbol;

            int nrArguments = expr.Arguments.Count + 2;  // +2 for lexicalparentframe and "this", which is added the last
            if (nrArguments % 2 == 1)
            {
                if (dllFunctionSymbol == null || (expr.Arguments.Count > 4))
                {
                    emitter.Codeline("push  qword 0          ; Keep 16-byte stack alignment! (for win32)");
                    emitter.StackPush();
                }
            }

            List<FunctionParameter> fPars = theFunction!.FunctionStmt.Parameters;
            for (int i = (nrArguments-3); i >= 0; i--)
            {
                var arg = expr.Arguments[i];
                EmitExpression(arg);
                if (dllFunctionSymbol != null && arg.ExprType.IsReferenceType)
                    emitter.GetMemoryPointerFromIndex();

                FunctionParameter fPar = fPars[i];
                EmitConversionCompatibleType(arg, fPar.TheType);
                emitter.Push(arg);
            }

            bool pushLexicalParent = (dllFunctionSymbol == null);
            bool pushThis = (dllFunctionSymbol == null);

            if (pushLexicalParent)
            {
                // Add lexical parent frame. Position: [rbp+G_PARAMETER_LEXPARENT] // second parameter
                if (levelsDeep == 0)
                    emitter.Codeline("mov   rax, rbp");         // normal parent frame
                else
                {
                    int loopNr = levelsDeep - 1;
                    emitter.Codeline("mov   rax, [rbp+G_PARAMETER_LEXPARENT]");    // parameter 2, lexical parent
                    for (int i = 0; i < loopNr; i++)
                        emitter.Codeline("mov   rax, [rax]");
                }
                emitter.Push();
            }

            if (pushThis)
            {
                // Add "this" or null if there is no class instance. Position: [rbp+16] // first parameter
                if (instVarName != null && instVar != null)
                    VariableRead(instVar);
                else
                    emitter.LoadNull();

                emitter.Push();
            }

            if (dllFunctionSymbol != null)
            {
                nrArguments = expr.Arguments.Count;
                if (nrArguments > 0)
                {
                    InsertFastCallArgument(0, expr.Arguments[0]);
                    if (nrArguments > 1)
                        InsertFastCallArgument(1, expr.Arguments[1]);
                }
                if (nrArguments > 2)
                {
                    InsertFastCallArgument(2, expr.Arguments[2]);
                    if (nrArguments > 3)
                        InsertFastCallArgument(3, expr.Arguments[3]);
                }
                int stackToReserve = 32;
                if (!emitter.IsAlign16(emitter.StackPos - stackToReserve))
                    stackToReserve += 8;    // align the stack to 16 bytes
                string hexStackToReserve = stackToReserve.ToString("X");
                emitter.Codeline($"sub   rsp, {hexStackToReserve}h");
                emitter.StackSub(stackToReserve);
                string groupName = (string)dllFunctionSymbol.FunctionStmt.Properties["group"];
                string functionName = (string)dllFunctionSymbol.FunctionStmt.Name.Lexeme;
                emitter.Codeline($"call  [{groupName}_{functionName}]");
                emitter.Codeline($"add   rsp, {hexStackToReserve}h");
                emitter.StackAdd(stackToReserve);
                // If we have more than 4 parameters, than we need to free those stack parameters.
                if (nrArguments > 4)
                {
                    int extraToRelease = (((nrArguments - (4 + 1)) * 8) & 0xfff0) + 16;
                    emitter.Codeline($"add   rsp, {extraToRelease}");
                    emitter.StackPop(extraToRelease);
                }
            }
            else
                emitter.CallFunction(theFunction!, expr);

            return null;
        }


        private void InsertFastCallArgument(int index, Expression expr)
        {
            string theRegister = "rax";

            if (expr.ExprType.Contains(TypeEnum.FloatingPoint))
            {
                switch (index)
                {
                    case 0:
                        theRegister = "xmm0";
                        break;
                    case 1:
                        theRegister = "xmm1";
                        break;
                    case 2:
                        theRegister = "xmm2";
                        break;
                    case 3:
                        theRegister = "xmm3";
                        break;
                }
                cpu.ReserveRegister(theRegister);
                emitter.Pop(expr, theRegister);
                cpu.FreeRegister(theRegister);
            }
            else
            {
                switch (index)
                {
                    case 0:
                        theRegister = "rcx";
                        break;
                    case 1:
                        theRegister = "rdx";
                        break;
                    case 2:
                        theRegister = "r8";
                        break;
                    case 3:
                        theRegister = "r9";
                        break;
                }
                cpu.ReserveRegister("rcx");
                emitter.Pop(expr, theRegister);
                cpu.FreeRegister("rcx");
            }
        }


        public object? VisitorGroupingExpr(Expression.Grouping expr)
        {
            EmitExpression(expr.Expression);
            return null;
        }


        public object? VisitorLiteralExpr(Expression.Literal expr)
        {
            if (expr.Value == null)
            {
                emitter.LoadNull();
                return null;
            }

            if (expr.ExprType.Name == "string")
            {
                var strConstant = expr.GetRootScope()?.GetString((string)expr.Value);
                if (strConstant != null)
                    emitter.LoadConstantString(strConstant.IndexspaceRownr);
            }
            else if (expr.ExprType.Contains(Datatype.TypeEnum.Integer))
            {
                emitter.LoadConstant64(Convert.ToInt64(expr.Value));
            }
            else if (expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                string id = expr.GetScope()!.IdFor(Convert.ToString(expr.Value, CultureInfo.InvariantCulture)!, "const float");
                emitter.LoadConstantFloat64(id);
            }
            else if (expr.ExprType.Contains(Datatype.TypeEnum.Boolean))
            {
                emitter.LoadBoolean((bool)expr.Value);
            }

            return null;
        }


        public object? VisitorLogicalExpr(Expression.Logical expr)
        {
            return null;
        }


        // Unary, like -a, !a, a++, &a or *a. Direction: Read/Write.
        public object? VisitorUnaryExpr(Expression.Unary expr)
        {
            // &a , &p[0]
            if (expr.Operator.Contains(TokenType.Ampersand))
            {
                if (expr.Right is Expression.Variable theVariable)
                    VariableAddressOf(theVariable);
                else if (expr.Right is Expression.ArrayAccess arrayAccess)
                    ArrayAccess(arrayAccess, assignment: null, addressOf: true);
                else
                    Compiler.Error("AddressOf can only be done on a variable.");
                return null;
            }

            // a++ , a--
            if (expr.Postfix && (expr.Operator.Contains(TokenType.PlusPlus) || expr.Operator.Contains(TokenType.MinusMinus)))
            {
                if (expr.Right is Expression.Variable theVariable)
                {
                    VariableRead(theVariable);
                    emitter.Push();
                    if (expr.Operator.Contains(TokenType.PlusPlus))
                        emitter.IncrementCurrent();
                    if (expr.Operator.Contains(TokenType.MinusMinus))
                        emitter.DecrementCurrent();
                    VariableWrite(theVariable);
                    emitter.Pop();
                } else
                    Compiler.Error("a++ or a-- can only be done on a variable.");
                return null;
            }

            Datatype exprDatatype = Datatype.Default;

            if (expr.Right is Expression.Grouping groupStmt)
            {
                EmitExpression(expr.Right);
                exprDatatype = groupStmt.ExprType;
            } else if (expr.Right is Expression.Variable theVariable)
            {
                VariableRead(theVariable);
                exprDatatype = theVariable.ExprType;
            } else
                EmitExpression(expr.Right);

            // -a
            if ((exprDatatype.Contains(TypeEnum.Integer) || exprDatatype.Contains(TypeEnum.FloatingPoint)) && expr.Operator.Contains(TokenType.Minus) && !expr.Postfix)
            {
                emitter.Negation(expr.Right);
                return null;
            }

            // !a
            if (expr.Operator.Contains(TokenType.Not))
            {
                emitter.LogicalNot();
                return null;
            }

            // *a  (a = int*)
            if (exprDatatype.Contains(TypeEnum.Pointer) && expr.Operator.Contains(TokenType.Asterisk))
            {
                emitter.LoadPointingTo(exprDatatype.Base!);
                return null;
            }

            // *a  (a = ptr)
            if (exprDatatype.Contains(TypeEnum.Integer) && expr.Operator.Contains(TokenType.Asterisk))
            {
                emitter.LoadPointingTo(exprDatatype);
                return null;
            }

            return null;
        }


        // Variable. Direction: Read
        public object? VisitorVariableExpr(Expression.Variable variableExpr)
        {
            VariableRead(variableExpr);
            return null;
        }


    }
}
