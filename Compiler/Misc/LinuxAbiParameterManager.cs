using GroundCompiler.Expressions;
using GroundCompiler.Statements;

namespace GroundCompiler;

public class LinuxAbiParameterManager
{
    /* The System V AMD64 ABI is difficult.
     * Large structs > 16 bytes is stored on the stack.
     * Struct > 8 bytes <= 16 bytes is stored in two registers. You cannot distribute them over a register and the stack.
     * Struct <= 8 bytes must be integer if one value is integer. If all is float, than it is a float register.
     */
    
    private CPU_X86_64 cpu;
    private CodeEmitter emitter;
    public int integerRegisterIndex = 0; // 6 registers, rdi, rsi, rdx, rcx, r8, r9
    public int floatRegisterIndex = 0;  // 8 registers xmm0-xmm7
    public int nrRegistersOnStack = 0; // remaining parameters are put on the stack. This is the number of 64 bit stack elements
    public int linuxCopyResultBytes = 0;
    public DllFunctionSymbol dllFunctionSymbol;
    public List<string> registerAllocation;
    public int totalStackByteSize = 0;

    public LinuxAbiParameterManager(CPU_X86_64 theCpu,  CodeEmitter theEmitter, DllFunctionSymbol theDllFunctionSymbol)
    {
        this.cpu = theCpu;
        this.emitter = theEmitter;
        integerRegisterIndex = 0;
        floatRegisterIndex = 0;
        linuxCopyResultBytes = 0;
        totalStackByteSize = 0;
        nrRegistersOnStack = 0;
        this.dllFunctionSymbol = theDllFunctionSymbol;
        registerAllocation = new List<string>();
    }

    public void getFloatRegister(FunctionParameter par)
    {
        // xmm0 t/m xmm7
        if (floatRegisterIndex > 7 || (integerRegisterIndex == 7 && par.Properties.ContainsKey(FunctionParameterPropKey.LinuxTwoRegisterParameter)))
        {
            par.Properties[FunctionParameterPropKey.LinuxNormalParameterOnStack] = true;
            nrRegistersOnStack++;
            par.Properties[FunctionParameterPropKey.LinuxParameterStackOffset] = totalStackByteSize;
            totalStackByteSize += 8;
        }
        else
        {
            string theRegister = $"xmm{floatRegisterIndex}";
            registerAllocation.Add(theRegister);
            floatRegisterIndex++;
        }
    }

    public void getIntegerRegister(FunctionParameter par)
    {
        // Bij een LinuxTwoRegisterParameter mag je de parameter niet splitsen over een register en de stack. 

        // 0=rdi  1=rsi  2=rdx  3=rcx  4=r8  5=r9
        if (integerRegisterIndex > 5 || (integerRegisterIndex == 5 && par.Properties.ContainsKey(FunctionParameterPropKey.LinuxTwoRegisterParameter)))
        {
            par.Properties[FunctionParameterPropKey.LinuxNormalParameterOnStack] = true;
            nrRegistersOnStack++;
            par.Properties[FunctionParameterPropKey.LinuxParameterStackOffset] = totalStackByteSize;
            totalStackByteSize += 8;
        }
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
        totalStackByteSize = 0;

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
                if (nrBytes <= 8)
                {
                    par.Properties[FunctionParameterPropKey.LinuxOneRegisterParameter] = true;
                    var classStatement = dt.Properties["classStatement"] as ClassStatement;
                    var varStList = classStatement!.InstanceVariableNodes;
                    bool willBeFloatParameter = true;
                    foreach (var varSt in varStList)
                        if (!varSt.ResultType.Contains(Datatype.TypeEnum.FloatingPoint))
                            willBeFloatParameter = false;

                    if (willBeFloatParameter)
                        getFloatRegister(par);
                    else
                        getIntegerRegister(par);

                    continue;
                }
                else if (nrBytes > 8 && nrBytes <= 16)
                {
                    par.Properties[FunctionParameterPropKey.LinuxTwoRegisterParameter] = true;
                    var classStatement = dt.Properties["classStatement"] as ClassStatement;
                    var varStList = classStatement!.InstanceVariableNodes;
                    bool willBeFloatParameter = true;
                    int nrByteCounter = 0;
                    bool reg1Set = false;
                    foreach (var varSt in varStList)
                    {
                        bool currentIsFloat = varSt.ResultType.Contains(Datatype.TypeEnum.FloatingPoint);
                        nrByteCounter += varSt.ResultType.SizeInBytes;

                        if (nrByteCounter > 8 && !reg1Set)
                        {
                            // Dit komt voor als een 4 byte variabele wordt gevolgd door een 8 byte variabele.
                            // We moeten dan eerst het type van de 4 byte variabele gebruiken.

                            // register 1
                            if (willBeFloatParameter)
                                getFloatRegister(par);
                            else
                                getIntegerRegister(par);

                            willBeFloatParameter = true;
                            nrByteCounter = 0; // without this we will return in this if-clause the next iteration.
                            reg1Set = true;

                            if (!currentIsFloat)
                                willBeFloatParameter = false;
                        }
                        else if (nrByteCounter == 8 && !reg1Set)
                        {
                            if (!currentIsFloat)
                                willBeFloatParameter = false;

                            // register 1
                            if (willBeFloatParameter)
                                getFloatRegister(par);
                            else
                                getIntegerRegister(par);

                            willBeFloatParameter = true;
                            nrByteCounter = 0; // without this we will return in this if-clause the next iteration.
                            reg1Set = true;
                        }
                        else
                            if (!currentIsFloat)
                                willBeFloatParameter = false;
                    }
                    // register 2
                    if (willBeFloatParameter)
                        getFloatRegister(par);
                    else
                        getIntegerRegister(par);

                    continue;
                }
                else if (nrBytes > 16)
                {
                    par.Properties[FunctionParameterPropKey.LinuxLargeParameterOnStack] = true;
                    par.Properties[FunctionParameterPropKey.LinuxParameterStackOffset] = totalStackByteSize;
                    par.Properties[FunctionParameterPropKey.LinuxParameterNrBytes] = nrBytes;
                    totalStackByteSize += nrBytes;
                    continue;
                }
            }

            if (dt.Contains(Datatype.TypeEnum.FloatingPoint))
                getFloatRegister(par);
            else
                getIntegerRegister(par);
        }

        if (totalStackByteSize > 0)
            totalStackByteSize = (totalStackByteSize + 15) & ~15;
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
                // In the System V AMD64 ABI, a result larger than 16 bytes is generally returned through a hidden pointer to caller-allocated memory, passed as the first argument in RDI.
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
            emitter.Codeline("mov   [rcx], rax");     // deze twee kloppen wel, want voor resultaten groter dan 16 wordt het resultaat in een pointer in RDI teruggegeven. Zie CheckForLargeResult.
            emitter.Codeline("mov   [rcx+8], rdx");
            emitter.Codeline("mov   rax, rcx");
            emitter.Codeline("pop   rcx");
        }
    }
    
}