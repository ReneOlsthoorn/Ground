using GroundCompiler.AstNodes;
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


        public Compiler(bool generateGuiApplication) {
            cpu = new CPU_X86_64();
            emitter = new CodeEmitterX64(cpu, generateGuiApplication);
        }

        public string GenerateAssembly(Statement stmt)
        {
            EmitStatement(stmt);
            return emitter.GetGeneratedCode();
        }

        public void EmitStatement(Statement? stmt) { stmt?.Accept(this); }
        public void EmitExpression(Expression? expr) { expr?.Accept(this); }



        public object? VisitorProgramNode(ProgramNode prog)
        {
            emitter.BeforeMainCode();
            var mainProc = new EmittedProcedure(prog, emitter, "main");
            mainProc.MainCallback = () =>
            {
                emitter.EmitFixedStringIndexSpaceEntries(prog.Scope.GetRootScope().GetStringSymbols());
                VisitorBlock(prog.Body);
                emitter.AfterMainCode();
                EmitFunctions(prog.Scope.GetFunctionSymbols());
                EmitClasses(prog.Scope.GetClassSymbols());
                emitter.AfterFunctions();
                emitter.EmitLiteralFloats(prog.Scope.GetLiteralFloatSymbols());
                emitter.EmitStrings(prog.Scope.GetStringSymbols());
            };
            mainProc.Emit();
            return null;
        }


        public object? VisitorBlock(BlockStatement stmt)
        {
            foreach (AstNode node in stmt.Nodes)
                EmitStatement(node as Statement);

            if (stmt.shouldCleanTmpDereferenced)
                emitter.CleanTmpDereferenced();

            if (stmt.shouldCleanDereferenced)
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


        public object? VisitorClass(Statement.ClassStatement stmt)
        {
            // We do not generate the classes at the place it is defined.
            // Compiler>>EmitClasses emits the classes.
            return null;
        }


        public object? VisitorGroup(Statement.GroupStatement stmt)
        {
            return null;
        }


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
            emitter.Writeline(stmt.LiteralAsmCode.StringValue.Trim('\r','\n'));     // assembly is passed as-is, so the \r\n must be removed in front and after the code.
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
            string baseReg = cpu.GetTmpRegister();
            emitter.MoveCurrentToRegister(baseReg);
            for (int i = 0; i < list.Elements.Count; i++)
            {
                Expression expr = list.Elements[i];
                if(list.ExprType.Contains(Datatype.TypeEnum.Array))
                    expr.ExprType = list.ExprType.Base;

                EmitExpression(expr);
                emitter.StoreCurrentInBasedIndex(sizeEachElement, baseReg, i);
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
            var classStatement = variableExpr.ExprType.Properties["classStatement"] as ClassStatement;
            var instVar = classStatement.InstanceVariables.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);

            string varName = variableExpr.Name.Lexeme + "." + instVar.Name.Lexeme;

            if (instVar.ResultType.Contains(Datatype.TypeEnum.FloatingPoint))
                emitter.LoadFunctionVariableFloat64(emitter.AssemblyVariableName(varName, currentScope?.Owner));
            else
                emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(varName, currentScope?.Owner));

            //
            return null;
        }


        // Set a class property. Direction: Write.
        public object? VisitorSetExpr(Expression.Set expr)
        {
            var currentScope = expr.GetScope();
            EmitExpression(expr.Value);

            var variableExpr = expr.Object as Expression.Variable;
            var classStatement = variableExpr.ExprType.Properties["classStatement"] as ClassStatement;
            var instVar = classStatement.InstanceVariables.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
            
            string reg;
            if (instVar!.ResultType.IsReferenceType)
            {
                reg = emitter.Gather_CurrentStackframe();
                emitter.AddReference(expr.Value);
                cpu.FreeRegister(reg);
            }
            string varName = variableExpr.Name.Lexeme + "." + instVar.Name.Lexeme;
            emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(varName, currentScope?.Owner), instVar.ResultType);

            return null;
        }


        // Variable. Direction: Write.
        public object? VisitorAssignmentExpr(Expression.Assignment assignment)
        {
            PrintAst(assignment);

            if (assignment.LeftOfEqualSign is Expression.Variable variableExpr)
                VariableAccess(variableExpr, assignment);
            else if (assignment.LeftOfEqualSign is Expression.ArrayAccess arrayExpr)
                ArrayAccess(arrayExpr, assignment);

            //else if (assignment.LeftOfEqualSign is Expression.Get getExpr)

            return null;
        }


        // 1+1. Direction: Read.
        public object? VisitorBinaryExpr(Expression.Binary expr)
        {
            PrintAst(expr);

            EmitExpression(expr.Left);
            EmitConversionCompatibleType(expr.Left, expr.ExprType);

            emitter.Push(expr);

            EmitExpression(expr.Right);
            EmitConversionCompatibleType(expr.Right, expr.ExprType);

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
                    emitter.PopDiv();
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
                    emitter.PopGreaterToBoolean();
                    break;
                case TokenType.GreaterEqual:
                    emitter.PopGreaterEqualToBoolean();
                    break;
                case TokenType.Less:
                    emitter.PopLessToBoolean();
                    break;
                case TokenType.LessEqual:
                    emitter.PopLessEqualToBoolean();
                    break;
                case TokenType.IsEqual:
                    emitter.PopSub();
                    emitter.LogicalNot();
                    break;
                case TokenType.NotIsEqual:
                    emitter.PopSub();
                    emitter.Logical();
                    break;
                case TokenType.LogicalOr:
                    emitter.PopOr();
                    break;
                case TokenType.LogicalAnd:
                    emitter.PopAnd();
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
            string instVarName = null;
            int levelsDeep = 0;

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
            }

            // When we have an methodcall, we use the scope from the class
            if (expr.FunctionName is Expression.Get functionNameGet)
            {
                if (functionNameGet.Object is Expression.Variable functionNameVar)
                {
                    string funcName = functionNameVar.Name.Lexeme;
                    var theSymbol = scope.GetVariable(funcName);

                    var theClass = theSymbol.GetClassStatement();
                    if (theClass != null)
                    {
                        scope = theClass.GetScope();
                        if (theSymbol != null)
                            instVarName = theSymbol.Name;
                    }

                    var theGroupStmt = theSymbol.GetGroupStatement();
                    if (theGroupStmt != null)
                        scope = theGroupStmt.GetScope();


                    string functionName = functionNameGet.Name.Lexeme;
                    theFunction = GetSymbol(functionName, scope!) as Scope.Symbol.FunctionSymbol;
                }
            }

            int nrArguments = expr.Arguments.Count + 2;  // +2 for lexicalparentframe and "this", which is added the last
            if (nrArguments % 2 == 1)
                emitter.Codeline("push  qword 0          ; Keep 16-byte stack alignment! (for win32)");

            List<FunctionParameter> fPars = theFunction!.FunctionStatement.Parameters;
            int needle = 0;
            foreach (var arg in expr.Arguments)
            {
                EmitExpression(arg);
                FunctionParameter fPar = fPars[needle];
                EmitConversionCompatibleType(arg, fPar.TheType);
                emitter.Push();
                needle++;
            }

            // Add lexical parent frame. Position: [rbp+24] // second parameter
            if (levelsDeep == 0)
                emitter.Codeline("mov   rax, rbp");         // normal parent frame
            else { 
                int loopNr = levelsDeep - 1;
                emitter.Codeline("mov   rax, [rbp+24]");    // parameter 2, lexical parent
                for (int i = 0; i < loopNr; i++)
                    emitter.Codeline("mov   rax, [rax]");
            }
            emitter.Push();

            // Add "this" or null if there is no class instance. Position: [rbp+16] // first parameter
            if (instVarName != null)
                emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(instVarName, currentScope?.Owner));
            else
                emitter.LoadNull();
            emitter.Push();

            emitter.CallFunction(theFunction!, expr);
            return null;
        }


        public object? VisitorGroupingExpr(Expression.Grouping expr)
        {
            expr.Expression.Accept(this);
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


        // Unary, like !a or a++  Direction: Read/Write.
        public object? VisitorUnaryExpr(Expression.Unary expr)
        {
            if (expr.Right is Expression.Variable  theVariable)
            {
                var currentScope = expr.GetScope();
                var symbol = GetSymbol(theVariable.Name.Lexeme, currentScope!);

                if (symbol is Scope.Symbol.LocalVariableSymbol localVarSymbol)
                {
                    if (localVarSymbol.DataType.Contains(TypeEnum.Integer) && expr.Postfix)
                    {
                        emitter.LoadFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner));
                        emitter.Push();
                        if (expr.Operator.Contains(TokenType.PlusPlus))
                            emitter.IncrementCurrent();
                        if (expr.Operator.Contains(TokenType.MinusMinus))
                            emitter.DecrementCurrent();
                        emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
                        emitter.Pop();
                    }
                }
                else if (symbol is Scope.Symbol.ParentScopeVariable parentSymbol)
                {
                    if (parentSymbol.DataType.Contains(TypeEnum.Integer) && expr.Postfix)
                    {
                        var reg = emitter.Gather_ParentStackframe(parentSymbol.LevelsDeep);
                        emitter.LoadParentFunctionVariable64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement));
                        emitter.Push();
                        if (expr.Operator.Contains(TokenType.PlusPlus))
                            emitter.IncrementCurrent();
                        if (expr.Operator.Contains(TokenType.MinusMinus))
                            emitter.DecrementCurrent();
                        emitter.StoreParentFunctionParameter64(emitter.AssemblyVariableName(symbol.Name, parentSymbol!.TheScopeStatement));
                        emitter.Pop();
                        cpu.FreeRegister(reg);
                    }
                }

            } else if (expr.Operator.Contains(TokenType.Not))
            {
                expr.Right.Accept(this);
                emitter.LogicalNot();
            }

            return null;
        }


        // Variable. Direction: Read
        public object? VisitorVariableExpr(Expression.Variable variableExpr)
        {
            VariableAccess(variableExpr);
            return null;
        }


    }
}
