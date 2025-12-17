using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class CPU_X86_64
    {
        public Dictionary<string, string> reservedRegisters;
        public List<string> _tmpRegisters = new List<string>() { "r8", "r9", "r10", "r11", "rdx", "rcx" };      // RAX cannot be reserved, because it can always be used.
        public List<string> _tmpFloatRegisters = new List<string>() { "xmm1", "xmm2", "xmm3", "xmm4", "xmm5" };     // XMM0 cannot be reserved, because it can always be used.
        public List<string> _restoredFloatRegisters = new List<string>() { "xmm6", "xmm7", "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15" };
        public List<string> _restoredRegisters = new List<string>() { "rbx", "rsi", "rdi", "r12", "r13", "r14", "r15" };    // rbp, rsp

        public CPU_X86_64()
        {
            reservedRegisters = new Dictionary<string, string>();
        }

        public string GetTmpRegister(string usage = "")
        {
            foreach (var reg in _tmpRegisters)
                if (!reservedRegisters.ContainsKey(reg))
                {
                    reservedRegisters[reg] = usage;
                    return reg;
                }
            Step6_Compiler.Error("No free register in GetTmpRegister.");
            return "";
        }

        public string GetRestoredRegister(Expression? exp = null)
        {
            foreach (var reg in _restoredRegisters)
                if (!reservedRegisters.ContainsKey(reg))
                {
                    reservedRegisters[reg] = "";
                    if (exp != null)
                    {
                        var functionStat = exp.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                        functionStat?.AddUsedRegister(reg);
                    }
                    return reg;
                }
            Step6_Compiler.Error("No free register in GetRestoredRegister.");
            return "";
        }

        public string GetTmpFloatRegister(string usage = "")
        {
            foreach (var reg in _tmpFloatRegisters)
                if (!reservedRegisters.ContainsKey(reg))
                {
                    reservedRegisters[reg] = usage;
                    return reg;
                }
            Step6_Compiler.Error("No free register in GetTmpFloatRegister.");
            return "";
        }

        public string GetRestoredFloatRegister(Expression? exp = null)
        {
            foreach (var reg in _restoredFloatRegisters)
                if (!reservedRegisters.ContainsKey(reg))
                {
                    reservedRegisters[reg] = "";
                    if (exp != null)
                    {
                        var functionStat = exp.FindParentType(typeof(FunctionStatement)) as FunctionStatement;
                        functionStat?.AddUsedRegister(reg);
                    }
                    return reg;
                }
            Step6_Compiler.Error("No free register in GetRestoredFloatRegister.");
            return "";
        }

        public void FreeRegister(string reg) {
            reservedRegisters.Remove(reg);
        }

        public void ReserveRegister(string reg, string usage = "")
        {
            if (reservedRegisters.ContainsKey(reg))
                Step6_Compiler.Error($"CPU_X86_64: ReserveRegister {reg} failed.");

            reservedRegisters[reg] = usage;
        }

        public string RAX_Register_Sized(int nrBytes)
        {
            switch (nrBytes)
            {
                case 1:
                    return "al";
                case 2:
                    return "ax";
                case 4:
                    return "eax";
                case 8:
                default:
                    return "rax";
            }
        }

        public string FasmSizeIndicator(int nrBytes)
        {
            switch (nrBytes)
            {
                case 1:
                    return "byte";
                case 2:
                    return "word";
                case 4:
                    return "dword";
                case 8:
                default:
                    return "qword";
            }
        }

    }
}
