using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class Compiler_FunctionCall
    {
        FunctionCall expr;
        Compiler compiler;
        CodeEmitter emitter;

        ClassStatement? classStatement = null;
        Scope? scope = null;
        FunctionSymbol? theFunction = null;

        string? instVarName = null;
        int levelsDeep = 0;
        Variable? functionNameVariable = null;


        Variable? instVar = null;
        ArrayAccess? propertyGetArrayAccess = null;
        bool objectNodeIsPointer = false;
        Expression? objectNodeIsPointerExpression = null;

        DllFunctionSymbol? dllFunctionSymbol = null;

        public Compiler_FunctionCall(FunctionCall functionCallExpr, Compiler compiler, CodeEmitter emitter)
        {
            /*
             * De Win32 abi is veel makkelijker dan System v: bij win32 zijn er alleen 64-bits parameters en het resultaat komt in RAX.
             * In system v, een parameter kan veel groter zijn en dan wordt ie op de stack gezet. Die waarden zijn geen pointers maar de
             * concrete data zelf, dus moeten we kopieer acties gaan doen (aardig wat werk).
             * In win32 pushen we alle parameters op de stack en poppen de parameters eraf die in registers moeten komen. De rest blijft
             * op de stack. In system v kan dat niet, want parameters zijn mogelijk groter dan 64-bit.
             * Voor system v reserveren we de hele stack in 1 keer.
            */
            this.expr = functionCallExpr;
            this.compiler = compiler;
            this.emitter = emitter;

            classStatement = null;
            scope = expr.GetScope();  // normally, the scope of the functioncall is used.
            theFunction = null;

            instVarName = null;
            levelsDeep = 0;
            functionNameVariable = expr.FunctionNameNode as Variable;
        }

        public bool Handle_Constructor()
        {
            // It is NOT a function call, but a constructor! 
            if (functionNameVariable != null && expr.ExprType.Contains(Datatype.TypeEnum.CustomClass))
            {
                int nrBytesToAllocate = expr.ExprType.SizeInBytes;
                emitter.ReserveOnStack(nrBytesToAllocate);
                string memPtrRegister = compiler.cpu.GetRestoredRegister(expr);
                emitter.RegisterMove("rax", memPtrRegister);
                emitter.Push();  // push the memPtr of the allocated memory

                var funcNameVar = expr.FunctionNameNode as Variable;
                var symbol = compiler.GetSymbol(funcNameVar!.Name.Lexeme, scope!, funcNameVar!.Name);
                var theClassSymbol = symbol as ClassSymbol;

                int nrFunctionArg = expr.ArgumentNodes.Count;
                int nrClassInstVars = theClassSymbol!.ClassStatement.InstanceVariableNodes.Count;
                for (int argNr = 0; argNr < nrClassInstVars; argNr++)
                {
                    Expression argExpr = expr.ArgumentNodes[argNr];
                    compiler.EmitExpression(argExpr);
                    var instVarStmt = theClassSymbol!.ClassStatement.InstanceVariableNodes[argNr];
                    compiler.EmitConversionCompatibleType(argExpr, instVarStmt.ResultType);
                    emitter.StoreInstanceVar($"{instVarStmt.Name.Lexeme}@{theClassSymbol!.ClassStatement.Name.Lexeme}", memPtrRegister, argExpr.ExprType);
                }
                emitter.Pop();  // pop the indexspacenr of the allocated memory
                compiler.cpu.FreeRegister(memPtrRegister);
                return true;
            }
            return false;
        }

        public bool Handle_Hardcoded()
        {
            if (functionNameVariable != null)
            {
                theFunction = scope!.GetFunctionAnywhere(functionNameVariable.Name.Lexeme);
                if (theFunction == null)
                    Compiler.Error($"VisitorFunctionCallExpr: {functionNameVariable!.Name.Lexeme} not found!");

                if (theFunction!.FunctionStmt.BodyNode == null)
                    return true;    // we are not calling an empty body function.

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

                if (functionNameVariable.Name.Lexeme == "assert")
                    if (expr.ArgumentNodes.Count < 2)
                        expr.ArgumentNodes.Add(new Literal(functionNameVariable.Name.LineNumber()));

                if (functionNameVariable.Name.Lexeme == "GC_CreateThread")
                {
                    string threadName = ((Variable)expr.ArgumentNodes[0]).Name.Lexeme;

                    // Total exception to the rule: Creating a Thread.
                    emitter.Codeline($"sub rsp, 0x30");
                    emitter.Codeline($"mov rcx, 0");
                    emitter.Codeline($"mov rdx, 0x10000");
                    emitter.Codeline($"lea r8, [_f_Generated_{threadName}_Startup]");
                    emitter.Codeline($"mov r9, 0");
                    emitter.Codeline($"mov qword [rsp+0x20], 0");
                    emitter.Codeline($"mov qword [rsp+0x28], 0");
                    emitter.Codeline($"call [kernel32_CreateThread]");
                    emitter.Codeline($"add rsp, 0x30");
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
                    return true;
                }

                if (functionNameVariable.Name.Lexeme == "GC_Fork")
                {
                    string threadName = ((Variable)expr.ArgumentNodes[0]).Name.Lexeme;
                    emitter.Codeline($"mov   rax, 57  ;SYS_FORK");
                    emitter.Codeline($"syscall");
                    emitter.Codeline($"cmp   rax, 0");
                    emitter.Codeline($"jne _f_Fork_Generated_{threadName}_After");
                    emitter.Codeline($"push  rbp");
                    emitter.Codeline($"mov   rax, [main_rbp]");
                    emitter.Codeline($"mov   rbp, rax");
                    emitter.Codeline($"push  rax");
                    emitter.Codeline($"push  qword 0");
                    emitter.Codeline($"call  _f_{threadName}");
                    emitter.Codeline($"mov   rax, 60  ;SYS_EXIT");
                    emitter.Codeline($"mov   rdi, 0");
                    emitter.Codeline($"syscall");
                    emitter.Writeline($"_f_Fork_Generated_{threadName}_After:");
                    return true;
                }

                if (functionNameVariable.Name.Lexeme == "GC_Clone")
                {
                    string threadName = ((Variable)expr.ArgumentNodes[0]).Name.Lexeme;
                    emitter.Codeline($"mov  rdi, 102400  ; STACK_SIZE");
                    emitter.Codeline($"call malloc");
                    emitter.Codeline($"lea  rsi, [rax + (102400 - 128)]  ; STACK_SIZE");
                    emitter.Codeline($"mov   rax, 56  ;SYS_CLONE");
                    emitter.Codeline($"xor   r8, r8 ; no Thread Local Storage");
                    emitter.Codeline($"lea   rdx, [rsi + 16]");  // we geven wat ruimte in het gereserveerde geheugen
                    emitter.Codeline($"lea   r10, [rsi + 32]");
                    //CLONE_FLAGS equ (0x00000100 + 0x00000200 + 0x00000400 + 0x00000800 + 0x00010000)
                    //                ; CLONE_VM   | CLONE_FS   | CLONE_FILES  | CLONE_SIGHAND  | CLONE_THREAD
                    emitter.Codeline($"mov   rdi, 0x00000100 + 0x00000200 + 0x00000400 + 0x00000800 + 0x00010000");
                    emitter.Codeline($"syscall");
                    emitter.Codeline($"cmp   rax, 0");
                    emitter.Codeline($"jne _f_Clone_Generated_{threadName}_After");
                    emitter.Codeline($"push  rbp");
                    emitter.Codeline($"mov   rax, [main_rbp]");
                    emitter.Codeline($"mov   rbp, rax");
                    emitter.Codeline($"push  rax");
                    emitter.Codeline($"push  qword 0");
                    emitter.Codeline($"call  _f_{threadName}");
                    emitter.Codeline($"mov   rax, 60  ;SYS_EXIT");
                    emitter.Codeline($"mov   rdi, 0");
                    emitter.Codeline($"syscall");
                    emitter.Writeline($"_f_Clone_Generated_{threadName}_After:");
                    return true;
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
                                Compiler.Error("Invalid Literal in zero function.");
                        }
                        else
                            Compiler.Error("Invalid number of arguments in zero function. Only 1 or 2 allowed.");

                        compiler.EmitExpression(arg);

                        emitter.Codeline($"push  rcx rdi");  // rcx = nr of bytes, rdi = destination pointer
                        emitter.Codeline($"mov   rdi, rax");
                        emitter.Codeline($"mov   rcx, {sizeToClean}");
                        emitter.Codeline($"xor   eax, eax");
                        emitter.Codeline($"cld");
                        emitter.Codeline($"rep stosb");
                        emitter.Codeline($"pop   rdi rcx");
                        return true;
                    }
                }
            }
            return false;
        }

        public bool Handle_MethodCall()
        {
            instVar = null;
            propertyGetArrayAccess = null;
            objectNodeIsPointer = false;
            objectNodeIsPointerExpression = null;

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

                objectNodeIsPointer = Datatype.IsPointerType(propertyGet.ObjectNode.ExprType);
                if (objectNodeIsPointer)
                {
                    objectNodeIsPointerExpression = propertyGet.ObjectNode;
                    classStatement = propertyGet.ObjectNode.ExprType.Base.Properties["classStatement"] as ClassStatement;
                    if (classStatement != null)
                        scope = classStatement.GetScope();
                }

                if (propertyGet.ObjectNode is ArrayAccess objectNodeArray)
                {
                    propertyGetArrayAccess = objectNodeArray;

                    classStatement = propertyGet.ObjectNode.ExprType.Properties["classStatement"] as ClassStatement;
                    if (classStatement != null)
                        scope = classStatement.GetScope();
                }
                string functionName = propertyGet.Name.Lexeme;
                theFunction = compiler.GetSymbol(functionName, scope!, propertyGet.Name) as FunctionSymbol;
            }
            return false;
        }

        public bool Handle_InternalCall()
        {
            dllFunctionSymbol = theFunction as DllFunctionSymbol;
            if (dllFunctionSymbol != null)
                return false;

            int nrArguments = expr.ArgumentNodes.Count + 2;  // +2 for lexicalparentframe and "this", which is added the last. Only needed for local calls.
            int nrArgumentsToRelease = nrArguments;
            if (nrArguments % 2 == 1)
            {
                emitter.Push8BytesForStackAlignment();  // this one will be automatically popped, because the ret statement will be 16 bytes wide.
                nrArgumentsToRelease += 1;
            }

            bool stackAlignmentDone = false;
            if ((!emitter.IsAlign16(emitter.StackPos) && (nrArguments % 2 == 0)) || (emitter.IsAlign16(emitter.StackPos) && (nrArguments % 2 == 1)))
            {
                stackAlignmentDone = true;  // this one will NOT be automatically popped, so we do it ourselves after calling the function.
                emitter.Push8BytesForStackAlignment();
            }

            /* Het idee is om alle parameters op de stack te zetten en vervolgens de parameters 
               die in registers geladen moeten worden weer van de stack af te halen. De stack moet wel 16-byte aligned worden. */

            // We iterate the parameters and put them on the stack.
            List<FunctionParameter> fPars = theFunction!.FunctionStmt.Parameters;
            for (int i = (nrArguments - 3); i >= 0; i--)
            {
                var arg = expr.ArgumentNodes[i];
                compiler.EmitExpression(arg);

                FunctionParameter fPar = fPars[i];
                compiler.EmitConversionCompatibleType(arg, fPar.TheType);

                emitter.Push(arg.ExprType);
            }


            if (instVarName == "this")
                emitter.Codeline("mov   rax, [rbp+G_PARAMETER_LEXPARENT]");    // "this" is the same lexical level, so as a trick we use the previous lexparent as lexparent.
            else
            {
                if (instVarName != null || propertyGetArrayAccess != null || objectNodeIsPointer == true)
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


            // Add "this" or null if there is no class instance. Position: [rbp+16] // first parameter
            if (instVarName == "this")
            {
                var functionStmt = expr.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                string procName = functionStmt!.Name.Lexeme;
                string theName = emitter.AssemblyVariableNameForFunctionParameter(procName, "this", classStatement?.Name.Lexeme);
                emitter.LoadFunctionParameter64(theName);
            }
            else if (instVarName != null && instVarName != "this" && instVar != null)
                compiler.VariableRead(instVar);
            else if (propertyGetArrayAccess != null)
                compiler.ArrayAccess(propertyGetArrayAccess, addressOf: true);
            else if (objectNodeIsPointer)
                compiler.EmitExpression(objectNodeIsPointerExpression);
            else
                emitter.LoadNull();

            emitter.Push();

            emitter.CallFunction(theFunction, expr);

            emitter.StackPop(8*nrArgumentsToRelease);  // The popping is automatically done with the RET statement. StackPop is only for our bookkeeping.
            if (stackAlignmentDone)
                emitter.Pop8BytesForStackAlignment();  // Really pop the extra alignment 8 bytes.

            return true;
        }

        public bool Windows_X64_ABI()
        {
            if ((dllFunctionSymbol == null) || (compiler.session.CompileForLinux))
                return false;

            string functionName = (string)dllFunctionSymbol.FunctionStmt.Name.Lexeme;

            int nrArguments = expr.ArgumentNodes.Count;
            int nrArgumentsToRelease = nrArguments - 4;   // the first 4 are put in the registers

            if ((nrArgumentsToRelease > 0) && (nrArgumentsToRelease % 2 == 1))
            {
                emitter.Push8BytesForStackAlignment();
                nrArgumentsToRelease += 1;
            }

            // We iterate the parameters and put them on the stack.
            List<FunctionParameter> fPars = theFunction!.FunctionStmt.Parameters;
            for (int i = (nrArguments - 1); i >= 0; i--)
            {
                var arg = expr.ArgumentNodes[i];
                compiler.EmitExpression(arg);

                FunctionParameter fPar = fPars[i];
                compiler.EmitConversionCompatibleType(arg, fPar.TheType);
                EmitCompressedParameters(arg, scope);

                emitter.Push(arg.ExprType);
            }

            int registerIndex = 0;

            /* When the returntype is bigger than 8 bytes, when need to reserve space on the stack and put it in RCX */
            if (dllFunctionSymbol.FunctionStmt.ResultDatatype?.isClass() ?? false)
            {
                int nrBytes = dllFunctionSymbol.FunctionStmt.ResultDatatype.SizeInBytes;
                if (nrBytes > 8)
                {
                    emitter.ReserveOnStack(nrBytes, "rcx");
                    registerIndex += 1;
                }
            }

            string groupName = (string)dllFunctionSymbol.FunctionStmt.Properties["group"];
            //string functionName = (string)dllFunctionSymbol.FunctionStmt.Name.Lexeme;

            int resultRAXsize = dllFunctionSymbol.FunctionStmt.Result_RAX_Register_Size();


            if (nrArguments > 0)
            {
                InsertFastCallArgument(registerIndex++, expr.ArgumentNodes[0]);
                if (nrArguments > 1)
                    InsertFastCallArgument(registerIndex++, expr.ArgumentNodes[1]);
            }

            if (nrArguments > 2)
            {
                InsertFastCallArgument(registerIndex++, expr.ArgumentNodes[2]);
                if (nrArguments > 3)
                    InsertFastCallArgument(registerIndex++, expr.ArgumentNodes[3]);
            }

            int stackToReserve = 32;
            if (!emitter.IsAlign16(emitter.StackPos - stackToReserve))
                stackToReserve += 8;    // align the stack to 16 bytes
            string hexStackToReserve = stackToReserve.ToString("X");
            emitter.Codeline($"sub   rsp, {hexStackToReserve}h");
            emitter.StackSub(stackToReserve);
            emitter.Codeline($"call  [{groupName}_{functionName}]");
            emitter.Codeline($"add   rsp, {hexStackToReserve}h");
            emitter.StackAdd(stackToReserve);
            // If we have more than 4 parameters, than we need to free those stack parameters.
            if (nrArgumentsToRelease > 0)
            {
                int extraToRelease = ((nrArgumentsToRelease * 8) + 15) & ~15;
                emitter.Codeline($"add   rsp, {extraToRelease}");
                emitter.StackPop(extraToRelease);
            }

            /* Clear the necessary bits in the rax result when the result is a C int or boolean. */
            if (resultRAXsize == 4)
                emitter.Codeline($"movsxd rax, eax");
            else if (resultRAXsize == 1)
                emitter.Codeline($"movzx rax, al");

            return true;
        }

        public bool SystemV_AMD64_ABI()
        {
            if ((!compiler.session.CompileForLinux) || (dllFunctionSymbol == null))
                return false;

            int nrArguments = expr.ArgumentNodes.Count;
            LinuxAbiParameterManager? lpm = new LinuxAbiParameterManager(compiler.cpu, emitter, dllFunctionSymbol!);
            lpm.Load(expr.ArgumentNodes, theFunction!.FunctionStmt.Parameters);    // The difficult Linux System V AMD64 Abi

            int nrElementsOnStack = lpm.nrRegistersOnStack;
            if (nrElementsOnStack % 2 == 1)
            {
                emitter.Push8BytesForStackAlignment();
                nrElementsOnStack += 1;
            }

            bool stackAlignmentNeeded = false;
            if (!emitter.IsAlign16(emitter.StackPos))
            {
                stackAlignmentNeeded = true;
                emitter.Push8BytesForStackAlignment();
            }

            if (lpm!.totalStackByteSize > 0)
                emitter.ReserveOnRSP(lpm.totalStackByteSize, "r10");


            List<FunctionParameter> fPars = theFunction!.FunctionStmt.Parameters;
            for (int i = (nrArguments - 1); i >= 0; i--)
            {
                var arg = expr.ArgumentNodes[i];
                compiler.EmitExpression(arg);

                FunctionParameter fPar = fPars[i];
                compiler.EmitConversionCompatibleType(arg, fPar.TheType);

                if (fPar.Properties.ContainsKey(FunctionParameterPropKey.LinuxOneRegisterParameter))
                {
                    PushLinuxOneRegisterParameter();
                    continue;
                }

                if (fPar.Properties.ContainsKey(FunctionParameterPropKey.LinuxTwoRegisterParameter))
                {
                    PushLinuxTwoRegisterParameter();
                    continue;
                }

                if (fPar.Properties.ContainsKey(FunctionParameterPropKey.LinuxLargeParameterOnStack))
                {
                    // we hebben r10 gevuld met het begin van de stack.
                    // copy the parameter to the stack.
                    int startOffset = (int)fPar.Properties[FunctionParameterPropKey.LinuxParameterStackOffset]!;
                    int nrIterates = (int)fPar.Properties[FunctionParameterPropKey.LinuxParameterNrBytes]! / 8;
                    compiler.cpu.ReserveRegister("r11");
                    for (int j = 0; j < nrIterates; j++)
                    {
                        emitter.Codeline($"mov   r11, [rax+0x{(j * 8).ToString("x")}]");
                        emitter.Codeline($"mov   [r10+0x{(startOffset + j * 8).ToString("x")}], r11");
                    }
                    compiler.cpu.FreeRegister("r11");
                    continue;
                }

                if (fPar.Properties.ContainsKey(FunctionParameterPropKey.LinuxNormalParameterOnStack))
                {
                    int startOffset = (int)fPar.Properties[FunctionParameterPropKey.LinuxParameterStackOffset]!;
                    compiler.cpu.ReserveRegister("r11");
                    emitter.Codeline($"mov   r11, [rax]");
                    emitter.Codeline($"mov   [r10+0x{startOffset.ToString("x")}], r11");
                    compiler.cpu.FreeRegister("r11");
                    continue;
                }

                emitter.Push(arg.ExprType);
            }


            int registerIndex = 0;
            if (!compiler.session.CompileForLinux)
            {
                /* When the returntype is bigger than 8 bytes, when need to reserve space on the stack and put it in RCX */
                if (dllFunctionSymbol.FunctionStmt.ResultDatatype?.isClass() ?? false)
                {
                    int nrBytes = dllFunctionSymbol.FunctionStmt.ResultDatatype.SizeInBytes;
                    if (nrBytes > 8)
                    {
                        emitter.ReserveOnStack(nrBytes, "rcx");
                        registerIndex += 1;
                    }
                }
            }

            nrArguments = expr.ArgumentNodes.Count;

            string groupName = (string)dllFunctionSymbol.FunctionStmt.Properties["group"];
            string functionName = (string)dllFunctionSymbol.FunctionStmt.Name.Lexeme;

            int resultRAXsize = dllFunctionSymbol.FunctionStmt.Result_RAX_Register_Size();

            foreach (string reg in lpm.registerAllocation)
            {
                compiler.cpu.ReserveRegister(reg);
                if (reg.StartsWith("xmm"))
                    emitter.PopFloat(reg);
                else
                    emitter.Pop(null, reg);
                compiler.cpu.FreeRegister(reg);
            }

            emitter.Codeline($"call  {functionName}");
            if (stackAlignmentNeeded)
                emitter.Pop8BytesForStackAlignment();

            // If we stack parameters, we need to free them.
            if (nrElementsOnStack > 0)
            {
                int extraToRelease = ((nrElementsOnStack * 8) + 15) & ~15;
                emitter.Codeline($"add   rsp, {extraToRelease}");
                emitter.StackPop(extraToRelease);
            }

            if (lpm.totalStackByteSize > 0)
                emitter.FreeOnRSP(lpm.totalStackByteSize);

            /* Clear the necessary bits in the rax result when the result is a C int or boolean. */
            if (resultRAXsize == 4)
                emitter.Codeline($"movsxd rax, eax");
            else if (resultRAXsize == 1)
                emitter.Codeline($"movzx rax, al");

            lpm.RetrieveLargerResult();

            return true;
        }

        public void InsertFastCallArgument(int index, Expression expr)
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
                compiler.cpu.ReserveRegister(theRegister);
                emitter.Pop(expr, theRegister);
                compiler.cpu.FreeRegister(theRegister);
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
                compiler.cpu.ReserveRegister(theRegister);
                emitter.Pop(expr, theRegister);
                compiler.cpu.FreeRegister(theRegister);
            }
        }

        // The X64 ABI doesn't want a pointer if the struct can be compressed to an 8 byte value.
        public void EmitCompressedParameters(Expression? arg, Scope? scope)
        {
            if (arg is Variable argVariable && argVariable.ExprType.Contains(Datatype.TypeEnum.CustomClass) && arg.ExprType.SizeInBytes <= 8)
            {
                var classStatement = argVariable.ExprType.Properties["classStatement"] as ClassStatement;
                if (classStatement != null && classStatement.CanBeCompressedToRegister())
                {
                    if (classStatement.IsF32F32())
                    {
                        emitter.Codeline("mov   rax, [rax]");
                        //de variabele naar de class staat in rax.
                        //uiteindelijk moet rax de compressed_one_register bevatten.
                        //ieder element van de class gaat naar de stack
                    }
                }
            }
            else if (arg.ExprType.Contains(Datatype.TypeEnum.CustomClass) && arg.ExprType.SizeInBytes <= 8)
            {
                emitter.Codeline("mov   rax, [rax]");
            }
        }


        public void PushLinuxOneRegisterParameter()
        {
            compiler.cpu.ReserveRegister("r11");
            emitter.Codeline("mov   r11, [rax]");
            emitter.Codeline("push  r11");
            compiler.cpu.FreeRegister("r11");
            emitter.StackPush();
        }


        public void PushLinuxTwoRegisterParameter()
        {
            compiler.cpu.ReserveRegister("r11");
            emitter.Codeline("mov   r11, [rax+8]");
            emitter.Codeline("push  r11");
            emitter.StackPush();
            emitter.Codeline("mov   r11, [rax]");
            emitter.Codeline("push  r11");
            emitter.StackPush();
            compiler.cpu.FreeRegister("r11");
        }
    }
}
