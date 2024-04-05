using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using static GroundCompiler.AstNodes.Statement;
using static GroundCompiler.Scope;
using static GroundCompiler.Scope.Symbol;

namespace GroundCompiler
{
    public class EmittedProcedure
    {
        public string ProcedureName;
        public FunctionStatement FunctionStatement { get; set; }
        public CodeEmitterX64 Emitter { get; set; }
        public Action? MainCallback = null;     // callback which is called as main-part of the code generation.
        public int? StackSpaceToReserve = null;

        public EmittedProcedure(FunctionStatement functionStatement, CodeEmitterX64 emitter, string? name = null)
        {
            this.FunctionStatement = functionStatement;
            Emitter = emitter;
            ProcedureName = (name != null) ? name : this.FunctionStatement.Name.Lexeme;
        }

        public bool NeedsRefCount() => FunctionStatement.NeedsRefcountStructure();

        public int ReferenceCountPointersAllocationSize()
        {
            // The first 32 bytes are for G_FIRST_REFCOUNT_PTR, G_LAST_REFCOUNT_PTR, G_FIRST_TMPREFCOUNT_PTR and G_LAST_TMPREFCOUNT_PTR
            return 32;
        }

        public int AmountStackSpaceToReserve()
        {
            if (StackSpaceToReserve == null)
                Compiler.Error("AmountStackSpaceToReserve is not calculated yet!");

            return StackSpaceToReserve!.Value;
        }


        public void Emit_Equ_LocalVariables(bool emit = true)
        {
            List<Scope.Symbol.LocalVariableSymbol> theVariables = this.FunctionStatement.Body.GetScope()!.GetVariableSymbols();

            int negativeOffset = (NeedsRefCount() ? ReferenceCountPointersAllocationSize() : 0);
            foreach (var varSymbol in theVariables)
            {
                if (varSymbol.DataType.Types.Contains(Datatype.TypeEnum.CustomClass))
                {
                    ClassStatement classStatement = varSymbol.DataType.Properties["classStatement"] as ClassStatement;
                    negativeOffset += varSymbol.DataType.SizeInBytes;

                    var theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, varSymbol.Name);
                    Emitter.Writeline($"{theName} equ {negativeOffset}");
                    Emitter.Writeline($"{varSymbol.Name}@{ProcedureName} equ rbp-{negativeOffset}");    // negative from RBP, because the variables are stored in the procedure frame, so below RBP

                    foreach (var instVar in classStatement!.InstanceVariables)
                    {
                        negativeOffset += instVar.ResultType.SizeInBytes;

                        var instName = $"{varSymbol.Name}.{instVar.Name.Lexeme}";
                        theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, instName);
                        Emitter.Writeline($"{theName} equ {negativeOffset}");
                        Emitter.Writeline($"{instName}@{ProcedureName} equ rbp-{negativeOffset}");
                    }
                }
                else
                {
                    negativeOffset += varSymbol.DataType.SizeInBytes;

                    var theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, varSymbol.Name);
                    Emitter.Writeline($"{theName} equ {negativeOffset}");
                    Emitter.Writeline($"{varSymbol.Name}@{ProcedureName} equ rbp-{negativeOffset}");    // negative from RBP, because the variables are stored in the procedure frame, so below RBP
                }
            }
            StackSpaceToReserve = (negativeOffset & 0xfff0) + 16;  // take care of a 16 byte stack alignment;
        }


        public string? GetGroupName()
        {
            if (FunctionStatement.Parent is GroupStatement groupStatement)
                return groupStatement.Name.Lexeme;

            return null;
        }


        public void Emit_Equ_FunctionParameters()
        {
            int counter = FunctionStatement.Parameters.Count + 1;  // Count + 1, because the "this" and __parent is added.
            var theName = "";
            int positiveOffset = 0;
            foreach (var par in FunctionStatement.Parameters)
            {
                theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, par.Name, GetGroupName());
                // the 16 bytes are for: push rbp(at position rbp) and call return address(at postition rbp+8).
                positiveOffset = 16 + (counter * 8);
                Emitter.Writeline($"{theName} equ {positiveOffset}");
                Emitter.Writeline($"{Emitter.UserfriendlyVariableNameForFunctionParameter(ProcedureName, par.Name, GetGroupName())} equ rbp+{positiveOffset}");   // positive from RBP, because the parameters are put on the stack before the procedure frame is created.
                counter--;
            }

            if (ProcedureName != "main")
            {
                theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, "lexparentframe", GetGroupName());
                positiveOffset = 16 + (counter * 8);
                Emitter.Writeline($"{theName} equ {positiveOffset}");
                Emitter.Writeline($"{Emitter.UserfriendlyVariableNameForFunctionParameter(ProcedureName, "lexparentframe", GetGroupName())} equ rbp+{positiveOffset}");
                counter--;

                theName = Emitter.AssemblyVariableNameForFunctionParameter(ProcedureName, "this", GetGroupName());
                positiveOffset = 16 + (counter * 8);
                Emitter.Writeline($"{theName} equ {positiveOffset}");
                Emitter.Writeline($"{Emitter.UserfriendlyVariableNameForFunctionParameter(ProcedureName, "this", GetGroupName())} equ rbp+{positiveOffset}");   // positive from RBP, because the parameters are put on the stack before the procedure frame is created.
            }
        }


        public void EmitProcedureNameLabel()
        {
            if (ProcedureName == "main")
                return;

            Emitter.InsertLabel(Emitter.ConvertToAssemblyFunctionName(ProcedureName, GetGroupName()));
        }


        public void EmitCreateStackframe()
        {
            if (FunctionStatement.AssemblyOnlyFunctionWithNoParameters())
                return;

            if (ProcedureName != "main")
                Emitter.CreateStackframe();

            int spaceToReserve = AmountStackSpaceToReserve();
            if (spaceToReserve > 0)
                Emitter.ReserveStackspace(spaceToReserve, NeedsRefCount());
        }


        public void EmitReleaseStackframe()
        {
            int stackToReclaim = 0;
            if (FunctionStatement.Parameters.Count > 0)
                stackToReclaim = (((FunctionStatement.Parameters.Count + 1) * 8) & 0xfff0) + 16;  // zorg voor een 16 byte alignment in de stack

            string? returnLabel = ReturnLabel();
            if (returnLabel != null)
                Emitter.InsertLabel(returnLabel);

            if (ProcedureName == "main")
                return;

            Emitter.EndFunction(stackToReclaim, noFrameRestoration: FunctionStatement.AssemblyOnlyFunctionWithNoParameters());
        }


        public string? ReturnLabel()
        {
            if (FunctionStatement.Properties.ContainsKey("returnLabel"))
                return (string)FunctionStatement.Properties["returnLabel"]!;

            return null;
        }


        public void Emit()
        {
            Emit_Equ_LocalVariables();
            Emit_Equ_FunctionParameters();
            EmitProcedureNameLabel();
            EmitCreateStackframe();

            FunctionStatement.Body.shouldCleanDereferenced = NeedsRefCount();

            if (MainCallback != null)
                MainCallback();

            EmitReleaseStackframe();
        }
    }
}
