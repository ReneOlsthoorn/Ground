using System.Globalization;
using System.Net.Security;
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
        public CompilationSession session;

        public Compiler(CompilationSession session) {
            this.session = session;
            CodeTemplateName = session.PreProcessor.Template;
            cpu = new CPU_X86_64();
            emitter = new CodeEmitter(cpu, session.PreProcessor.Defines, session);
        }

        public string LibrariesToInclude()
        {
            StringBuilder result = new StringBuilder();
            foreach (var (libraryName, dllFilename, linuxLib) in session.PreProcessor.Libraries)
                result.AppendLine($"          {libraryName}, '{dllFilename}', \\");
            return result.ToString();
        }

        public string LibraryApiIncludes()
        {
            StringBuilder result = new StringBuilder();
            foreach (var (libraryName, dllFilename, linuxLib) in session.PreProcessor.Libraries)
                result.AppendLine($"  include 'Include/{libraryName}_api.inc'");
            return result.ToString();
        }


        public string GenerateAssembly(Statement stmt)
        {
            // Gather the codeblocks
            EmitStatement(stmt);

            // Read the codetemplate
            string linuxExtension = this.session.CompileForLinux ? "_linux" : "";
            string tmpl = File.ReadAllText($"Templates/{this.CodeTemplateName + linuxExtension}.asm");

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
                VisitorBlock(prog.BodyNode!);
                emitter.CloseGeneratedCode_Main();

                int oldFramePos = emitter.FramePosition;
                EmitFunctions(prog.Scope.GetFunctionStatements());
                EmitClasses(prog.Scope.GetClassSymbols());
                emitter.FramePosition = oldFramePos;
                emitter.CloseGeneratedCode_Procedures();

                emitter.EmitLiteralFloat64(prog.Scope.GetLiteralFloatSymbols());
                emitter.EmitLiteralFloat32(prog.Scope.GetLiteralFloat32Symbols());
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
            return null;
        }


        public object? VisitorVariableDeclaration(VarStatement stmt)
        {
            var name = stmt.Name.Lexeme;
            var currentScope = stmt.GetScope();
            var symbol = GetSymbol(name, currentScope!, stmt.Name);

            // all declared variables are local to something, so we only know LocalVariableSymbols
            if (symbol is LocalVariableSymbol  localVarSymbol)
            {
                if (localVarSymbol.DataType.Types.Contains(Datatype.TypeEnum.CustomClass))
                {
                    int nrBytesToAllocate = localVarSymbol.DataType.SizeInBytes;
                    emitter.ReserveOnStack(nrBytesToAllocate);
                    emitter.StoreFunctionVariable64(emitter.AssemblyVariableName(localVarSymbol, currentScope?.Owner), localVarSymbol.DataType);
                }

                if (stmt.InitializerNode != null)
                {
                    // shortcut. A special list validator must be made.
                    if (stmt.InitializerNode is Expressions.List)
                        stmt.InitializerNode!.ExprType = localVarSymbol.DataType;

                    EmitExpression(stmt.InitializerNode);
                    EmitConversionCompatibleType(stmt.InitializerNode!, localVarSymbol.DataType);

                    var assemblyVarName = emitter.AssemblyVariableName(localVarSymbol, stmt.GetScope()?.Owner);
                    emitter.StoreFunctionVariable64(assemblyVarName, localVarSymbol.DataType);
                }
            }
            return null;
        }
        

        public object? VisitorReturn(ReturnStatement stmt)
        {
            if (stmt.ReturnValueNode is ThisExpression thisExpr)
                emitter.Codeline("mov   rax, [rbp+G_PARAMETER_THIS]");
            else
                EmitExpression(stmt.ReturnValueNode);

            if (stmt.FindParentType(typeof(FunctionStatement)) is FunctionStatement  fStmt)
            {
                string returnLabel;
                if (fStmt.Properties.ContainsKey("returnLabel"))
                {
                    returnLabel = (string)fStmt.Properties["returnLabel"]!;
                }
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

            emitter.ReserveOnStack((int)nrBytesToAllocate);
            if (list.ElementsNodes.Count > 0)
            {
                emitter.Push();
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
                emitter.Pop();
            }
            
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
            // The deepest PropertyExpression is the first we need to evaluate. I use a stack to do that.
            Stack<PropertyExpression> propExprStack = new();
            propExprStack.Push(expr);
            PropertyExpression needle = expr;
            while (needle.ObjectNode is PropertyExpression propExpr)
            {
                needle = propExpr;
                propExprStack.Push(propExpr);
            }
            needle = propExprStack.Pop();
            while (propExprStack.Count >= 1)
            {
                PropertyExpressionAddressOf(needle);
                needle = propExprStack.Pop();
            }

            var objectNodeAsVariable = needle.ObjectNode as Variable;
            var objectNodeAsArray = needle.ObjectNode as ArrayAccess;
            var objectNodeAsThis = needle.ObjectNode as ThisExpression;


            var objectNodeIsPointer = Datatype.IsPointerType(needle.ObjectNode.ExprType);
            var currentScope = needle.GetScope();

            ClassStatement? classStatement = null;
            VarStatement? instVar = null;

            if (objectNodeAsVariable != null)
            {
                if (objectNodeAsVariable?.Name.Lexeme == "g")
                {
                    string theVariable = needle.Name.Lexeme;
                    if (needle.Name.Contains(TokenType.Literal) && needle.Name.Datatype!.Contains(Datatype.TypeEnum.String))
                        theVariable = theVariable.Substring(1, (theVariable.Length - 2));

                    emitter.LoadHardcodedGroupVariable(theVariable);
                    return null;
                }

                var variableSymbol = currentScope!.GetVariable(objectNodeAsVariable!.Name.Lexeme);
                if (variableSymbol is GroupSymbol groupSymbol)
                {
                    var groupScope = groupSymbol.GroupStatement.GetScope();
                    var groupVar = groupScope.GetVariable(needle.Name.Lexeme);
                    if (groupVar is HardcodedVariable hardCodedVar)
                    {
                        string varName = emitter.AssemblyVariableNameForHardcodedGroupVariable(groupSymbol.Name, hardCodedVar.Name);
                        emitter.LoadHardcodedGroupVariable(varName);
                    }
                    return null;
                }
            }

            if (objectNodeIsPointer)
                classStatement = needle.ObjectNode.ExprType.Base.Properties["classStatement"] as ClassStatement;
            else
            {
                classStatement = needle.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                if (objectNodeAsVariable != null)
                    VariableRead(objectNodeAsVariable);
            }

            instVar = classStatement!.InstanceVariableNodes.Find((instVariable) => instVariable.Name.Lexeme == needle.Name.Lexeme);
            if (instVar == null)
                Compiler.Error($"Instance variable {needle.Name.Lexeme} not found.", needle.Name);

            if (objectNodeAsThis != null)
            {
                classStatement = needle.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == needle.Name.Lexeme);

                var functionStmt = needle.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }

            if (objectNodeAsArray != null)
            {
                ArrayAccess(objectNodeAsArray!, addressOf: true);

                classStatement = needle.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                instVar = classStatement!.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == needle.Name.Lexeme);
            }

            if (objectNodeIsPointer)
                EmitExpression(needle.ObjectNode);

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
            string? storeCurrentReg = null;

            // The deepest PropertyExpression is the first we need to evaluate. I use a stack to do that.
            Stack <PropertyExpression> propExprStack = new();
            propExprStack.Push(expr.PropExpr);
            bool storeCurrent = expr.PropExpr.ObjectNode is PropertyExpression;
            PropertyExpression needle = expr.PropExpr;
            while (needle.ObjectNode is PropertyExpression propExpr)
            {
                needle = propExpr;
                propExprStack.Push(propExpr);
            }
            needle = propExprStack.Pop();
            while (propExprStack.Count >= 1)
            {
                PropertyExpressionAddressOf(needle);
                needle = propExprStack.Pop();
            }
            if (storeCurrent)
            {
                storeCurrentReg = cpu.GetRestoredRegister();
                emitter.PushRegister(storeCurrentReg);      //save the restored register
                emitter.Codeline($"mov   {storeCurrentReg}, rax");
            }

            ClassStatement? classStatement = null;
            VarStatement? instVar = null;

            var objectNodeAsVariable = needle.ObjectNode as Variable;
            var objectNodeAsArray = needle.ObjectNode as ArrayAccess;
            var objectNodeAsThis = needle.ObjectNode as ThisExpression;
            bool needleObjectIsPointer = Datatype.IsPointerType(needle.ObjectNode.ExprType);

            if (expr.ValueNode != null)
            {
                EmitExpression(expr.ValueNode);
                if (needle.Name.Contains(TokenType.Literal))  // for example g.[pixels_p]  The Literal part is [pixels_p]
                {
                    string theLiteralVariable = needle.Name.Lexeme;
                    if (needle.Name.Contains(TokenType.Literal) && needle.Name.Datatype!.Contains(Datatype.TypeEnum.String))
                        theLiteralVariable = theLiteralVariable.Substring(1, (theLiteralVariable.Length - 2));

                    emitter.StoreCurrent(theLiteralVariable);
                    return null;
                }
                emitter.Push(expr.ValueNode.ExprType);
            }

            classStatement = null;
            if (needleObjectIsPointer)
                classStatement = needle.ObjectNode.ExprType.Base!.Properties["classStatement"] as ClassStatement;
            else
                classStatement = needle.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;

            instVar = classStatement?.InstanceVariableNodes.First((instVariable) => instVariable.Name.Lexeme == needle.Name.Lexeme);

            if (objectNodeAsVariable != null)
                VariableRead(objectNodeAsVariable);

            if (objectNodeAsThis != null)
            {
                var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }

            if (objectNodeAsArray != null)
                ArrayAccess(objectNodeAsArray!, addressOf: true);

            if (storeCurrent)
                emitter.Codeline($"mov   rax, {storeCurrentReg}");

            string instVarReg = cpu.GetTmpRegister();
            emitter.StoreCurrent(instVarReg);
            emitter.Pop(expr.ValueNode);

            if (expr.ValueNode != null)
                EmitConversionCompatibleType(expr.ValueNode, instVar.ResultType);

            emitter.StoreInstanceVar($"{instVar.Name.Lexeme}@{classStatement.Name.Lexeme}", instVarReg, instVar.ResultType);
            cpu.FreeRegister(instVarReg);

            if (storeCurrent)
            {
                emitter.PopRegister(storeCurrentReg);
                cpu.FreeRegister(storeCurrentReg);
            }
            return null;
        }


        // Variable. Direction: Write.
        public object? VisitorAssignment(Assignment assignment)
        {
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
                case TokenType.Caret:
                    emitter.PopBitwiseXor();
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
            /*
             * De Win32 abi is veel makkelijker dan System v: bij win32 zijn er alleen 64-bits parameters en het resultaat komt in RAX.
             * In system v, een parameter kan veel groter zijn en dan wordt ie op de stack gezet. Die waarden zijn geen pointers maar de
             * concrete data zelf, dus moeten we kopieer acties gaan doen (aardig wat werk).
             * In win32 pushen we alle parameters op de stack en poppen de parameters eraf die in registers moeten komen. De rest blijft
             * op de stack. In system v kan dat niet, want parameters zijn mogelijk groter dan 64-bit.
             * Voor system v reserveren we de hele stack in 1 keer.
            */

            Compiler_FunctionCall cvc = new Compiler_FunctionCall(expr, this, emitter);
            bool stop = false;
            stop = cvc.Handle_Constructor();    if (stop) return null;
            stop = cvc.Handle_Hardcoded();      if (stop) return null;
            stop = cvc.Handle_MethodCall();     if (stop) return null;
            stop = cvc.Handle_InternalCall();   if (stop) return null;
            stop = cvc.Windows_X64_ABI();       if (stop) return null;
            stop = cvc.SystemV_AMD64_ABI();     if (stop) return null;

            return null;
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

            if (expr.ExprType.Name == "string" || (expr.ExprType.Name == "byte*" && expr.Value.GetType().Name == "String"))
            {
                var strConstant = expr.GetRootScope()?.GetString((string)expr.Value);
                if (strConstant != null)
                    emitter.LoadConstantString(strConstant);
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
                    bool isFloat32 = (expr.ExprType.SizeInBytes == 4);
                    string id = expr.GetScope()!.IdFor(Convert.ToString(expr.Value, CultureInfo.InvariantCulture)!, isFloat32 ? "const f32" : "const f64");
                    if (isFloat32)
                        emitter.LoadConstantFloat32(id);
                    else
                        emitter.LoadConstantFloat64(id);
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
                    PropertyExpressionsAddressOf(propExpr);
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
                    emitter.Push();     // the value is pushed, the propertyset will pop it.
                    PropertySet propSet = new PropertySet(propExpr, null, null);
                    propSet.Parent = propExpr.Parent;
                    VisitorPropertySet(propSet);
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
