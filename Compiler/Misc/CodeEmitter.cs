using GroundCompiler.Expressions;
using GroundCompiler.Statements;
using System.Globalization;

namespace GroundCompiler
{
    public class LinearIR  //IR = Intermediate Representation
    {
        private static readonly HashSet<string> IntegerRegisters = new(StringComparer.OrdinalIgnoreCase)
        {
            "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rbp", "rsp",
            "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15"
        };

        public string Instruction;
        public string? DestinationOperand;
        public string? SourceOperand;
        public Dictionary<string, object?> Properties;

        // We use the same order as the Intel assembly: first destination and then source.
        public LinearIR(string instruction, string? destinationOperand = null, string? sourceOperand = null)
        {
            this.Instruction = instruction;
            this.DestinationOperand = destinationOperand;
            this.SourceOperand = sourceOperand;
            this.Properties = new Dictionary<string, object?>();
        }

        public string InstructionPadded
        {
            get { return Instruction.PadRight(6); }
        }

        public override string ToString()
        {
            if ((DestinationOperand == null) && (SourceOperand == null))
                return $"  {InstructionPadded}\r\n";
            if ((DestinationOperand != null) && (SourceOperand == null))
                return $"  {InstructionPadded}{this.DestinationOperand}\r\n";
            if ((DestinationOperand != null) && (SourceOperand != null))
                return $"  {InstructionPadded}{this.DestinationOperand}, {this.SourceOperand}\r\n";
            return "";
        }

        public string Comp
        {
            get {
                if ((DestinationOperand == null) && (SourceOperand == null))
                    return $"{Instruction}";
                if ((DestinationOperand != null) && (SourceOperand == null))
                    return $"{Instruction};{this.DestinationOperand}";
                if ((DestinationOperand != null) && (SourceOperand != null))
                    return $"{Instruction};{this.DestinationOperand};{this.SourceOperand}";
                return "";
            }
        }

        public string CompDest
        {
            get
            {
                if ((DestinationOperand == null) && (SourceOperand == null))
                    return $"{Instruction}";
                if (DestinationOperand != null)
                    return $"{Instruction};{this.DestinationOperand}";
                return "";
            }
        }

        public string CompSrc
        {
            get
            {
                if ((DestinationOperand == null) && (SourceOperand == null))
                    return $"{Instruction}";
                if (SourceOperand != null)
                    return $"{Instruction};{this.SourceOperand}";
                return "";
            }
        }

        public bool IsPop() => Instruction?.ToLowerInvariant() == "pop";
        public string? theSetInstructionCondition() {
            if (Instruction?.ToLowerInvariant()?.StartsWith("set") ?? false)
            {
                if (Instruction == "setg") return "g";
                if (Instruction == "setge") return "ge";
                if (Instruction == "setl") return "l";
                if (Instruction == "setle") return "le";
            }
            return null;
        }

        public bool SourceIsImmediateInteger()
        {
            if (SourceOperand == null) return false;
            return (int.TryParse(SourceOperand, out _));
        }

        public bool IsDestinationIntegerRegister()
        {
            if (DestinationOperand == null)
                return false;
            return IntegerRegisters.Contains(DestinationOperand);
        }
    }


    public class CodeEmitter
    {
        public CPU_X86_64 cpu;
        public List<string> GeneratedCode_Equates;
        public List<string> GeneratedCode_Main;
        public List<string> GeneratedCode_Procedures;
        public List<string> GeneratedCode_Data;
        public List<object> generatedCode;
        public int FramePosition;
        private CompilationSession session;

        // When entering a function, the stack is always unaligned, because the returnaddress is on the stack.
        // So StackPos is always -8 when starting a procedure.
        public long StackPos = -8;  // position of the stack for align16 purposes. Resetted in EmitProcedure>>EmitCreateStackframe()
        long labelCounter = 0;

        public CodeEmitter(CPU_X86_64 cpu, Dictionary<string, Token>? preprocessorDefines = null, CompilationSession session = null)
        {
            this.cpu = cpu;
            this.session = session;
            generatedCode = new List<object>();
            GeneratedCode_Equates = new List<string>();
            InsertPreprocessorDefines(preprocessorDefines);
            GeneratedCode_Main = new List<string>();
            GeneratedCode_Procedures = new List<string>();
            GeneratedCode_Data = new List<string>();
        }

        public List<LinearIR>? GetLinearIR_Range(ref List<object> input, int index, int size)
        {
            List<LinearIR> result = new List<LinearIR>();
            for (int i = 0; i < size; i++)
            {
                object obj = input[index+i];
                if (obj is string strObj)
                    return null;
                LinearIR linObj = (LinearIR)obj;
                result.Add(linObj);
            }
            return result;
        }

        public LinearIR? getLin(ref List<object> input, int index)
        {
            object obj = input[index];
            if (obj is LinearIR linObj)
                return linObj;
            return null;
        }

        public string getInstr(ref List<object> input, int index)
        {
            if (input.Count <= index)
                return "";
            object obj = input[index];
            if (obj is LinearIR linObj)
                return linObj.Instruction;
            if (obj is string strObj)
                return strObj.TrimStart().Split(' ')[0];
            return "";
        }

        public string getComp(ref List<object> input, int index)
        {
            if (input.Count <= index)
                return "";
            object obj = input[index];
            if (obj is LinearIR linObj)
                return linObj.Comp;
            if (obj is string strObj)
                return string.Join(";", strObj.Trim().Split(new[] { ' ', ',' }, StringSplitOptions.RemoveEmptyEntries));
            return "";
        }

        public void PeepholeOptimize(LinearIR linObj, ref List<object> input, int index, int listSize)
        {
            /*  cmp rax, ?
                setg al
                movzx rax, al
                test rax, rax
                jz L0 

            becomes:
                cmp rax, ?
                jng L0
            */
            if (linObj.Properties.ContainsKey("hint peephole int > >= < <=") && (index + 6 < listSize))
            {
                List<LinearIR>? list = GetLinearIR_Range(ref input, index, 5);
                if (list != null)
                {
                    if ((list[0].Instruction == "cmp") && (list[0].DestinationOperand == "rax") &&
                        (list[1].Instruction.StartsWith("set")) && (list[1].DestinationOperand == "al") &&
                        (list[2].Comp == "movzx;rax;al") &&
                        (list[3].Comp == "test;rax;rax") &&
                        (list[4].Instruction == "jz"))
                    {
                        string? condition = list[1].theSetInstructionCondition();
                        if (condition != null)
                        {
                            LinearIR conditionalJump = new LinearIR($"jn{condition}", list[4].DestinationOperand);
                            input[index + 1] = conditionalJump;
                            for (int i = 2; i <= 4; i++)
                                input[index + i] = "";
                        }
                    }
                }
            }

            /*  sub   rax, ?
                neg   rax
                mov   eax, 1
                sbb   eax, 0
                test  rax, rax
                jz    L0
            
            becomes:
                cmp   rax, ?
                jne   L0
             */
            if (linObj.Properties.ContainsKey("hint peephole int == !=") && (index + 8 < listSize))
            {
                List<LinearIR>? list = GetLinearIR_Range(ref input, index, 6);
                if (list != null)
                {
                    if ((list[0].Instruction == "sub") && (list[0].DestinationOperand == "rax") &&
                        (list[1].Comp == "neg;rax") &&
                        (((list[2].Comp == "mov;eax;1") && (list[3].Comp == "sbb;eax;0")) || ((list[2].Comp == "mov;eax;0") && (list[3].Comp == "adc;eax;0"))) &&
                        (list[4].Comp == "test;rax;rax") &&
                        (list[5].Instruction == "jz"))
                    {
                        bool eq = (list[3].Comp == "sbb;eax;0");
                        string condition = eq ? "ne" : "e";
                        if (condition != null)
                        {
                            input[index] = new LinearIR($"cmp", list[0].DestinationOperand, list[0].SourceOperand);
                            input[index + 1] = new LinearIR($"j{condition}", list[5].DestinationOperand);
                            for (int i = 2; i <= 5; i++)
                                input[index + i] = "";
                        }
                    }
                }
            }

            /*  mov   rax, ?
                push  rax
                mov   rax, ?
                pop   r8

            becomes:
                mov   r8, ?
                mov   rax, ?
            */
            if (linObj.CompDest == "mov;rax")
            {
                if ((getLin(ref input, index + 1)?.CompDest == "push;rax") &&
                    (getLin(ref input, index + 2)?.CompDest == "mov;rax") &&
                    (getLin(ref input, index + 3)?.Instruction == "pop") && (getLin(ref input, index + 3)?.IsDestinationIntegerRegister() ?? false))
                {
                    linObj.DestinationOperand = getLin(ref input, index + 3)?.DestinationOperand;
                    input[index + 1] = "";
                    input[index + 3] = "";
                }
            }

            /*
              mov   rax, 1
              mov   ?, rax
              mov   rax, 0    --> this one is important, else rax might be used somewhere else in the code

            becomes:
              mov   ?, 1
             */
            if (linObj.CompDest == "mov;rax" && linObj.SourceIsImmediateInteger() &&
                (getLin(ref input, index + 1)?.CompSrc == "mov;rax") &&
                (getLin(ref input, index + 2)?.CompDest == "mov;rax"))
            {
                LinearIR el2 = getLin(ref input, index + 1)!;
                el2.SourceOperand = $"qword {linObj.SourceOperand}";
                input[index] = "";
                input[index + 1] = el2;
            }

            /*
              xor   eax, eax
              mov   rax, ?

            becomes:
              mov   rax, ?
             */
            if (linObj.Comp == "xor;eax;eax" &&
                ((getLin(ref input, index + 1)?.CompDest == "mov;rax") || (getLin(ref input, index + 1)?.CompDest == "mov;eax")) && (getLin(ref input, index + 1)?.Comp != "mov;eax;eax"))
            {
                input[index] = "";
            }
        }

        public void PeepholeOptimizationPass(ref List<object> input, int listSize)
        {
            for (int i = 0; i < listSize; i++)
            {
                object obj = input[i];
                if (obj is string strObj)
                    continue;
                LinearIR linObj = (LinearIR)obj;
                PeepholeOptimize(linObj, ref input, i, listSize);
            }
        }

        public List<string> ConvertToStrings(List<object> mixedGenerated)
        {
            int listSize = mixedGenerated.Count;
            PeepholeOptimizationPass(ref mixedGenerated, listSize);

            List<string> result = new List<string>();
            for (int i = 0; i < listSize; i++)
            {
                object obj = mixedGenerated[i];
                if (obj is string strObj)
                {
                    if (strObj != "")
                        result.Add(strObj);
                    continue;
                }
                LinearIR linObj = (LinearIR)obj;
                result.Add(linObj.ToString());
            }
            return result;
        }

        public void CloseGeneratedCode_Main()
        {
            GeneratedCode_Main.AddRange(ConvertToStrings(generatedCode));
            generatedCode = new List<object>();
        }
        public void CloseGeneratedCode_Procedures()
        {
            GeneratedCode_Procedures.AddRange(ConvertToStrings(generatedCode));
            generatedCode = new List<object>();
        }
        public void CloseGeneratedCode_Data()
        {
            GeneratedCode_Data.AddRange(ConvertToStrings(generatedCode));
            generatedCode = new List<object>();
        }
        public List<string> CloseGeneratedCode()
        {
            var result = ConvertToStrings(generatedCode);
            generatedCode = new List<object>();
            return result;
        }

        public void Writeline(string text) { generatedCode.Add(text + "\r\n"); }
        public void WriteDefine(string key, string value)
        {
            if (session.CompileForNASM)
                Writeline($"%define {key} {value}");
            else
                Writeline($"{key} equ {value}");
        }
        public void WriteEqu(string key, long value)
        {
            if (session.CompileForNASM)
                Writeline($"{key} equ {value}");
            else
                Writeline($"{key} = {value}");
        }
        public void Codeline(string text) { Writeline($"  {text}"); }
        public LinearIR CodeIR(string? instr, string? op1 = null, string? op2 = null)
        {
            LinearIR ir = new LinearIR(instr, op1, op2);
            generatedCode.Add(ir);
            return ir;
        }
        public string NewLabel() { return $"L{labelCounter++}"; }

        public void EmitNOP() => Codeline("nop");

        public void EmitLiteralFloat64(List<Float64ConstantSymbol> globalLiteralFloats)
        {
            if (globalLiteralFloats.Count > 0)
                Writeline($"align 16");

            foreach (var variable in globalLiteralFloats)
            {
                string quoted = ((double)variable.Value).ToString("0.0000000000", CultureInfo.InvariantCulture);
                Writeline($"{variable.SymbolRefId} dq {quoted}");
            }
        }

        public void EmitLiteralFloat32(List<Float32ConstantSymbol> globalLiteralFloats)
        {
            if (globalLiteralFloats.Count > 0)
                Writeline($"align 16");

            foreach (var variable in globalLiteralFloats)
            {
                string quoted = ((float)variable.Value).ToString("0.0000000000", CultureInfo.InvariantCulture);
                Writeline($"{variable.SymbolRefId} dd {quoted}");
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
            CodeIR("push","rbp");         // this line makes the value at [rbp] always the parent
            StackPush();  // now, the stack is aligned, because when starting a function, the stack is always unaligned.
            CodeIR("mov","rbp","rsp");
        }

        public void ReserveStackspace(int stackSpaceNeeded)
        {
            if (stackSpaceNeeded % 16 > 0)
                Compiler.Error("Stack is not aligned on 16 byte boundary");

            CodeIR("sub","rsp",$"{stackSpaceNeeded}");
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
                CodeIR("mov", "rsp", "rbp");
                // the intial "mov rbp, rsp" statement is done with an aligned stack, so the stackpos is -16
                StackPos = -16;
                CodeIR("pop", "rbp");
                StackPop();
            }
            if (returnPop > 0)
                CodeIR("retn",$"{returnPop}");
            else
                CodeIR("ret");
        }

        public void CallFunction(FunctionSymbol f, Expression expr)
        {
            string assemblyFunctionname = ConvertToAssemblyFunctionName(f.FunctionStmt.Name.Lexeme, f.FunctionStmt.GetGroupOrClassName());
            CodeIR("call",$"{assemblyFunctionname}");
        }

        public void LoadConstantString(StringConstantSymbol strSymbol)
        {
            CodeIR("lea", "rax", $"[{strSymbol.SymbolRefId}]");
        }

        public void RegisterMove(string reg1, string reg2) => CodeIR("mov", reg2, reg1);
        public void LoadHardcodedGroupVariable(string name) => CodeIR("mov", "rax", name);
        public void StoreCurrent(string name) => CodeIR("mov", name, "rax");
        public void LoadNull() => CodeIR("xor", "eax", "eax");


        public void LoadConstant64(Int64 value)
        {
            CodeIR("mov", "rax", $"{value}");
        }

        public void LoadBoolean(bool value)
        {
            CodeIR("mov", "rax", $"{(value ? 1 : 0)}");
        }
        public void LoadInfinityFloat64()
        {
            CodeIR("mov", "rax", "0x7FF0000000000000");
            CodeIR("movq", "xmm0", "rax");
        }

        public void LoadConstantFloat32(string name)
        {
            CodeIR("movss", "xmm0", $"dword [{name}]");
        }

        public void LoadConstantFloat64(string name)
        {
            CodeIR("movq", "xmm0", $"qword [{name}]");
        }

        public void LoadAssemblyVariableString(string name) => CodeIR("lea", "rax", $"[{name}]");

        public void LoadSystemVarsVariable(string name)
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("mov", $"{reg}", "[vars]");
            CodeIR("mov", "rax", $"[{reg}+SystemVars.{name}]");
            cpu.FreeRegister(reg);
        }

        public void StoreSystemVarsVariable(string name, int nrBytes = 8)
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("mov", $"{reg}", "[vars]");
            CodeIR("mov", $"[{reg}+SystemVars.{name}]", $"{cpu.RAX_Register_Sized(nrBytes)}");
            cpu.FreeRegister(reg);
        }

        public void Push8BytesForStackAlignment()
        {
            CodeIR("sub", "rsp", "8");
            StackPush();
        }
        public void Pop8BytesForStackAlignment()
        {
            CodeIR("add", "rsp", "8");
            StackPop();
        }


        public void Push(Datatype? conversionDatatype = null)
        {
            if (conversionDatatype != null && conversionDatatype.Contains(Datatype.TypeEnum.FloatingPoint))
                PushFloat();
            else
            {
                CodeIR("push", "rax");
                StackPush();
            }
        }

        public void PushRegister(string reg)
        {
            CodeIR("push", $"{reg}");
            StackPush();
        }
        public void PopRegister(string reg)
        {
            CodeIR("pop", $"{reg}");
            StackPop();
        }

        public void PushFloat()
        {
            CodeIR("sub", "rsp", "8");
            StackSub();
            CodeIR("movq", "qword [rsp]", "xmm0");
        }

        public void ReserveOnRSP(int size, string? register = null)
        {
            if (size > 0)
                CodeIR("sub", "rsp", $"0x{size.ToString("x")}");

            if (register != null)
            {
                cpu.ReserveRegister(register);
                CodeIR("mov", $"{register}", "rsp");
                cpu.FreeRegister(register);
            }
        }
        public void FreeOnRSP(int size)
        {
            if (size > 0)
                Codeline($"add   rsp, 0x{size.ToString("x")}");
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
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("add", "rax", $"{reg}");
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
            if (session.CompileForLinux)
            {
                if (conversionDatatype.Contains(Datatype.TypeEnum.String))
                {
                    // We have the situation that in string comparison there can be a null value in both arguments.
                    var nullExitLabel = NewLabel();
                    var strCmpLabel = NewLabel();
                    var secondArgNull = NewLabel();
                    cpu.ReserveRegister("rdi");
                    cpu.ReserveRegister("rsi");
                    Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                    Codeline($"jne    {strCmpLabel}");
                    Codeline($"pop    rdi");
                    StackPop();
                    InsertLabel(secondArgNull);
                    Codeline($"sub    rax, rdi");
                    Codeline($"jmp    {nullExitLabel}");
                    InsertLabel(strCmpLabel);
                    Codeline($"mov    rdi, rax");
                    Codeline($"pop    rax");
                    //StackPop(); // deze tweede pop doen we niet, omdat normaal gesproken er maar 1 tijdens executie wordt uitgevoerd.
                    Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                    Codeline($"je     {secondArgNull}");
                    Codeline($"mov    rsi, rax");
                    Codeline($"call   strcmp");
                    InsertLabel(nullExitLabel);
                    cpu.FreeRegister("rsi");
                    cpu.FreeRegister("rdi");
                    return;
                }
            }
            else
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
            CodeIR("pop", reg);
            StackPop();
            var ir = CodeIR("sub", "rax", reg);
            ir.Properties["hint peephole int == !="] = true;
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
            CodeIR("pop", "rdx");
            StackPop();
            CodeIR("mul", "rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
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
            CodeIR("xor", "rdx", "rdx");    // always clean rdx before division
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("cqo");
            CodeIR("idiv", $"{reg}");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseAnd()
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("and", "rax", $"{reg}");
            cpu.FreeRegister(reg);
        }

        public void PopModulo()
        {
            var reg = cpu.GetTmpRegister();
            cpu.ReserveRegister("rdx");
            CodeIR("xor", "edx", "edx");        // always clean rdx before division
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("cqo");
            CodeIR("idiv", $"{reg}");
            CodeIR("mov", "rax", "rdx");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseOr()
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("or", "rax", $"{reg}");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseXor()
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("xor", "rax", $"{reg}");
            cpu.FreeRegister(reg);
        }

        public void PopCCToBoolean(string condition)
        {
            var reg = cpu.GetTmpRegister();            
            CodeIR("pop", reg);
            StackPop();
            var ir = CodeIR("cmp", "rax", reg);
            ir.Properties["hint peephole int > >= < <="] = true;
            CodeIR($"set{condition}", "al");
            CodeIR("movzx", "rax", "al");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }
        public void PopGreaterToBoolean() => PopCCToBoolean("g");
        public void PopLessToBoolean() => PopCCToBoolean("l");
        public void PopGreaterEqualToBoolean() => PopCCToBoolean("ge");
        public void PopLessEqualToBoolean() => PopCCToBoolean("le");

        public void Logical()
        {
            CodeIR("neg", "rax");         // if rax != 0 => carry flag is set
            CodeIR("mov", "eax", "0");
            CodeIR("adc", "eax", "0");
            // input int64 rax == 0, output bool rax -> 0
            // input int64 rax != 0, output bool rax -> 1
        }

        public void LogicalNot()
        {
            CodeIR("neg", "rax");         // if rax != 0 => carry flag is set
            CodeIR("mov", "eax", "1");
            CodeIR("sbb", "eax", "0");
            // input int64 rax == 0, output bool rax -> 1
            // input int64 rax != 0, output bool rax -> 0
        }

        public void PopOr()
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("or", "rax", $"{reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopAnd()
        {
            var reg = cpu.GetTmpRegister();
            CodeIR("pop", $"{reg}");
            StackPop();
            CodeIR("and", "rax", $"{reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopShiftLeft()
        {
            cpu.ReserveRegister("rcx");
            CodeIR("pop", "rcx");
            StackPop();
            CodeIR("shl", "rax", "cl");
            cpu.FreeRegister("rcx");
        }

        public void PopShiftRight()
        {
            cpu.ReserveRegister("rcx");
            CodeIR("pop", "rcx");
            StackPop();
            CodeIR("sar", "rax", "cl");
            cpu.FreeRegister("rcx");
        }

        public string Octoword() => session.CompileForNASM ? "oword" : "xword";

        public void Negation(Expression? expr = null)
        {
            if (expr != null && expr.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (expr.ExprType.SizeInBytes == 8)
                    Codeline($"xorps   xmm0, {Octoword()} [Negation_XMM]");
                if (expr.ExprType.SizeInBytes == 4)
                    Codeline($"xorps   xmm0, {Octoword()} [Negation_XMM32]");
            }
            else 
                CodeIR("neg", "rax");
        }

        public void JumpToLabelIfTrue(string label)
        {
            CodeIR("test", "rax", "rax");
            CodeIR("jnz", label);
        }

        public void JumpToLabelIfFalse(string label)
        {
            CodeIR("test", "rax", "rax");
            CodeIR("jz", label);
        }

        public void JumpToLabel(string label)
        {
            CodeIR("jmp", label);
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
            CodeIR("mov", "rcx", "rbp");
            return "rcx";
        }

        public void LoadPointingTo(Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            var reg = cpu.GetTmpRegister();
            CodeIR("mov", $"{reg}", "rax");
            CodeIR("xor", "eax", "eax");
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq   xmm0, [{reg}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd   xmm0, [{reg}]");
            }
            else
                CodeIR("mov", $"{cpu.RAX_Register_Sized(nrBytes)}", $"[{reg}]");
            cpu.FreeRegister(reg);
        }
        public void StorePointingTo(Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            var reg = cpu.GetTmpRegister();
            CodeIR("mov", $"{reg}", "rax");
            Pop();
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq   [{reg}], xmm0");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd   [{reg}], xmm0");
            }
            else
                CodeIR("mov", $"[{reg}]", $"{cpu.RAX_Register_Sized(nrBytes)}");
            cpu.FreeRegister(reg);
        }
        public void LeaFunctionVariable64(string variableName) => CodeIR("lea", "rax", $"qword [rbp-{variableName}]");
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
                CodeIR("lea", "rax", $"qword [rbp-{variableName}]");
            else
                CodeIR("mov", "rax", $"qword [rbp-{variableName}]");
        }
        public void LeaParentFunctionVariable64(string variableName) => CodeIR("lea", "rax", $"qword [rcx-{variableName}]");
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
                CodeIR("mov", "rax", $"qword [rcx-{variableName}]");
        }
        public void LeaFunctionParameter64(string variableName) => CodeIR("lea", "rax", $"qword [rbp+{variableName}]");
        public void LoadFunctionParameter64(string variableName) => CodeIR("mov", "rax", $"qword [rbp+{variableName}]");
        public void LoadFunctionParameter64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint)) {
                if (datatype.SizeInBytes == 8)
                    Codeline($"movq  xmm0, qword [rbp+{variableName}]");
                if (datatype.SizeInBytes == 4)
                    Codeline($"movd  xmm0, dword [rbp+{variableName}]");
            }
            else
                CodeIR("mov", "rax", $"qword [rbp+{variableName}]");
        }

        public void LoadFunction(string functionName)
        {
            CodeIR("mov", "rax", $"{functionName}");
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
                CodeIR("mov", $"qword [rbp+{variableName}]", "rax");
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
                Codeline($"push  rax");
                Codeline($"push  rcx");
                Codeline($"lea   rcx, qword [rbp-{variableName}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx");
                Codeline($"pop   rax");
            }
            else
            {
                // You might ask why only rax is used and not eax, ax, al based on the datatype. Like this:
                // string reg = cpu.RAX_Register_Sized(datatype.SizeInBytes);
                // Because a byte in de stack will misalign the stack horribly. And also, local variables are
                // not arrays, so they take not so much space. It is not like the programmer will be defining 300
                // byte variables. In that case, an array is created by the programmer those objects are a pointer.
                CodeIR("mov", $"qword [rbp-{variableName}]", "rax");
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
                Codeline($"push  rax");
                Codeline($"push  rcx");
                Codeline($"lea   rcx, qword [rcx-{variableName}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx");
                Codeline($"pop   rax");
            }
            else
                CodeIR("mov", $"[rcx-{variableName}]", "rax");
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
                Codeline($"push  rax");
                Codeline($"push  rcx");
                Codeline($"lea   rcx, qword [{reg}+{instVar}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx");
                Codeline($"pop   rax");
            }
            else
            {
                var nrBytes = targetType.SizeInBytes;
                CodeIR("mov", $"{cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}]", $"{cpu.RAX_Register_Sized(nrBytes)}");
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
            else if (datatype.Contains(Datatype.TypeEnum.CustomClass))
            {
                Codeline($"lea   rax, qword [{reg}+{instVar}]");
            }
            else
            {
                var nrBytes = datatype.SizeInBytes;
                if (nrBytes < 4)
                    Codeline($"xor   rax, rax");

                CodeIR("mov", $"{cpu.RAX_Register_Sized(nrBytes)}", $"{cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}]");
            }
        }

        public void LeaInstanceVar(string instVar, string reg, Datatype datatype)
        {
            var nrBytes = datatype.SizeInBytes;
            CodeIR("lea", "rax", $"{cpu.FasmSizeIndicator(nrBytes)} [{reg}+{instVar}]");
        }

        public void IncrementCurrent()
        {
            CodeIR("inc", "rax");
        }
        public void DecrementCurrent()
        {
            CodeIR("dec", "rax");
        }

        public void ReserveOnStack(int space, string register = "rax")
        {
            int toReserve = space;
            int onder15 = (space & 0xf);
            if (onder15 > 0)
                toReserve = space - onder15 + 16;

            FramePosition += toReserve;
            CodeIR("lea", $"{register}", $"[rbp-{FramePosition}]");
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
                CodeIR("pop", $"{ register ?? "rax" }");
                StackPop();
            }
        }

        public void MoveCurrentToRegister(string reg) => CodeIR("mov", $"{reg}", "rax");

        public void StoreCurrentInBasedIndex(int nrBytes, string baseReg, int index, Datatype targetType)
        {
            if (targetType.Contains(Datatype.TypeEnum.String))
            {
                // rax = source   rcx = destination
                Codeline($"push  rax");
                Codeline($"push  rcx");
                Codeline($"lea   rcx, qword [{baseReg}+{index}*{nrBytes}]");
                Codeline($"call  CopyString");
                Codeline($"pop   rcx");
                Codeline($"pop   rax");
                return;
            }
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                if (targetType.SizeInBytes == 8)
                    Codeline($"movq  rax, xmm0");  // below, the basereg+index cannot be done with xmm0
                if (targetType.SizeInBytes == 4)
                    Codeline($"movd  eax, xmm0");  // below, the basereg+index cannot be done with xmm0
            }
            CodeIR("mov", $"[{baseReg}+{index}*{nrBytes}]", $"{cpu.RAX_Register_Sized(nrBytes)}");
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
            CodeIR("mov", $"[{baseReg}+({indexReg}*{nrBytes})]", $"{cpu.RAX_Register_Sized(nrBytes)}");
        }

        public void SignExtend(Datatype theType)
        {
            if (theType.IsValueType && theType.Contains(Datatype.TypeEnum.Signed) && theType.Contains(Datatype.TypeEnum.Integer) && theType.SizeInBytes < 8)
                CodeIR("movsx", "rax", $"{cpu.RAX_Register_Sized(theType.SizeInBytes)}");
        }

        public void LoadBasedIndexToCurrent(int nrBytes, string baseReg, string indexReg, Datatype targetType)
        {
            CodeIR("xor", "eax", "eax");
            if (nrBytes >= 16 && Utils.IsLog2(nrBytes))
            {
                string reg = cpu.GetTmpRegister();
                CodeIR("mov", $"{reg}", $"{indexReg}");
                CodeIR("shl", $"{reg}", $"{Math.Log2(nrBytes)}");
                CodeIR("lea", "rax", $"[{baseReg}+{reg}]");
                cpu.FreeRegister(reg);
            }
            else if (nrBytes == 1 || nrBytes == 2 || nrBytes == 4 || nrBytes == 8)
                CodeIR("mov", $"{cpu.RAX_Register_Sized(nrBytes)}", $"[{baseReg}+({indexReg}*{nrBytes})]");
            else
                Compiler.Error($"LoadBasedIndexToCurrent: Index of {nrBytes} is not supported.");

            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint) && (targetType.SizeInBytes == 8))
                CodeIR("movq", "xmm0", "rax");
            if (targetType.Contains(Datatype.TypeEnum.FloatingPoint) && (targetType.SizeInBytes == 4))
                CodeIR("movd", "xmm0", "eax");
        }

        public void LeaBasedIndexToCurrent(int nrBytes, string baseReg, string indexReg, Datatype targetType)
        {
            CodeIR("xor", "eax", "eax");
            //if (targetType.Contains(Datatype.TypeEnum.String) && nrBytes == 256)
            if (nrBytes >= 16 && Utils.IsLog2(nrBytes))
            {
                string reg = cpu.GetTmpRegister();
                CodeIR("mov", $"{reg}", $"{indexReg}");
                CodeIR("shl", $"{reg}", $"{Math.Log2(nrBytes)}");
                CodeIR("lea", "rax", $"[{baseReg}+{reg}]");
                cpu.FreeRegister(reg);
            }
            else if (nrBytes == 1 || nrBytes == 2 || nrBytes == 4 || nrBytes == 8)
                CodeIR("lea", $"{cpu.RAX_Register_Sized(nrBytes)}", $"[{baseReg}+({indexReg}*{nrBytes})]");
            else
                Compiler.Error($"LeaBasedIndexToCurrent: Index of {nrBytes} is not supported.");
        }

        public void LeaBasedIndex(int nrBytes, string baseReg, string indexReg)
        {
            if (nrBytes != 1 && nrBytes != 2 && nrBytes != 4 && nrBytes != 8)
            {
                cpu.ReserveRegister("rdx");
                CodeIR("mov", "rax", $"{nrBytes}");
                CodeIR("mov", "rdx", $"{indexReg}");
                CodeIR("mul", "rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
                CodeIR("mov", $"{indexReg}", "rax");
                CodeIR("lea", "rax", $"[{baseReg}+{indexReg}]");
                cpu.FreeRegister("rdx");
            }
            else
                CodeIR("lea", "rax", $"[{baseReg}+({indexReg}*{nrBytes})]");
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
                CodeIR("and", "rax", "0xff");
            else if (newNrBytes == 2)
                CodeIR("and", "rax", "0xffff");
            else if (newNrBytes == 4)
                CodeIR("mov", "eax", "eax");
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

                if (session.CompileForNASM)
                {
                    if (preprocessorDefines[key]?.Datatype?.Contains(Datatype.TypeEnum.FloatingPoint) ?? false)
                        GeneratedCode_Equates.Add($"%define GC_{key} {preprocessorDefines[key].Lexeme}\r\n");
                    else
                        GeneratedCode_Equates.Add($"GC_{key} equ {preprocessorDefines[key].Lexeme}\r\n");
                }
                else
                    GeneratedCode_Equates.Add($"GC_{key} = {preprocessorDefines[key].Lexeme}\r\n");
            }
        }
    }
}
