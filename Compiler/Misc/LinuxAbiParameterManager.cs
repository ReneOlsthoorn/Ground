using System.Diagnostics;
using System.Globalization;
using System.Text;
using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler;

public class LinuxAbiParameterManager
{
    /* The system v amd64 abi is difficult. */
    
    private CPU_X86_64 cpu;
    private CodeEmitter emitter;
    public int integerRegisterIndex = 0; // 6 registers, rdi, rsi, rdx, rcx, r8, r9
    public int floatRegisterIndex = 0;  // 8 registers xmm0-xmm7
    public int stackNr = 0; // remaining parameters are put on the stack. This is the number of 64 bit stack elements
    public int linuxCopyResultBytes = 0;
    public DllFunctionSymbol dllFunctionSymbol;
    public List<string> registerAllocation;

    public LinuxAbiParameterManager(CPU_X86_64 theCpu,  CodeEmitter theEmitter, DllFunctionSymbol theDllFunctionSymbol)
    {
        this.cpu = theCpu;
        this.emitter = theEmitter;
        integerRegisterIndex = 0;
        floatRegisterIndex = 0;
        linuxCopyResultBytes = 0;
        stackNr = 0;
        this.dllFunctionSymbol = theDllFunctionSymbol;
        registerAllocation = new List<string>();
    }

    public void getFloatRegister()
    {
        if (floatRegisterIndex > 7)
            stackNr++;
        else
        {
            string theRegister = $"xmm{floatRegisterIndex}";
            registerAllocation.Add(theRegister);
            floatRegisterIndex++;
        }
    }

    public void getIntegerRegister()
    {
        if (integerRegisterIndex > 5)
            stackNr++;
        else
        {
            string theRegister = "";
            switch (integerRegisterIndex)
            {
                case 0:
                    theRegister = "rdi";
                    break;
                case 1:
                    theRegister = "rsi";
                    break;
                case 2:
                    theRegister = "rdx";
                    break;
                case 3:
                    theRegister = "rcx";
                    break;
                case 4:
                    theRegister = "r8";
                    break;
                case 5:
                    theRegister = "r9";
                    break;
            }
            registerAllocation.Add(theRegister);
            integerRegisterIndex++;
        }
    }

    public void Load(List<Expression> argNodes, List<FunctionParameter> functionParameters)
    {
        CheckForLargeResult();
        foreach (FunctionParameter par in functionParameters)
        {
            Datatype dt = par.TheType;

            if (dt.isClass())
            {
                // als je een class in een parameter zet, dan is het altijd een struct. 
                // onder linux moet je dan meerdere registers gebruiken om een 16 byte struct door te geven.
                // Deze register paren zijn al op de stack gezet. Dus dit is niet de enige plek waar de "TwoRegisters" bepaald worden.
                int nrBytes = dt.SizeInBytes;
                if (nrBytes > 8 && nrBytes <= 16)
                {
                    var classStatement = dt.Properties["classStatement"] as ClassStatement;
                    int newAddedRegisters = 0;
                    foreach (VarStatement vs in classStatement!.InstanceVariableNodes)
                    {
                        if (vs.ResultType.Contains(Datatype.TypeEnum.FloatingPoint))
                            getFloatRegister();
                        else
                            getIntegerRegister();

                        newAddedRegisters++;
                        if (newAddedRegisters == 2)
                            break;
                    }
                }
                continue;
            }
            else
            {
                if (dt.Contains(Datatype.TypeEnum.FloatingPoint))
                    getFloatRegister();
                else
                    getIntegerRegister();
            }
        }
    }

    public void CheckForLargeResult()
    {
        if (dllFunctionSymbol.FunctionStmt.ResultDatatype?.isClass() ?? false)
        {
            int nrBytes = dllFunctionSymbol.FunctionStmt.ResultDatatype.SizeInBytes;
            if (nrBytes > 8 && nrBytes <= 16)
                linuxCopyResultBytes = nrBytes;
                        
            if (nrBytes > 16)
            {
                emitter.ReserveOnStack(nrBytes, "rdi");
                this.integerRegisterIndex++;
            }
        }  
    }

    public void RetrieveLargerResult()
    {
        if (linuxCopyResultBytes > 0)
        {
            emitter.Codeline("push  rcx");
            emitter.ReserveOnStack(linuxCopyResultBytes, "rcx");
            emitter.Codeline("mov   [rcx], rax");
            emitter.Codeline("mov   [rcx+8], rdx");
            emitter.Codeline("mov   rax, rcx");
            emitter.Codeline("pop   rcx");
        }
    }
    
    public bool ReserveArgument(Expression expr)
    {
        string theRegister = "rax";
        int linuxInputInTwoRegisters = 0;
        
        if (expr.ExprType?.isClass() ?? false)
        {
            // als je een class in een parameter zet, dan is het altijd een struct. 
            // onder linux moet je dan meerdere registers gebruiken om een 16 byte struct door te geven.
            // Deze register paren zijn al op de stack gezet. Dus dit is niet de enige plek waar de "TwoRegisters" bepaald worden.
            int nrBytes = expr.ExprType.SizeInBytes;
            if (nrBytes > 8 && nrBytes <= 16)
                linuxInputInTwoRegisters = nrBytes;
        }
        int nrRegistersToReserve = (linuxInputInTwoRegisters > 0) ? 2 : 1;
        
        /*

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
            int nrRegisters = (linuxInputInTwoRegisters > 0) ? 2 : 1;

            if ((index + 1 + nrRegisters) > 6)
                return true;

            for (int i = 0; i < nrRegisters; i++)
            {
                switch (index)
                {
                    case 0:
                        theRegister = "rdi";
                        break;
                    case 1:
                        theRegister = "rsi";
                        break;
                    case 2:
                        theRegister = "rdx";
                        break;
                    case 3:
                        theRegister = "rcx";
                        break;
                    case 4:
                        theRegister = "r8";
                        break;
                    case 5:
                        theRegister = "r9";
                        break;
                }
                emitter.Pop(expr, theRegister);
                if (i != (nrRegisters - 1))
                    index++;
            }
        }
        */

        return false;
    }
}