using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Scope;
using static GroundCompiler.Scope.Symbol;

namespace GroundCompiler
{
    public class CodeEmitterX64
    {
        public CPU_X86_64 cpu;
        public List<string> generatedCode;
        long labelCounter = 0;
        bool generateGuiApplication = true;

        public CodeEmitterX64(CPU_X86_64 cpu, bool generateGuiApplication)
        {
            this.cpu = cpu;
            generatedCode = new List<string>();
            this.generateGuiApplication = generateGuiApplication;
        }
        public string GetGeneratedCode()
        {
            return string.Join("", generatedCode);
        }

        // The ActiveExpression helps the emitter to choose between Integer or Float operations. 
        public GroundCompiler.AstNodes.Expression? ActiveExpression = null;

        public void Writeline(string text) { generatedCode.Add(text + "\r\n"); }
        public void Codeline(string text) { Writeline($"  {text}"); }
        public string NewLabel() { return $"L{labelCounter++}"; }

        private string GetAsmFile() => this.generateGuiApplication ? File.ReadAllText("..\\..\\..\\base_gui.asm.txt") : File.ReadAllText("..\\..\\..\\base_console.asm.txt");
        public void BeforeMainCode() => generatedCode.Add(GetAsmFile().Split(";INSERTIONPOINT\r\n")[0]);
        public void AfterMainCode() => generatedCode.Add(GetAsmFile().Split(";INSERTIONPOINT\r\n")[1]);
        public void AfterFunctions() => generatedCode.Add(GetAsmFile().Split(";INSERTIONPOINT\r\n")[2]);

        public void EmitLiteralFloats(List<Scope.Symbol.FloatConstantSymbol> globalLiteralFloats)
        {
            foreach (var variable in globalLiteralFloats)
            {
                string quoted = ((double)variable.Value).ToString("0.0000000000", CultureInfo.InvariantCulture);
                Writeline($"{variable.SymbolRefId} dq {quoted}");
            }
        }

        public void EmitStrings(List<Scope.Symbol.StringConstantSymbol> globalStrings)
        {
            foreach (var variable in globalStrings)
            {
                string quoted = EmitQuotedAssemblyString((string)variable.Value);
                if (quoted == "''")
                    Writeline($"{variable.SymbolRefId} db 0");
                else
                    Writeline($"{variable.SymbolRefId} db {quoted},0");
            }
        }

        public void EmitFixedStringIndexSpaceEntries(List<Scope.Symbol.StringConstantSymbol> globalStrings)
        {
            int indexspaceRownr = 1;
            cpu.ReserveRegister("rcx");
            foreach (var variable in globalStrings)
            {
                Codeline($"lea   rcx, [{variable.SymbolRefId}]");
                Codeline($"call  AddFixedString");
                variable.IndexspaceRownr = indexspaceRownr;
                indexspaceRownr++;
            }
            cpu.FreeRegister("rcx");
        }

        public string EmitQuotedAssemblyString(string text)
        {
            text = text.Replace("\r", "',13,'").Replace("\n", "',10,'");
            return $"'{text}'".Replace(",''", "").Replace("'',", "");
        }

        public void CreateStackframe()
        {
            Codeline($"push  rbp");         // this line makes the value at [rbp] always the parent
            Codeline($"mov   rbp, rsp");
        }

        public void ReserveStackspace(int stackSpaceNeeded, bool insertRefCountBlock = true)
        {
            Codeline($"sub   rsp, {stackSpaceNeeded}");
            if (insertRefCountBlock)
            {
                Codeline($"mov   qword [rbp-G_FIRST_REFCOUNT_PTR], 0");
                Codeline($"mov   qword [rbp-G_LAST_REFCOUNT_PTR], 0");
                Codeline($"mov   qword [rbp-G_FIRST_TMPREFCOUNT_PTR], 0");
                Codeline($"mov   qword [rbp-G_LAST_TMPREFCOUNT_PTR], 0");
            }
        }

        public void EndFunction(int returnPop = 0, bool noFrameRestoration = false)
        {
            if (!noFrameRestoration)
            {
                Codeline($"mov   rsp, rbp");
                Codeline($"pop   rbp");
            }
            if (returnPop > 0)
                Codeline($"retn  {returnPop}\r\n");
            else
                Codeline($"ret\r\n");
        }

        public void CallFunction(FunctionSymbol f, AstNodes.Expression expr)
        {
            bool needsTmpReference = f.FunctionStatement.ResultDatatype?.IsReferenceType ?? false;
            if (needsTmpReference)
                cpu.ReserveRegister("rcx");

            string assemblyFunctionname = ConvertToAssemblyFunctionName(f.FunctionStatement.Name.Lexeme, f.FunctionStatement.GetGroupName());
            Codeline($"call  {assemblyFunctionname}");

            if (needsTmpReference)
            {
                Codeline("mov   rcx, rbp");
                AddTmpReference(expr);
                cpu.FreeRegister("rcx");
            }
        }

        public void LoadConstantString(int indexSpaceRownr)
        {
            Codeline($"mov   rax, {indexSpaceRownr}");
        }

        public void LoadNull()
        {
            Codeline($"xor   eax, eax");
        }


        public void LoadConstant64(Int64 value)
        {
            Codeline($"mov   rax, {value}");
        }

        public void LoadConstantFloat64(string name)
        {
            Codeline($"movq  xmm0, qword [{ name }]");
        }

        public void LoadConstantUInt64(UInt64 value)
        {
            Codeline($"mov   rax, {value}");
        }
        public void LoadAssemblyVariable(string name) => Codeline($"mov   rax, [{name}]");
        public void LoadAssemblyConstant(string name) => Codeline($"mov   rax, {name}");

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

        public void Push()
        {
            if (ActiveExpression?.ExprType.Contains(Datatype.TypeEnum.FloatingPoint) ?? false)
                PushFloat();
            else
                Codeline($"push  rax");
        }

        public void PushFloat()
        {
            Codeline($"sub   rsp, 16");
            Codeline($"movq  qword [rsp], xmm0");
        }

        public void PopFloat()
        {
            Codeline($"movq  xmm0, qword [rsp]");
            Codeline($"add   rsp, 16");
        }

        public void PopAddStrings()
        {
            cpu.ReserveRegister("rcx");
            cpu.ReserveRegister("rdx");
            Codeline("pop   rcx");
            Codeline("mov   rdx, rax");
            Codeline("call  AddCombinedStrings");       // rcx wijst naar eerste string, rdx wijst naar tweede string
            Codeline("mov   rcx, rbp");
            AddTmpReference(ActiveExpression!);
            cpu.FreeRegister("rdx");
            cpu.FreeRegister("rcx");
        }

        public void PopAdd()
        {
            if (ActiveExpression != null && ActiveExpression.ExprType.Name == "string")
            {
                // We do string concatenation, this allocates memory. Clean the references so memory won't get drained when we are in a loop. 
                var blockType = ActiveExpression.FindParentType(typeof(BlockStatement)) as BlockStatement;
                if (blockType != null)
                    blockType!.shouldCleanDereferenced = true;

                PopAddStrings();
                return;
            }

            if (ActiveExpression != null && ActiveExpression.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                Codeline($"movq   {floatReg}, xmm0");
                Codeline($"movq  xmm0, qword [rsp]");
                Codeline($"add   rsp, 16");
                Codeline($"addsd   xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Codeline($"pop   rax");
            Codeline($"add   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopSub()
        {
            if (ActiveExpression != null && ActiveExpression.ExprType.Contains(Datatype.TypeEnum.String))
            {
                // We have the situation that in string comparison there can be a null value in both arguments.
                var nullExitLabel = NewLabel();
                var strCmpLabel = NewLabel();
                var secondArgNull = NewLabel();
                cpu.ReserveRegister("rcx");
                cpu.ReserveRegister("rdx");
                Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                Codeline($"jne    {strCmpLabel}");
                Codeline($"mov    rcx, rax");
                Codeline($"pop    rax");
                InsertLabel(secondArgNull);
                Codeline($"sub    rax, rcx");
                Codeline($"jmp    {nullExitLabel}");
                InsertLabel(strCmpLabel);
                Codeline($"call   GetMemoryPointerFromIndex");
                Codeline($"mov    rcx, rax");
                Codeline($"pop    rax");
                Codeline($"cmp    rax, 0");         // Are we checking for a null value? In that case do not do a string comparison
                Codeline($"je     {secondArgNull}");
                Codeline($"call   GetMemoryPointerFromIndex");
                Codeline($"mov    rdx, rax");
                Codeline($"sub    rsp, 20h");
                Codeline($"call   [msvcrt_strcmp]");
                Codeline($"add    rsp, 20h");
                InsertLabel(nullExitLabel);
                cpu.FreeRegister("rdx");
                cpu.FreeRegister("rcx");
                return;
            }

            if (ActiveExpression != null && ActiveExpression.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                Codeline($"movq   {floatReg}, xmm0");
                Codeline($"movq  xmm0, qword [rsp]");
                Codeline($"add   rsp, 16");
                Codeline($"subsd   xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Codeline($"pop   rax");
            Codeline($"sub   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopMul()
        {
            if (!(ActiveExpression?.ExprType.Contains(Datatype.TypeEnum.Number) ?? false))
                Compiler.Error("CodeEmitterX64>>PopMul: Cannot multiply expressions that are not numbers.");

            if (ActiveExpression != null && ActiveExpression.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                Codeline($"movq   {floatReg}, xmm0");
                Codeline($"movq  xmm0, qword [rsp]");
                Codeline($"add   rsp, 16");
                Codeline($"mulsd   xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            cpu.ReserveRegister("rdx");
            Codeline($"mov   rdx, rax");
            Codeline($"pop   rax");
            Codeline($"mul   rdx");   // rdx will be normally be destroyed anyway by the result being stored in rdx:rax
            cpu.FreeRegister("rdx");
        }

        public void PopDiv()
        {
            if (ActiveExpression != null && ActiveExpression.ExprType.Contains(Datatype.TypeEnum.FloatingPoint))
            {
                var floatReg = cpu.GetTmpFloatRegister();
                Codeline($"movq   {floatReg}, xmm0");
                Codeline($"movq  xmm0, qword [rsp]");
                Codeline($"add   rsp, 16");
                Codeline($"divsd   xmm0, {floatReg}");
                cpu.FreeRegister(floatReg);
                return;
            }

            var reg = cpu.GetTmpRegister();
            cpu.ReserveRegister("rdx");
            Codeline($"mov   {reg}, rax");
            Codeline($"xor   rdx, rdx");    // always clean rdx before division
            Codeline($"pop   rax");
            Codeline($"div   {reg}");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseAnd()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Codeline($"pop   rax");
            Codeline($"and   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopModulo()
        {
            var reg = cpu.GetTmpRegister();
            cpu.ReserveRegister("rdx");
            Codeline($"mov   {reg}, rax");
            Codeline($"xor   edx, edx");        // always clean rdx before division
            Codeline($"pop   rax");
            Codeline($"div   {reg}");
            Codeline($"mov   eax, edx");
            cpu.FreeRegister("rdx");
            cpu.FreeRegister(reg);
        }

        public void PopBitwiseOr()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"mov   {reg}, rax");
            Codeline($"pop   rax");
            Codeline($"or   rax, {reg}");
            cpu.FreeRegister(reg);
        }

        public void PopGreaterToBoolean()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");             // expr 3 > 2.
            Codeline($"sub   rax, {reg}");        // sub 2, 3 (2 - 3) -> carry is set
            Codeline($"mov   eax, 0");
            Codeline($"adc   eax, 0");          // carry is added as 1, so result = 1 (value true).
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopLessToBoolean()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            Codeline($"sub   {reg}, rax");
            Codeline($"mov   eax, 0");
            Codeline($"adc   eax, 0");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopGreaterEqualToBoolean()
        {
            PopLessToBoolean();
            LogicalNot();
        }

        public void PopLessEqualToBoolean()
        {
            PopGreaterToBoolean();
            LogicalNot();
        }

        public void Logical()
        {
            Codeline($"neg   rax");         // if rax != 0 => carry flag is set
            Codeline($"mov   eax, 0");
            Codeline($"adc   eax, 0");
            // int64 rax 0, bool rax becomes 0
            // int64 rax != 0, bool rax becomes 1
        }

        public void LogicalNot()
        {
            Codeline($"neg   rax");         // if rax != 0 => carry flag is set
            Codeline($"mov   eax, 1");
            Codeline($"sbb   eax, 0");
            // int64 rax 0, bool rax becomes 1
            // int64 rax != 0, bool rax becomes 0
        }

        public void PopOr()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            Codeline($"or   rax, {reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
        }

        public void PopAnd()
        {
            var reg = cpu.GetTmpRegister();
            Codeline($"pop   {reg}");
            Codeline($"and   rax, {reg}");
            // bool rax 1 = true, bool rax 0 = false;
            cpu.FreeRegister(reg);
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

        public void StoreFunctionVariable64(string variableName, Datatype datatype)
        {
            if (datatype.Contains(Datatype.TypeEnum.FloatingPoint))
                Codeline($"movq  qword [rbp-{variableName}], xmm0");
            else
                Codeline($"mov   qword [rbp-{variableName}], rax");
        }

        public void StoreParentFunctionParameter64(string variableName)
        {
            Codeline($"mov   [rcx-{variableName}], rax");
        }

        public string Gather_ParentStackframe(int levelDeep)
        {
            cpu.ReserveRegister("rcx");
            if (levelDeep < 1)
                Compiler.Error("Parent not found.");

            int loopNr = levelDeep - 1;
            Codeline("mov   rcx, [rbp]");
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

        public void LoadFunctionVariable64(string variableName)
        {
            Codeline($"mov   rax, qword [rbp-{variableName}]");
        }
        public void LoadFunctionVariableFloat64(string variableName)
        {
            Codeline($"movq  xmm0, qword [rbp-{variableName}]");
        }

        public void LoadParentFunctionVariable64(string variableName)
        {
            Codeline($"mov   rax, qword [rcx-{variableName}]");
        }
        public void LoadFunctionParameter64(string variableName)
        {
            Codeline($"mov   rax, qword [rbp+{variableName}]");
        }
        public void IncrementCurrent()
        {
            Codeline($"inc   rax");
        }
        public void DecrementCurrent()
        {
            Codeline($"dec   rax");
        }

        public void GetMemoryPointerFromIndex()
        {
            Codeline("call  GetMemoryPointerFromIndex");
        }

        public void IntegerToString(AstNodes.Expression expr)
        {
            cpu.ReserveRegister("rcx");
            Codeline("call  IntegerToString");
            Codeline("mov   rcx, rbp");
            AddTmpReference(expr);
            cpu.FreeRegister("rcx");
        }

        public void FloatToString(AstNodes.Expression expr)
        {
            cpu.ReserveRegister("rcx");
            Codeline($"call  FloatToString");
            Codeline("mov   rcx, rbp");
            AddTmpReference(expr);
            cpu.FreeRegister("rcx");
        }

        public void IntegerToFloat()
        {
            Codeline("cvtsi2sd xmm0, rax");
        }

        public void InsertLabel(string label)
        {
            Writeline($"{label}:");
        }

        public string ConvertToAssemblyFunctionName(string functionName, string? groupName = null) => $"_f_{functionName}" + ((groupName != null) ? $"@{groupName}" : "");

        public string ConvertToAssemblyClassName(string className)
        {
            return $"_c_{className}";
        }

        public string AssemblyVariableName(Scope.Symbol.LocalVariableSymbol varSymbol, IScopeStatement? scopeStmt)
        {
            return AssemblyVariableNameForFunctionParameter(scopeStmt!.GetScopeName().Lexeme, varSymbol.Name);
        }

        public string AssemblyVariableName(Scope.Symbol.FunctionParameterSymbol varSymbol)
        {
            return AssemblyVariableNameForFunctionParameter(varSymbol.TheFunction.Name.Lexeme, varSymbol.FunctionParameter.Name);
        }

        public string AssemblyVariableName(string name, IScopeStatement? scopeStmt)
        {
            return AssemblyVariableNameForFunctionParameter(scopeStmt!.GetScopeName().Lexeme, name);
        }

        public string AssemblyVariableNameForClassInstanceVariable(string functionName, string parName)
        {
            string part1 = ConvertToAssemblyClassName(functionName);
            string part2 = parName;
            return $"{part1}@{part2}";
        }

        public string AssemblyVariableNameForFunctionParameter(string functionName, string parName, string? groupName = null)
        {
            string part1 = ConvertToAssemblyFunctionName(functionName);
            string part2 = parName;
            return $"{part1}@{part2}" + ((groupName != null) ? $"@{groupName}" : "");
        }
        public string UserfriendlyVariableNameForFunctionParameter(string functionName, string parName, string? groupName = null)
        {
            string part1 = functionName;
            string part2 = parName;
            return $"{part2}@{part1}" + ((groupName != null) ? $"@{groupName}" : "");
        }

        public void CleanDereferenced()
        {
            cpu.ReserveRegister("rcx");
            Codeline("mov   rcx, rbp");               // rcx must contain the base of the stack of the function
            Codeline("call  RemoveDereferenced");
            cpu.FreeRegister("rcx");
        }

        public void CleanTmpDereferenced()
        {
            cpu.ReserveRegister("rcx");
            Codeline("mov   rcx, rbp");               // rcx must contain the base of the stack of the function
            Codeline("call  RemoveTmpDereferenced");
            cpu.FreeRegister("rcx");
        }

        public void RemoveReference()
        {
            Codeline("call  RemoveReference");
        }

        public void AddReference(AstNodes.Expression expr)
        {
            // rcx must contain the base of the stack of the function
            Codeline("call  AddReference");
            var blockType = expr.FindParentType(typeof(BlockStatement)) as BlockStatement;
            if (blockType == null)
                Compiler.Error("AddTmpReference: no blockType found.");

            blockType!.shouldCleanDereferenced = true;
        }

        public void AddTmpReference(AstNodes.Expression expr)
        {
            // rcx must contain the base of the stack of the function
            Codeline("call  AddTmpReference");
            var blockType = expr.FindParentType(typeof(BlockStatement)) as BlockStatement;
            if (blockType == null)
                Compiler.Error("AddTmpReference: no blockType found.");

            blockType!.shouldCleanTmpDereferenced = true;
        }

        public void Allocate(UInt64 nrBytes)
        {
            cpu.ReserveRegister("rcx");
            Codeline($"mov   rcx, {nrBytes}");
            Codeline($"call  GC_Allocate");   //; INPUT: rcx contains the requested size     ; RESULT: rcx = INDEXSPACE rownr, rax = memptr
            cpu.FreeRegister("rcx");
        }

        public void PushAllocateIndexElement()
        {
            Codeline("push  rcx");
        }

        public void Pop()
        {
            if (ActiveExpression?.ExprType.Contains(Datatype.TypeEnum.FloatingPoint) ?? false)
                PopFloat();
            else
                Codeline("pop   rax");
        }
        public void PopAllocateIndexElement() => Codeline("pop   rax");

        public void MoveCurrentToRegister(string reg) => Codeline($"mov   {reg}, rax");

        public void StoreCurrentInBasedIndex(int nrBytes, string baseReg, int index)
        {
            Codeline($"mov   [{baseReg}+{index}*{nrBytes}], {cpu.RAX_Register_Sized(nrBytes)}");
        }
        public void StoreCurrentInBasedIndex(int nrBytes, string baseReg, string indexReg)
        {
            Codeline($"mov   [{baseReg}+({indexReg}*{nrBytes})], {cpu.RAX_Register_Sized(nrBytes)}");
        }
        public void LoadBasedIndexToCurrent(int nrBytes, string baseReg, string indexReg)
        {
            Codeline($"xor   eax, eax");
            Codeline($"mov   {cpu.RAX_Register_Sized(nrBytes)}, [{baseReg}+({indexReg}*{nrBytes})]");
        }

    }
}
