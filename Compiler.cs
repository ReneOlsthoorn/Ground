using System.Globalization;
using System.Text;
using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public partial class Compiler : Statement.IVisitor<object?>, Expression.IVisitor<object?>
    {
        public CPU_X86_64 cpu;
        CodeEmitter emitter;
        AstPrinter AstPrint = new AstPrinter();
        readonly string CodeTemplateName;
        CompilationSession session;

        public Compiler(CompilationSession session) {
            this.session = session;
            CodeTemplateName = session.PreProcessor.Template;
            cpu = new CPU_X86_64();
            emitter = new CodeEmitter(cpu, session.PreProcessor.Defines);
        }

        public string LibrariesToInclude()
        {
            StringBuilder result = new StringBuilder();
            foreach (var (libraryName, dllFilename) in session.PreProcessor.Libraries)
                result.AppendLine($"          {libraryName}, '{dllFilename}', \\");
            return result.ToString();
        }

        public string LibraryApiIncludes()
        {
            StringBuilder result = new StringBuilder();
            foreach (var (libraryName, dllFilename) in session.PreProcessor.Libraries)
                result.AppendLine($"  include 'Include\\{libraryName}_api.inc'");
            return result.ToString();
        }


        public string GenerateAssembly(Statement stmt)
        {
            // Gather the codeblocks
            EmitStatement(stmt);

            // Read the codetemplate
            string tmpl = File.ReadAllText($"Templates\\{this.CodeTemplateName}.fasm");

            // Fill in the blocks in the template
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_EQUATES", string.Join("", emitter.GeneratedCode_Equates));
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_MAIN", string.Join("", emitter.GeneratedCode_Main) );
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_PROCEDURES", string.Join("", emitter.GeneratedCode_Procedures));
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_DATA", string.Join("", emitter.GeneratedCode_Data));
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_LIBRARIES\r\n", LibrariesToInclude());
            tmpl = tmpl.Replace(";GC_INSERTIONPOINT_LIBRARY_API_INCLUDES\r\n", LibraryApiIncludes());
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
                VisitorBlock(prog.BodyNode!);
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

            if (stmt.shouldCleanDereferenced && stmt.Parent is FunctionStatement)    // When CleanDereferenced() is done on normal loop blocks, the variables belonging to the same scope outside the loop will be freed. That is not wanted.
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
            if (symbol is LocalVariableSymbol  localVarSymbol)
            {
                if (localVarSymbol.DataType.Types.Contains(Datatype.TypeEnum.CustomClass))
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

                if (stmt.InitializerNode != null)
                {
                    // shortcut. A special list validator must be made.
                    if (stmt.InitializerNode is Expressions.List)
                        stmt.InitializerNode!.ExprType = localVarSymbol.DataType;

                    EmitExpression(stmt.InitializerNode);
                    EmitConversionCompatibleType(stmt.InitializerNode!, localVarSymbol.DataType);

                    if (stmt.InitializerNode!.ExprType.IsReferenceType)
                    {
                        if (!IsUnaryAddressOf(stmt.InitializerNode!)) {
                            var reg = emitter.Gather_CurrentStackframe();
                            emitter.AddReference(stmt.InitializerNode);
                            cpu.FreeRegister(reg);
                        }
                    }

                    var assemblyVarName = emitter.AssemblyVariableName(localVarSymbol, stmt.GetScope()?.Owner);
                    emitter.StoreFunctionVariable64(assemblyVarName, localVarSymbol.DataType);
                }
            }
            return null;
        }
        

        public object? VisitorReturn(ReturnStatement stmt)
        {
            if (stmt.ReturnValueNode is ThisExpression thisExpr)
            {
                emitter.Codeline("mov   rax, [rbp+G_PARAMETER_THIS]");
            } else
                EmitExpression(stmt.ReturnValueNode);

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


        public object? VisitorAssembly(AssemblyStatement stmt)
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


        public object? VisitorBreak(BreakStatement stmt)
        {
            var whileStmt = stmt.FindParentType(typeof(WhileStatement)) as WhileStatement;
            if (whileStmt != null)
                emitter.JumpToLabel((string)whileStmt.Properties["breakLabel"]!);

            return null;
        }

        public object? VisitorContinue(ContinueStatement stmt)
        {
            var whileStmt = stmt.FindParentType(typeof(WhileStatement)) as WhileStatement;
            if (whileStmt != null)
                emitter.JumpToLabel((string)whileStmt.Properties["continueLabel"]!);

            return null;
        }

        public object? VisitorIf(IfStatement stmt)
        {
            PrintAst(stmt);
            EmitExpression(stmt.ConditionNode);
            string elseLabel = emitter.NewLabel();
            string doneLabel = emitter.NewLabel();
            emitter.JumpToLabelIfFalse(elseLabel);
            EmitStatement(stmt.ThenBranchNode);
            emitter.JumpToLabel(doneLabel);
            emitter.InsertLabel(elseLabel);
            if (stmt.ElseBranchNode != null)
                EmitStatement(stmt.ElseBranchNode);

            emitter.InsertLabel(doneLabel);
            return null;
        }


        public object? VisitorWhile(WhileStatement whileStmt)
        {
            string testLabel = emitter.NewLabel();
            string doneLabel = emitter.NewLabel();
            whileStmt.Properties["breakLabel"] = doneLabel;
            string? continueLabel = null;
            if (whileStmt.IncrementNode != null)
            {
                continueLabel = emitter.NewLabel();
                whileStmt.Properties["continueLabel"] = continueLabel;
            }
            emitter.InsertLabel(testLabel);
            EmitExpression(whileStmt.ConditionNode);
            emitter.JumpToLabelIfFalse(doneLabel);
            EmitStatement(whileStmt.BodyNode);
            if (whileStmt.IncrementNode != null)
            {
                if (continueLabel != null)
                    emitter.InsertLabel(continueLabel);
                EmitStatement(whileStmt.IncrementNode);
            }
            emitter.JumpToLabel(testLabel);
            emitter.InsertLabel(doneLabel);
            return null;
        }


        public object? VisitorExpression(ExpressionStatement stmt)
        {
            EmitExpression(stmt.ExpressionNode);
            return null;
        }


        // Direction: Read
        public object? VisitorPoke(PokeStatement stmt)
        {
            EmitExpression(stmt.ValueExpressionNode);
            emitter.StoreSystemVarsVariable(stmt.VariableName, stmt.SizeType.SizeInBytes);
            return null;
        }


        // Expression like: [ 1, 2, 3, 4 ].  Direction: Read
        public object? VisitorList(Expressions.List list)
        {
            // ExprType in list contains the result datatype.
            // We need to fill RAX with an reference to the list
            // Allocate the number of elements in the memory manager.
            if (!list.ExprType.Contains(Datatype.TypeEnum.Array))
                Error("VisitListExpr: List is no Array");

            int sizeEachElement = list.ExprType.Base!.SizeInBytes;
            UInt64 nrBytesToAllocate = list.SizeInBytes();
            emitter.Allocate(nrBytesToAllocate);
            emitter.PushAllocateIndexElement();
            string baseReg = cpu.GetRestoredRegister(list);
            emitter.MoveCurrentToRegister(baseReg);
            for (int i = 0; i < list.ElementsNodes.Count; i++)
            {
                Expression expr = list.ElementsNodes[i];
                if (list.ExprType.Contains(Datatype.TypeEnum.Array))
                {
                    expr.Properties["old ExprType"] = expr.ExprType;
                    expr.ExprType = list.ExprType.Base;
                }

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
        public object? VisitorArrayAccess(ArrayAccess expr)
        {
            ArrayAccess(expr);
            return null;
        }


        // Get a class property. Direction: Read.
        public object? VisitorPropertyGet(PropertyExpression expr)
        {
            var objectNodeAsVariable = expr.ObjectNode as Variable;
            var objectNodeAsArray = expr.ObjectNode as ArrayAccess;
            var objectNodeAsThis = expr.ObjectNode as ThisExpression;

            var currentScope = expr.GetScope();

            ClassStatement? classStatement = null;
            VarStatement? instVar = null;

            if (objectNodeAsVariable != null)
            {
                if (objectNodeAsVariable?.Name.Lexeme == "g")
                {
                    string theVariable = expr.Name.Lexeme;
                    if (expr.Name.Contains(TokenType.Literal) && expr.Name.Datatype!.Contains(Datatype.TypeEnum.String))
                        theVariable = theVariable.Substring(1, (theVariable.Length - 2));

                    emitter.LoadHardcodedGroupVariable(theVariable);
                    return null;
                }

                var variableSymbol = currentScope!.GetVariable(objectNodeAsVariable!.Name.Lexeme);
                if (variableSymbol is GroupSymbol groupSymbol)
                {
                    var groupScope = groupSymbol.GroupStatement.GetScope();
                    var groupVar = groupScope.GetVariable(expr.Name.Lexeme);
                    if (groupVar is HardcodedVariable hardCodedVar)
                    {
                        string varName = emitter.AssemblyVariableNameForHardcodedGroupVariable(groupSymbol.Name, hardCodedVar.Name);
                        emitter.LoadHardcodedGroupVariable(varName);
                    }
                    return null;
                }

                // Is there a pointer?
                // A pointer is a special. It will not use the indexed memory, but direct memory.
                if (Datatype.IsPointerType(expr.ObjectNode.ExprType))
                {
                    classStatement = expr.ObjectNode.ExprType.Base.Properties["classStatement"] as ClassStatement;
                    instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
                }
                else
                {
                    classStatement = expr.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                    instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);

                    VariableRead(objectNodeAsVariable);
                    emitter.GetMemoryPointerFromIndex();
                }
            }

            if (objectNodeAsThis != null)
            {
                classStatement = expr.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);

                var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }

            if (objectNodeAsArray != null)
            {
                ArrayAccess(objectNodeAsArray!, addressOf: true);

                classStatement = expr.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
            }

            string instVarReg = cpu.GetTmpRegister();
            emitter.Codeline($"mov   {instVarReg}, rax");
            emitter.LoadInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);

            return null;
        }


        // Set a class property. Direction: Write.
        public object? VisitorPropertySet(PropertySet expr)
        {
            var currentScope = expr.GetScope();

            var objectNodeAsVariable = expr.ObjectNode as Variable;
            var objectNodeAsArray = expr.ObjectNode as ArrayAccess;
            var objectNodeAsThis = expr.ObjectNode as ThisExpression;

            ClassStatement? classStatement = null;
            if (Datatype.IsPointerType(expr.ObjectNode.ExprType))
            {
                // Als er een pointer binnenkomt, dan gaan we ervan uit dat de value al emitted is.
                classStatement = expr.ObjectNode.ExprType.Base.Properties["classStatement"] as ClassStatement;
            }
            else
            {
                if (expr.ValueNode != null)
                {
                    EmitExpression(expr.ValueNode);

                    if (expr.Name.Contains(TokenType.Literal))
                    {
                        string theLiteralVariable = expr.Name.Lexeme;
                        if (expr.Name.Contains(TokenType.Literal) && expr.Name.Datatype!.Contains(Datatype.TypeEnum.String))
                            theLiteralVariable = theLiteralVariable.Substring(1, (theLiteralVariable.Length - 2));

                        emitter.StoreCurrent(theLiteralVariable);
                        return null;
                    }

                    if (objectNodeAsVariable?.Name.Lexeme == "g")
                    {
                        string theLiteralVariable = expr.Name.Lexeme;
                        emitter.StoreCurrent($"[{theLiteralVariable}]");
                        return null;
                    }

                    emitter.Push(expr.ValueNode.ExprType);
                }
                classStatement = expr.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
            }

            var instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == expr.Name.Lexeme);
            
            string reg;
            if (instVar!.ResultType.IsReferenceType)
            {
                reg = emitter.Gather_CurrentStackframe();
                emitter.AddReference(expr.ValueNode);
                cpu.FreeRegister(reg);
            }

            if (objectNodeAsVariable != null)
            {
                VariableRead(objectNodeAsVariable);
                if (!Datatype.IsPointerType(expr.ObjectNode.ExprType))
                    emitter.GetMemoryPointerFromIndex();
            }

            if (objectNodeAsThis != null)
            {
                var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }

            if (objectNodeAsArray != null)
                ArrayAccess(objectNodeAsArray!, addressOf: true);

            string instVarReg = cpu.GetTmpRegister();
            emitter.StoreCurrent(instVarReg);
            emitter.Pop(expr.ValueNode);
            if (expr.ValueNode != null)
                EmitConversionCompatibleType(expr.ValueNode, instVar.ResultType);

            emitter.StoreInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);

            return null;
        }


        // Variable. Direction: Write.
        public object? VisitorAssignment(Assignment assignment)
        {
            PrintAst(assignment);

            if (assignment.LeftOfEqualSignNode is Variable variableExpr)
                VariableAssignment(variableExpr, assignment);
            else if (assignment.LeftOfEqualSignNode is ArrayAccess arrayExpr)
                ArrayAccess(arrayExpr, assignment);
            else if (assignment.LeftOfEqualSignNode is Unary unaryExpr)
                UnaryAssignment(unaryExpr, assignment);

            return null;
        }


        // 1+1. Direction: Read.
        public object? VisitorBinary(Binary expr)
        {
            PrintAst(expr);

            var conversionDatatype = expr.DetermineConversionDatatype();

            EmitExpression(expr.RightNode);
            EmitConversionCompatibleType(expr.RightNode, conversionDatatype);
            emitter.Push(conversionDatatype);

            EmitExpression(expr.LeftNode);
            EmitConversionCompatibleType(expr.LeftNode, conversionDatatype);

            switch (expr.Operator.Type)
            {
                case TokenType.Plus:
                    emitter.PopAdd(expr, conversionDatatype);
                    break;
                case TokenType.Minus:
                    emitter.PopSub(expr, conversionDatatype);
                    break;
                case TokenType.Asterisk:
                    emitter.PopMul(expr, conversionDatatype);
                    break;
                case TokenType.Slash:
                    emitter.PopDiv(expr, conversionDatatype);
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
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("ja", conversionDatatype);
                    else
                        emitter.PopGreaterToBoolean();
                    break;
                case TokenType.GreaterEqual:
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("jae", conversionDatatype);
                    else
                        emitter.PopGreaterEqualToBoolean();
                    break;
                case TokenType.Less:
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("jb", conversionDatatype);
                    else
                        emitter.PopLessToBoolean();
                    break;
                case TokenType.LessEqual:
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("jbe", conversionDatatype);
                    else
                        emitter.PopLessEqualToBoolean();
                    break;
                case TokenType.IsEqual:
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("je", conversionDatatype);
                    else
                    {
                        emitter.PopSub(expr, conversionDatatype);
                        emitter.LogicalNot();
                    }
                    break;
                case TokenType.NotIsEqual:
                    if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                        emitter.PopCompareFloat("jne", conversionDatatype);
                    else
                    {
                        emitter.PopSub(expr, conversionDatatype);
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


        // This function needs refactoring. It does too much. We must push it over and create a class for it.
        public object? VisitorFunctionCall(FunctionCall expr)
        {
            ClassStatement? classStatement = null;

            // normally, the scope of the functioncall is used.
            var currentScope = expr.GetScope();
            var scope = currentScope;
            FunctionSymbol? theFunction = null;

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

                var funcNameVar = expr.FunctionNameNode as Variable;
                var symbol = GetSymbol(funcNameVar!.Name.Lexeme, scope!);
                var theClassSymbol = symbol as ClassSymbol;

                //GetVariableAnywhere
                int nrFunctionArg = expr.ArgumentNodes.Count;
                int nrClassInstVars = theClassSymbol!.ClassStatement.InstanceVariableNodes.Count;
                for (int argNr = 0; argNr < nrClassInstVars; argNr++)
                {
                    Expression argExpr = expr.ArgumentNodes[argNr];
                    EmitExpression(argExpr);
                    var instVarStmt = theClassSymbol!.ClassStatement.InstanceVariableNodes[argNr];
                    EmitConversionCompatibleType(argExpr, instVarStmt.ResultType);
                    emitter.StoreInstanceVar($"{instVarStmt.Name.Lexeme}@{theClassSymbol!.ClassStatement.Name.Lexeme}", memPtrRegister, argExpr.ExprType);
                }
                emitter.Pop();  // pop the indexspacenr of the allocated memory
                cpu.FreeRegister(memPtrRegister);
                cpu.FreeRegister(indexSpaceRegister);
                return null;
            }

            if (expr.FunctionNameNode is Variable functionNameVariable)
            {
                theFunction = scope!.GetFunctionAnywhere(functionNameVariable.Name.Lexeme);
                if (theFunction == null)
                    Compiler.Error($"VisitorFunctionCallExpr: {functionNameVariable!.Name.Lexeme} not found!");

                string name = functionNameVariable.Name.Lexeme;
                var needleScope = scope;
                IScopeStatement? ownerScope = needleScope.Owner;
                while (!needleScope.Contains(name))
                {
                    if (!(ownerScope is ClassStatement || ownerScope is GroupStatement || ownerScope is ProgramNode))   // Dit zijn niet echte calling scopes.
                        levelsDeep++;

                    needleScope = needleScope.Parent;
                    if (needleScope == null)
                        break;

                    ownerScope = needleScope.Owner;
                }

                if (functionNameVariable.Name.Lexeme == "GC_CreateThread")
                {
                    string threadName = ((Variable)expr.ArgumentNodes[0]).Name.Lexeme;

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

                if (functionNameVariable.Name.Lexeme == "zero")
                {
                    var arg = expr.ArgumentNodes[0];
                    if (arg is Variable theZeroVar)
                    {
                        long sizeToClean = 0;
                        if (expr.ArgumentNodes.Count == 1)
                            sizeToClean = theZeroVar.ExprType.SizeInBytes;
                        else if (expr.ArgumentNodes.Count == 2)
                        {
                            var theLiteral = expr.ArgumentNodes[1] as Literal;
                            if (theLiteral != null && theLiteral.ExprType.Contains(Datatype.TypeEnum.Integer))
                                sizeToClean = (long)theLiteral!.Value!;
                            else
                                Error("Invalid Literal in zero function.");
                        }
                        else
                            Error("Invalid number of arguments in zero function. Only 1 or 2 allowed.");

                        EmitExpression(arg);
                        if (arg.ExprType.IsReferenceType)
                            emitter.GetMemoryPointerFromIndex();

                        emitter.Codeline($"push  rcx rdi");  // rcx = nr of bytes, rdi = destination pointer
                        emitter.Codeline($"mov   rdi, rax");
                        emitter.Codeline($"mov   rcx, {sizeToClean}");
                        emitter.Codeline($"xor   eax, eax");
                        emitter.Codeline($"rep stosb");
                        emitter.Codeline($"pop   rdi rcx");
                        return null;
                    }
                }
            }

            Variable? instVar = null;
            ArrayAccess? propertyGetArrayAccess = null;

            // When we have an methodcall, we use the scope from the class
            if (expr.FunctionNameNode is PropertyExpression propertyGet)
            {
                if (propertyGet.ObjectNode is Variable functionNameVar)
                {
                    instVar = functionNameVar;
                    string funcName = functionNameVar.Name.Lexeme;
                    var theSymbol = scope!.GetVariableAnywhere(funcName);

                    if (theSymbol is ParentScopeVariable parentSymbol)
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
                }

                if (propertyGet.ObjectNode is ThisExpression objectNodeThis)
                {
                    instVarName = "this";
                    if (expr.FindParentType(typeof(ClassStatement)) is ClassStatement cStmt)
                        classStatement = cStmt;
                }

                if (propertyGet.ObjectNode is ArrayAccess objectNodeArray)
                {
                    propertyGetArrayAccess = objectNodeArray;

                    classStatement = propertyGet.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                    if (classStatement != null)
                        scope = classStatement.GetScope();
                }
                string functionName = propertyGet.Name.Lexeme;
                theFunction = GetSymbol(functionName, scope!) as FunctionSymbol;
            }
            var dllFunctionSymbol = theFunction as DllFunctionSymbol;

            int nrArguments = expr.ArgumentNodes.Count + 2;  // +2 for lexicalparentframe and "this", which is added the last
            if (nrArguments % 2 == 1)
            {
                if (dllFunctionSymbol == null || (expr.ArgumentNodes.Count > 4))
                {
                    emitter.Codeline("push  qword 0          ; Keep 16-byte stack alignment! (for win32)");
                    emitter.StackPush();
                }
            }

            List<FunctionParameter> fPars = theFunction!.FunctionStmt.Parameters;
            for (int i = (nrArguments-3); i >= 0; i--)
            {
                var arg = expr.ArgumentNodes[i];
                EmitExpression(arg);

                // In een DLL aanroep willen we altijd de memory-location meegeven in plaats van de memory-index.
                if (dllFunctionSymbol != null && arg.ExprType.IsReferenceType && (!IsUnaryAddressOf(arg)))
                    emitter.GetMemoryPointerFromIndex();

                FunctionParameter fPar = fPars[i];
                EmitConversionCompatibleType(arg, fPar.TheType);
                emitter.Push(arg.ExprType);
            }

            bool pushLexicalParent = (dllFunctionSymbol == null);
            bool pushThis = (dllFunctionSymbol == null);

            if (pushLexicalParent)
            {
                if (instVarName == "this")
                    emitter.Codeline("mov   rax, [rbp+G_PARAMETER_LEXPARENT]");    // "this" is the same lexical level, so as a trick we use the previous lexparent as lexparent.
                else
                {
                    if (instVarName != null || propertyGetArrayAccess != null)
                        emitter.Codeline("mov   rax, [main_rbp]");
                    else
                    {
                        if (levelsDeep == 0)
                        {
                            if (instVarName != null || propertyGetArrayAccess != null)
                                emitter.Codeline("mov   rax, [main_rbp]");
                            else
                                emitter.Codeline("mov   rax, rbp");         // normal parent frame for normal functions
                        }
                        else
                        {
                            int loopNr = levelsDeep - 1;
                            emitter.Codeline("mov   rax, [rbp+G_PARAMETER_LEXPARENT]");    // parameter 2, lexical parent
                            for (int i = 0; i < loopNr; i++)
                                emitter.Codeline("mov   rax, [rax]");
                        }
                    }
                }
                emitter.Push();
            }

            if (pushThis)
            {
                // Add "this" or null if there is no class instance. Position: [rbp+16] // first parameter
                if (instVarName == "this")
                {
                    var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                    string procName = functionStmt!.Name.Lexeme;
                    string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement?.Name.Lexeme);
                    emitter.LoadFunctionParameter64(theName);
                }
                else if (instVarName != null && instVarName != "this" && instVar != null)
                {
                    VariableRead(instVar);
                    emitter.GetMemoryPointerFromIndex();
                }
                else if (propertyGetArrayAccess != null)
                    ArrayAccess(propertyGetArrayAccess, addressOf: true);
                else
                    emitter.LoadNull();

                emitter.Push();
            }

            if (dllFunctionSymbol != null)
            {
                nrArguments = expr.ArgumentNodes.Count;
                if (nrArguments > 0)
                {
                    InsertFastCallArgument(0, expr.ArgumentNodes[0]);
                    if (nrArguments > 1)
                        InsertFastCallArgument(1, expr.ArgumentNodes[1]);
                }
                if (nrArguments > 2)
                {
                    InsertFastCallArgument(2, expr.ArgumentNodes[2]);
                    if (nrArguments > 3)
                        InsertFastCallArgument(3, expr.ArgumentNodes[3]);
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

            if (expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
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


        public object? VisitorGrouping(Grouping expr)
        {
            EmitExpression(expr.expression);
            return null;
        }


        public object? VisitorLiteral(Literal expr)
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
                emitter.LoadConstant64(Convert.ToInt64(expr.Value));
            else if (expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                Datatype? oldDatatype = expr.Properties.ContainsKey("old ExprType") ? expr.Properties["old ExprType"] as Datatype : null;
                if (oldDatatype != null && !oldDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                {
                    if (oldDatatype.Contains(Datatype.TypeEnum.Integer))
                    {
                        emitter.LoadConstant64(Convert.ToInt64(expr.Value));
                        emitter.IntegerToFloat(expr.ExprType.SizeInBytes);
                    }
                }
                else
                {
                    string id = expr.GetScope()!.IdFor(Convert.ToString(expr.Value, CultureInfo.InvariantCulture)!, "const float");
                    emitter.LoadConstantFloat64(id);
                    if (expr.ExprType.SizeInBytes == 4)
                        emitter.resizeCurrentFloatingPoint(8, 4);
                }
            }
            else if (expr.ExprType.Contains(Datatype.TypeEnum.Boolean))
                emitter.LoadBoolean((bool)expr.Value);

            return null;
        }


        // Unary, like -a, !a, a++, &a or *a. Direction: Read/Write.
        public object? VisitorUnary(Unary expr)
        {
            // &a , &p[0]
            if (expr.Operator.Contains(TokenType.Ampersand))
            {
                if (expr.RightNode is Variable theVariable)
                    VariableAddressOf(theVariable);
                else if (expr.RightNode is ArrayAccess arrayAccess)
                    ArrayAccess(arrayAccess, assignment: null, addressOf: true);
                else if (expr.RightNode is PropertyExpression propExpr)
                    PropertyExpressionAddressOf(propExpr);
                else
                    Compiler.Error("AddressOf can only be done on a variable.");
                return null;
            }

            // a++ , a--
            if (expr.Postfix && (expr.Operator.Contains(TokenType.PlusPlus) || expr.Operator.Contains(TokenType.MinusMinus)))
            {
                if (expr.RightNode is PropertyExpression propExpr)
                {
                    VisitorPropertyGet(propExpr);
                    if (expr.Operator.Contains(TokenType.PlusPlus))
                        emitter.IncrementCurrent();
                    if (expr.Operator.Contains(TokenType.MinusMinus))
                        emitter.DecrementCurrent();
                    emitter.Push();
                    PropertySet propSet = new PropertySet(propExpr.ObjectNode, propExpr.Name, null, null);
                    propSet.Parent = propExpr.Parent;
                    VisitorPropertySet(propSet);
                    emitter.Pop();
                }
                else if (expr.RightNode is Variable theVariable)
                {
                    VariableRead(theVariable);
                    emitter.Push();
                    if (expr.Operator.Contains(TokenType.PlusPlus))
                        emitter.IncrementCurrent();
                    if (expr.Operator.Contains(TokenType.MinusMinus))
                        emitter.DecrementCurrent();
                    VariableWrite(theVariable);
                    emitter.Pop();
                }
                else
                    Compiler.Error("a++ or a-- can only be done on a variable.");
                return null;
            }

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
            else if ((expr.RightNode is PropertyExpression theProp) && expr.Operator.Contains(TokenType.Asterisk))
            {
                if (theProp.ObjectNode is Variable objVar)
                {
                    VariableRead(objVar);
                    EmitExpression(theProp);
                    return null;
                }
            }
            else
                EmitExpression(expr.RightNode);

            // -a
            if ((exprDatatype.Contains(Datatype.TypeEnum.Integer) || exprDatatype.Contains(Datatype.TypeEnum.FloatingPoint)) && expr.Operator.Contains(TokenType.Minus) && !expr.Postfix)
            {
                emitter.Negation(expr.RightNode);
                return null;
            }

            // !a
            if (expr.Operator.Contains(TokenType.Not))
            {
                emitter.LogicalNot();
                return null;
            }

            // *a  (a = int*)
            if (exprDatatype.Contains(Datatype.TypeEnum.Pointer) && expr.Operator.Contains(TokenType.Asterisk))
            {
                emitter.LoadPointingTo((exprDatatype.Base == null) ? Datatype.Default : exprDatatype.Base);
                return null;
            }

            // *a  (a = ptr)
            if (exprDatatype.Contains(Datatype.TypeEnum.Integer) && expr.Operator.Contains(TokenType.Asterisk))
            {
                emitter.LoadPointingTo(exprDatatype);
                return null;
            }

            return null;
        }


        // Variable. Direction: Read
        public object? VisitorVariable(Variable variableExpr)
        {
            VariableRead(variableExpr);
            return null;
        }


    }
}
