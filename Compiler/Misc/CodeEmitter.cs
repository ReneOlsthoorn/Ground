using GroundCompiler.Expressions;
using GroundCompiler.Statements;
using System.Globalization;

namespace GroundCompiler
{
    public class CodeEmitter
    {
        public CPU_X86_64 cpu;
        public List<string> GeneratedCode_Equates;
        public List<string> GeneratedCode_Main;
        public List<string> GeneratedCode_Procedures;
        public List<string> GeneratedCode_Data;
        public List<string> generatedCode;
        public int FramePosition;

        // When entering a function, the stack is always unaligned, because the returnaddress is on the stack.
        // So StackPos is always -8 when starting a procedure.
        public long StackPos = -8;  // position of the stack for align16 purposes. Resetted in EmitProcedure>>EmitCreateStackframe()
        long labelCounter = 0;

        public CodeEmitter(CPU_X86_64 cpu, Dictionary<string, Token>? preprocessorDefines = null)
        {
            this.cpu = cpu;
            generatedCode = new List<string>();
            GeneratedCode_Equates = new List<string>();
            InsertPreprocessorDefines(preprocessorDefines);
            GeneratedCode_Main = new List<string>();
            GeneratedCode_Procedures = new List<string>();
            GeneratedCode_Data = new List<string>();
        }

        public void CloseGeneratedCode_Main()
        {
            GeneratedCode_Main.AddRange(generatedCode);
            generatedCode = new List<string>();
        }
        public void CloseGeneratedCode_Procedures()
        {
            GeneratedCode_Procedures.AddRange(generatedCode);
            generatedCode = new List<string>();
        }
        public void CloseGeneratedCode_Data()
        {
            GeneratedCode_Data.AddRange(generatedCode);
            generatedCode = new List<string>();
        }
        public List<string> CloseGeneratedCode()
        {
            var result = generatedCode;
            generatedCode = new List<string>();
            return result;
        }

        public void Writeline(string text) { generatedCode.Add(text + "\r\n"); }
        public void Codeline(string text) { Writeline($"  {text}"); }
        public string NewLabel() { return $"L{labelCounter++}"; }


        public void EmitLiteralFloats(List<FloatConstantSymbol> globalLiteralFloats)
        {
            if (globalLiteralFloats.Count > 0)
                Writeline($"align 16");

            foreach (var variable in globalLiteralFloats)
            {
                string quoted = ((double)variable.Value).ToString("0.0000000000", CultureInfo.InvariantCulture);
                Writeline($"{variable.SymbolRefId} dq {quoted}");
            }
        }

        public void EmitStrings(List<StringConstantSymbol> globalStrings)
        {
            foreach (var variable in globalStrings)
            {
                Writeline($"align 16");
                string quoted = EmitQuotedAssemblyString((string)variable.Value);
                if (quoted == "''")
                    Writeline($"{variable.SymbolRefId} db 0");
                else
                    Writeline($"{variable.SymbolRefId} db {quoted},0");
            }
        }

        public string EmitQuotedAssemblyString(string text)
        {
            text = text.Replace("'", "\\27").Replace("\r", "\\0d").Replace("\n", "\\0a");
            //text = text.Replace("\r", "',13,'").Replace("\n", "',10,'");
            text = System.Text.RegularExpressions.Regex.Replace(text, @"\\([0-9A-Fa-f]{2})", m =>
            {
                string hex = m.Groups[1].Value;
                int value = Convert.ToInt32(hex, 16);
                return "',0x" + hex + ",'";
            });
            return $"'{text}'".Replace(",''", "").Replace("'',", "");
        }

        public void CreateStackframe()
        {
            Codeline($"push  rbp");         // this line makes the value at [rbp] always the parent
            StackPush();  // now, the stack is aligned, because when starting a function, the stack is always unaligned.
            Codeline($"mov   rbp, rsp");
        }

        public void ReserveStackspace(int stackSpaceNeeded)
        {
            if (stackSpaceNeeded % 16 > 0)
                Compiler.Error("Stack is not aligned on 16 byte boundary");

            Codeline($"sub   rsp, {stackSpaceNeeded}");
            StackSub(stackSpaceNeeded);
/* The code below can be used to clear the allocated stack space. It would be better if the user called zero() on the array.
            Codeline($"lea   rax, [rsp]");
            Codeline($"push  rdi rcx");
            Codeline($"mov   rdi, rax");
            Codeline($"xor   eax, eax");
            Codeline($"mov   rcx, { stackSpaceNeeded / 8 }");
            Codeline($"rep   stosq");
            Codeline($"pop   rcx rdi");  */
        }

        public void EndFunction(int returnPop = 0, bool noFrameRestoration = false)
        {
            if (!noFrameRestoration)
            {
                Codeline($"mov   rsp, rbp");
                // the intial "mov rbp, rsp" statement is done with an aligned stack, so the stackpos is -16
                StackPos = -16;
                Codeline($"pop   rbp");
                StackPop();
            }
            if (returnPop > 0)
                Codeline($"retn  {returnPop}\r\n");
            else
                Codeline($"ret\r\n");
        }

        public void CallFunction(FunctionSymbol f, Expression expr)
        {
            string assemblyFunctionname = ConvertToAssemblyFunctionName(f.FunctionStmt.Name.Lexeme, f.FunctionStmt.GetGroupOrClassName());
            Codeline($"call  {assemblyFunctionname}");
        }

        public void LoadConstantString(StringConstantSymbol strSymbol)
        {
            Codeline($"lea   rax, [{strSymbol.SymbolRefId}]");
        }

        public void RegisterMove(string reg1, string reg2) => Codeline($"mov   {reg2}, {reg1}");
        public void LoadHardcodedGroupVariable(string name) => Codeline($"mov   rax, {name}");
        public void StoreCurrent(string name) => Codeline($"mov   {name}, rax");
        public void LoadNull() => Codeline($"xor   eax, eax");


        public void LoadConstant64(Int64 value)
        {
            Codeline($"mov   rax, {value}");
        }

        public void LoadBoolean(bool value)
        {
            Codeline($"mov   rax, {(value ? 1 : 0)}");
        }
        public void LoadInfinityFloat64()
        {
            Codeline($"mov   rax, 0x7FF0000000000000");
            Codeline($"movq  xmm0, rax");
        }

        public void LoadConstantFloat64(string name)
        {
            Codeline($"movq  xmm0, qword [{name}]");
        }

        public void LoadAssemblyVariableString(string name) => Codeline($"lea   rax, [{name}]");

        public void LoadSystemVarsVariable(string name)
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, [vars]");
            Codeline($"mov   rax, [{reg}+SystemVars.{name}]");
            cpu.FreeRegister(reg);
        }

        public void StoreSystemVarsVariable(string name, int nrBytes = 8)
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, [vars]");
            Codeline($"mov   [{reg}+SystemVars.{name}], {cpu.RAX_Register_Sized(nrBytes)}");
            cpu.FreeRegister(reg);
        }

        public void Push(Datatype? conversionDatatype = null)
        {
            if (conversionDatatype != null && conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                PushFloat();
            else
            {
                Codeline($"push  rax");
                StackPush();
            }
        }

        public void PushFloat()
        {
            Codeline($"sub   rsp, 8");
            StackSub();
            Codeline($"movq  qword [rsp], xmm0");
        }

        public void PopFloat(string? register = null)
        {
            string usedRegister = "xmm0";
            if (register != null)
                usedRegister = register;
            Codeline($"movq  {usedRegister}, qword [rsp]");
            Codeline($"add   rsp, 8");
            StackAdd();
        }

        public void PopAddStrings(Expression? expr = null)
        {
            // rax will contain the ptr to the new stack string.
            cpu.ReserveRegister("rcx");
            cpu.ReserveRegister("rdx");
            Codeline("mov   rcx, rax");
            Codeline("pop   rdx");
            StackPop();
            FramePosition += 256;
            Codeline($"lea   rax, [rbp-{FramePosition}]");
            Codeline("call  AddCombinedStrings");       // rcx wijst naar eerste string, rdx wijst naar tweede string
            cpu.FreeRegister("rdx");
            cpu.FreeRegister("rcx");
        }

        public void PopAdd(Expression expr, Datatype conversionDatatype)
        {
            if (conversionDatatype.Contains(Datatype.TypeEnum.String))
            {
                PopAddStrings(expr);
                return;
            }

            if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                PopFloat($"{floatReg}");
                if (conversionDatatype.SizeInBytes == 4)
                    Codeline($"addss xmm0, {floatReg}");
                else
                    Codeline($"addsd xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"add   rax, {reg}");
            cpu.FreeRegister(reg);
        }


        public void PopCompareFloat(string trueJmpCondition, Datatype conversionDatatype)
        {
            var exitLabel = NewLabel();

            var floatReg = cpu.GetTmpFloatRegister();
            PopFloat($"{floatReg}");
            Codeline($"mov   rax, 1");

            if (conversionDatatype.SizeInBytes == 4)
                Codeline($"ucomiss xmm0, {floatReg}");
            else
                Codeline($"ucomisd xmm0, {floatReg}");

            Codeline($"{trueJmpCondition}    {exitLabel}");
            Codeline($"mov   rax, 0");
            Codeline($"jmp   {exitLabel}");
            cpu.FreeRegister(floatReg);
            InsertLabel(exitLabel);
        }


        public void PopSub(Binary expr, Datatype conversionDatatype)
        {
            if (conversionDatatype.Contains(Datatype.TypeEnum.String))
            {
                // We have the situation that in string comparison there can be a null value in both arguments.
                var nullExitLabel = NewLabel();
                var strCmpLabel = NewLabel();
                var secondArgNull = NewLabel();
                cpu.ReserveRegister("rcx");
                cpu.ReserveRegister("rdx");
                Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                Codeline($"jne    {strCmpLabel}");
                Codeline($"pop    rcx");
                StackPop();
                InsertLabel(secondArgNull);
                Codeline($"sub    rax, rcx");
                Codeline($"jmp    {nullExitLabel}");
                InsertLabel(strCmpLabel);
                Codeline($"mov    rcx, rax");
                Codeline($"pop    rax");
                //StackPop(); // deze tweede pop doen we niet, omdat normaal gesproken er maar 1 tijdens executie wordt uitgevoerd.
                Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                Codeline($"je     {secondArgNull}");
                Codeline($"mov    rdx, rax");
                Codeline($"sub    rsp, 20h");
                Codeline($"call   [msvcrt_strcmp]");
                Codeline($"add    rsp, 20h");
                InsertLabel(nullExitLabel);
                cpu.FreeRegister("rdx");
                cpu.FreeRegister("rcx");
                return;
            }

            if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                PopFloat($"{floatReg}");
                if (conversionDatatype.SizeInBytes == 4)
                    Codeline($"subss xmm0, {floatReg}");
                else
                    Codeline($"subsd xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"sub   rax, {reg}");
            cpu.FreeRegister(reg);
        }


        public void PopMul(Expression expr, Datatype conversionDatatype)
        {
            if (!conversionDatatype.Contains(Datatype.TypeEnum.Number))
                Compiler.Error("CodeEmitterX64>>PopMul: Cannot multiply expressions that are not numbers.");

            if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                PopFloat($"{floatReg}");
                if (conversionDatatype.SizeInBytes == 4)
                    Codeline($"mulss xmm0, {floatReg}");
                else
                    Codeline($"mulsd xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            cpu.ReserveRegister("rdx");
            Codeline($"pop   rdx");
            StackPop();
            Codeline($"mul   rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
            cpu.FreeRegister("rdx");
        }

        public void PopDiv(Expression expr, Datatype conversionDatatype)
        {
            if (conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                PopFloat($"{floatReg}");
                if (conversionDatatype.SizeInBytes == 4)
                    Codeline($"divss xmm0, {floatReg}");
                else
                    Codeline($"divsd xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            cpu.ReserveRegister("rdx");
            Codeline($"xor   rdx, rdx");    // always clean rdx before division
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"div   {reg}");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseAnd()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"and   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopModulo()
        {
            var reg = cpu.GetTmpRegister();
            cpu.ReserveRegister("rdx");
            Codeline($"xor   edx, edx");        // always clean rdx before division
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"div   {reg}");
            Codeline($"mov   eax, edx");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseOr()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"or   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseXor()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"xor  rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopCCToBoolean(string condition)
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"cmp   rax, {reg}");
            Codeline($"set{condition}  al");
            Codeline($"movzx rax, al");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }
        public void PopGreaterToBoolean() => PopCCToBoolean("g");
        public void PopLessToBoolean() => PopCCToBoolean("l");
        public void PopGreaterEqualToBoolean() => PopCCToBoolean("ge");
        public void PopLessEqualToBoolean() => PopCCToBoolean("le");

        public void Logical()
        {
            Codeline($"neg   rax");         // if rax != 0 => carry flag is set
            Codeline($"mov   eax, 0");
            Codeline($"adc   eax, 0");
            // input int64 rax == 0, output bool rax -> 0
            // input int64 rax != 0, output bool rax -> 1
        }

        public void LogicalNot()
        {
            Codeline($"neg   rax");         // if rax != 0 => carry flag is set
            Codeline($"mov   eax, 1");
            Codeline($"sbb   eax, 0");
            // input int64 rax == 0, output bool rax -> 1
            // input int64 rax != 0, output bool rax -> 0
        }

        public void PopOr()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"or    rax, {reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopAnd()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            StackPop();
            Codeline($"and   rax, {reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopShiftLeft()
        {
            cpu.ReserveRegister("rcx");
            Codeline($"pop   rcx");
            StackPop();
            Codeline($"shl   rax, cl");
            cpu.FreeRegister("rcx");
        }

        public void PopShiftRight()
        {
            cpu.ReserveRegister("rcx");
            Codeline($"pop   rcx");
            StackPop();
            Codeline($"shr   rax, cl");
            cpu.FreeRegister("rcx");
        }

        public void Negation(Expression? expr = null)
        {
            if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (expr.ExprType.SizeInBytes == 8)
                    Codeline($"xorps   xmm0, xword [Negation_XMM]");
                if (expr.ExprType.SizeInBytes == 4)
                    Codeline($"xorps   xmm0, xword [Negation_XMM32]");
            }
            else 
                Codeline($"neg   rax");
        }

        public void JumpToLabelIfTrue(string label)
        {
            Codeline($"cmp   eax, 0");
            Codeline($"jnz   {label}");
        }

        public void JumpToLabelIfFalse(string label)
        {
            Codeline($"cmp   eax, 0");
            Codeline($"jz    {label}");
        }

        public void JumpToLabel(string label)
        {
            Codeline($"jmp   {label}");
        }

        public string Gather_LexicalParentStackframe(int levelDeep)
        {
            cpu.ReserveRegister("rcx");
            if (levelDeep < 1)
                Compiler.Error("Parent not found.");

            int loopNr = levelDeep - 1;
            Codeline("mov   rcx, [rbp+G_PARAMETER_LEXPARENT]");
            for (int i = 0; i < loopNr; i++)
                Codeline("mov   rcx, [rcx]");
            return "rcx";
        }

        public string Gather_CurrentStackframe()
        {
            cpu.ReserveRegister("rcx");
            Codeline("mov   rcx, rbp");
            return "rcx";
        }

        public void LoadPointingTo(Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Codeline($"xor   eax, eax");
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq   xmm0, [{reg}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd   xmm0, [{reg}]");
            }
            else
                Codeline($"mov   {cpu.RAX_Register_Sized(nrBytes)}, [{reg}]");
            cpu.FreeRegister(reg);
        }
        public void StorePointingTo(Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Pop();
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq   [{reg}], xmm0");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd   [{reg}], xmm0");
            }
            else
                Codeline($"mov   [{reg}], {cpu.RAX_Register_Sized(nrBytes)}");
            cpu.FreeRegister(reg);
        }
        public void LeaFunctionVariable64(string variableName) => Codeline($"lea   rax, qword [rbp-{variableName}]");
        public void LoadFunctionVariable64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  xmm0, qword [rbp-{variableName}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  xmm0, dword [rbp-{variableName}]");
            }
            else if (datatype.Contains(Datatype.TypeEnum.String))
                Codeline($"lea   rax, qword [rbp-{variableName}]");
            else
                Codeline($"mov   rax, qword [rbp-{variableName}]");
        }
        public void LeaParentFunctionVariable64(string variableName) => Codeline($"lea   rax, qword [rcx-{variableName}]");
        public void LoadParentFunctionVariable64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  xmm0, qword [rcx-{variableName}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  xmm0, dword [rcx-{variableName}]");
            }
            else if (datatype.Contains(Datatype.TypeEnum.String))
                LeaParentFunctionVariable64(variableName);
            else
                Codeline($"mov   rax, qword [rcx-{variableName}]");
        }
        public void LeaFunctionParameter64(string variableName) => Codeline($"lea   rax, qword [rbp+{variableName}]");
        public void LoadFunctionParameter64(string variableName) => Codeline($"mov   rax, qword [rbp+{variableName}]");
        public void LoadFunctionParameter64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint)) {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  xmm0, qword [rbp+{variableName}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  xmm0, dword [rbp+{variableName}]");
            }
            else
                Codeline($"mov   rax, qword [rbp+{variableName}]");
        }

        public void LoadFunction(string functionName)
        {
            Codeline($"mov   rax, {functionName}");
        }

        public void StoreFunctionParameter64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  qword [rbp+{variableName}], xmm0");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  dword [rbp+{variableName}], xmm0");
            }
            else
                Codeline($"mov   qword [rbp+{variableName}], rax");
        }

        public void StoreFunctionVariable64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  qword [rbp-{variableName}], xmm0");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  dword [rbp-{variableName}], xmm0");
            }
            else if (datatype.Contains(Datatype.TypeEnum.String))
            {
                //copy the string pointed in rax, to the [rbp-{variableName}]
                Codeline($"push  rax rcx");
                Codeline($"lea   rcx, qword [rbp-{variableName}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx rax");
            }
            else
            {
                // You might ask why only rax is used and not eax, ax, al based on the datatype. Like this:
                // string reg = cpu.RAX_Register_Sized(datatype.SizeInBytes);
                // Because a byte in de stack will misalign the stack horribly. And also, local variables are
                // not arrays, so they take not so much space. It is not like the programmer will be defining 300
                // byte variables. In that case, an array is created by the programmer those objects are a pointer.
                Codeline($"mov   qword [rbp-{variableName}], rax");
            }
        }

        public void StoreParentFunctionParameter64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  qword [rcx-{variableName}], xmm0");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  dword [rcx-{variableName}], xmm0");
            }
            else if (datatype.Contains(Datatype.TypeEnum.String))
            {
                //copy the string pointed in rax, to the [rbp-{variableName}]
                Codeline($"push  rax rcx");
                Codeline($"lea   rcx, qword [rcx-{variableName}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx rax");
            }
            else
                Codeline($"mov   [rcx-{variableName}], rax");
        }

        public void StoreInstanceVar(string instVar, string reg, Datatype targetType)
        {
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint)) {
                if (targetType.SizeInBytes == 8)
                    Codeline($"movq  qword [{reg}+{instVar}], xmm0");
                if (targetType.SizeInBytes == 4)
                    Codeline($"movd  dword [{reg}+{instVar}], xmm0");
            }
            else if (targetType.Contains(Datatype.TypeEnum.String))
            {
                //copy the string pointed in rax, to the [rbp-{variableName}]
                Codeline($"push  rax rcx");
                Codeline($"lea   rcx, qword [{reg}+{instVar}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx rax");
            }
            else
            {
                var nrBytes = targetType.SizeInBytes;
                Codeline($"mov   {cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}], {cpu.RAX_Register_Sized(nrBytes)}");
            }
        }

        public void LoadInstanceVar(string instVar, string reg, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  xmm0, qword [{reg}+{instVar}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  xmm0, dword [{reg}+{instVar}]");
            }
            else if (datatype.Contains(Datatype.TypeEnum.String))
            {
                Codeline($"lea   rax, qword [{reg}+{instVar}]");
            }
            else
            {
                var nrBytes = datatype.SizeInBytes;
                if (nrBytes < 4)
                    Codeline($"xor   rax, rax");

                Codeline($"mov   {cpu.RAX_Register_Sized(nrBytes)}, {cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}]");
            }
        }

        public void LeaInstanceVar(string instVar, string reg, Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            Codeline($"lea   rax, {cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}]");
        }

        public void IncrementCurrent()
        {
            Codeline($"inc   rax");
        }
        public void DecrementCurrent()
        {
            Codeline($"dec   rax");
        }

        public void ReserveOnStack(int space, string register = "rax")
        {
            int toReserve = space;
            int onder15 = (space & 0xf);
            if (onder15 > 0)
                toReserve = space - onder15 + 16;

            FramePosition += toReserve;
            Codeline($"lea   {register}, [rbp-{FramePosition}]");
        }

        public void IntegerToString(Expression expr)
        {
            cpu.ReserveRegister("rcx");
            FramePosition += 256;
            Codeline($"lea   rcx, [rbp-{FramePosition}]");
            Codeline("call  IntegerToString");
            Codeline($"mov   rax, rcx");
            cpu.FreeRegister("rcx");
        }

        public void FloatToString(Expression expr)
        {
            cpu.ReserveRegister("rcx");
            FramePosition += 256;
            Codeline($"lea   rcx, [rbp-{FramePosition}]");
            Codeline($"call  FloatToString");
            Codeline($"mov   rax, rcx");
            cpu.FreeRegister("rcx");
        }

        public void BooleanToString(Expression expr)
        {
            Codeline($"call  BooleanToString");
        }

        public void IntegerToFloat(int destinationSize)
        {
            Codeline("cvtsi2sd xmm0, rax");
            resizeCurrentFloatingPoint(sourceNrBytes: 8, destinationNrBytes: destinationSize);
        }

        public void FloatToInteger(Datatype sourceDatatype, Datatype destinationDatatype)
        {
            if (sourceDatatype.SizeInBytes == 4)
                Codeline("cvtss2si rax, xmm0");
            else
                Codeline("cvtsd2si rax, xmm0");
        }

        public void InsertLabel(string label)
        {
            Writeline($"{label}:");
        }

        public string ConvertToAssemblyFunctionName(string functionName, string? groupName = null) => $"_f_{functionName}" + ((groupName != null) ? $"@{groupName}" : "");

        public string AssemblyVariableName(LocalVariableSymbol varSymbol, IScopeStatement? scopeStmt)
        {
            string? groupOrClassName = null;
            if (scopeStmt is FunctionStatement funcStmt)
                if (funcStmt.classStatement != null)
                    groupOrClassName = funcStmt.classStatement.Name.Lexeme;

            return AssemblyVariableNameForFunctionParameter(scopeStmt!.GetScopeName().Lexeme, varSymbol.Name, groupOrClassName);
        }

        public string AssemblyVariableName(FunctionParameterSymbol varSymbol)
        {
            return AssemblyVariableNameForFunctionParameter(varSymbol.TheFunction.Name.Lexeme, varSymbol.FunctionParameter.Name, varSymbol.TheFunction.GetGroupOrClassName());
        }

        public string AssemblyVariableName(string name, IScopeStatement? scopeStmt)
        {
            string? groupOrClassName = null;
            if (scopeStmt is FunctionStatement funcStmt)
                if (funcStmt.classStatement != null)
                    groupOrClassName = funcStmt.classStatement.Name.Lexeme;

            return AssemblyVariableNameForFunctionParameter(scopeStmt!.GetScopeName().Lexeme, name, groupOrClassName);
        }

        public string AssemblyVariableNameForFunctionParameter(string functionName, string parName, string? groupName = null)
        {
            string part1 = ConvertToAssemblyFunctionName(functionName);
            string part2 = parName;
            return $"{part2}@{part1}" + ((groupName != null) ? $"@{groupName}" : "");
        }

        public string UserfriendlyVariableNameForFunctionParameter(string functionName, string parName, string? groupName = null)
        {
            string part1 = functionName;
            string part2 = parName;
            return $"{part2}@{part1}" + ((groupName != null) ? $"@{groupName}" : "");
        }

        public string AssemblyVariableNameForHardcodedGroupVariable(string group, string variableName) => $"{group}_{variableName}";

        public void Pop(Expression? expr = null, string? register = null)
        {
            if (expr?.ExprType.Contains(Datatype.TypeEnum.FloatingPoint) ?? false)
                PopFloat(register);
            else
            {
                Codeline($"pop   {((register == null) ? "rax" : register)}");
                StackPop();
            }
        }

        public void MoveCurrentToRegister(string reg) => Codeline($"mov   {reg}, rax");

        public void StoreCurrentInBasedIndex(int nrBytes, string baseReg, int index, Datatype targetType)
        {
            if (targetType.Contains(Datatype.TypeEnum.String))
            {
                // rax = source   rcx = destination
                Codeline($"push  rax rcx");
                Codeline($"lea   rcx, qword [{baseReg}+{index}*{nrBytes}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx rax");
                return;
            }
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (targetType.SizeInBytes == 8)
                    Codeline($"movq  rax, xmm0");  // below, the basereg+index cannot be done with xmm0
                if (targetType.SizeInBytes == 4)
                    Codeline($"movd  eax, xmm0");  // below, the basereg+index cannot be done with xmm0
            }
            Codeline($"mov   [{baseReg}+{index}*{nrBytes}], {cpu.RAX_Register_Sized(nrBytes)}");
        }

        public void StoreCurrentInBasedIndex(int nrBytes, string baseReg, string indexReg, Datatype targetType)
        {
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (targetType.SizeInBytes == 8)
                    Codeline($"movq  rax, xmm0");  // below, the basereg+index cannot be done with xmm0
                if (targetType.SizeInBytes == 4)
                    Codeline($"movd  eax, xmm0");  // below, the basereg+index cannot be done with xmm0
            }
            Codeline($"mov   [{baseReg}+({indexReg}*{nrBytes})], {cpu.RAX_Register_Sized(nrBytes)}");
        }

        public void SignExtend(Datatype theType)
        {
            if (theType.IsValueType && theType.Contains(Datatype.TypeEnum.Signed) && theType.Contains(Datatype.TypeEnum.Integer) && theType.SizeInBytes < 8)
                Codeline($"movsx rax, {cpu.RAX_Register_Sized(theType.SizeInBytes)}");
        }

        public void LoadBasedIndexToCurrent(int nrBytes, string baseReg, string indexReg, Datatype targetType)
        {
            Codeline($"xor   eax, eax");
            if (targetType.Contains(Datatype.TypeEnum.String) && nrBytes == 256)
            {
                string reg = cpu.GetTmpRegister();
                Codeline($"mov   {reg}, {indexReg}");
                Codeline($"shl   {reg}, 8");
                Codeline($"mov   rax, [{baseReg}+{reg}]");
                cpu.FreeRegister(reg);
            }
            else
                Codeline($"mov   {cpu.RAX_Register_Sized(nrBytes)}, [{baseReg}+({indexReg}*{nrBytes})]");

            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint) && (targetType.SizeInBytes == 8))
                Codeline($"movq   xmm0, rax");
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint) && (targetType.SizeInBytes == 4))
                Codeline($"movd   xmm0, eax");
        }

        public void LeaBasedIndexToCurrent(int nrBytes, string baseReg, string indexReg, Datatype targetType)
        {
            Codeline($"xor   eax, eax");
            if (targetType.Contains(Datatype.TypeEnum.String) && nrBytes == 256)
            {
                string reg = cpu.GetTmpRegister();
                Codeline($"mov   {reg}, {indexReg}");
                Codeline($"shl   {reg}, 8");
                Codeline($"lea   rax, [{baseReg}+{reg}]");
                cpu.FreeRegister(reg);
            }
            else if (nrBytes != 1 && nrBytes != 2 && nrBytes != 4 && nrBytes != 8)
                Codeline($"lea   {cpu.RAX_Register_Sized(nrBytes)}, [{baseReg}+({indexReg}*{nrBytes})]");
            else
                Compiler.Error($"LeaBasedIndexToCurrent: Index of {nrBytes} is not supported.");
        }

        public void LeaBasedIndex(int nrBytes, string baseReg, string indexReg)
        {
            if (nrBytes != 1 && nrBytes != 2 && nrBytes != 4 && nrBytes != 8)
            {
                cpu.ReserveRegister("rdx");
                Codeline($"mov   rax, {nrBytes}");
                Codeline($"mov   rdx, {indexReg}");
                Codeline($"mul   rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
                Codeline($"mov   {indexReg}, rax");
                Codeline($"lea   rax, [{baseReg}+{indexReg}]");
                cpu.FreeRegister("rdx");
            }
            else
                Codeline($"lea   rax, [{baseReg}+({indexReg}*{nrBytes})]");
        }

        public void resizeCurrentFloatingPoint(int sourceNrBytes, int destinationNrBytes)
        {
            if (sourceNrBytes == 8 && destinationNrBytes == 8)
                return;
            if (sourceNrBytes == 8 && destinationNrBytes == 4)
            {
                var tmpReg = cpu.GetTmpFloatRegister();
                Codeline($"cvtsd2ss  xmm0, xmm0");
                Codeline($"movaps {tmpReg}, xmm0");
                Codeline($"xorps xmm0, xmm0");
                Codeline($"movss xmm0, {tmpReg}");
                cpu.FreeRegister(tmpReg);
            }
            if (sourceNrBytes == 4 && destinationNrBytes == 8)
                Codeline($"cvtss2sd  xmm0, xmm0");
        }

        public void resizeCurrent(int newNrBytes)
        {
            if (newNrBytes == 1)
                Codeline($"and   rax, 0xff");
            else if (newNrBytes == 2)
                Codeline($"and   rax, 0xffff");
            else if (newNrBytes == 4)
                Codeline($"mov   eax, eax");
        }

        public bool IsAlign16(long stackposition) => (((-stackposition) % 16) == 0);
        public void StackAdd(int size = 8) => StackPos += size;
        public void StackSub(int size = 8) => StackPos -= size;
        public void StackPush(int size = 8) => StackSub(size);
        public void StackPop(int size = 8) => StackAdd(size);

        void InsertPreprocessorDefines(Dictionary<string, Token>? preprocessorDefines = null)
        {
            if (preprocessorDefines == null)
                return;

            foreach (var key in preprocessorDefines.Keys)
            {
                if (preprocessorDefines[key]?.Datatype?.Contains(Datatype.TypeEnum.String) ?? false)
                    continue;

                GeneratedCode_Equates.Add($"GC_{key}={preprocessorDefines[key].Lexeme}\r\n");
            }
        }
    }
}
