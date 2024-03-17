using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using static GroundCompiler.AstNodes.Statement;

namespace GroundCompiler
{
    public class EmittedClass
    {
        public string ClassName;
        public ClassStatement ClassStatement { get; set; }
        public CodeEmitterX64 Emitter { get; set; }
        public Action<FunctionStatement>? MethodCallback = null;     // callback which is called as main-part of the code generation.

        public EmittedClass(ClassStatement classStatement, CodeEmitterX64 emitter, string? name = null)
        {
            this.ClassStatement = classStatement;
            Emitter = emitter;
            ClassName = (name != null) ? name : this.ClassStatement.Name.Lexeme;
        }

        public int AmountStackSpaceToReserve()
        {
            int result = 0;

            foreach (var inst in ClassStatement.InstanceVariables)
                result += inst.ResultType.SizeInBytes;

            /*
            result += NeedsRefCount() ? ReferenceCountPointersAllocationSize() : 0;

            List<Scope.Symbol.LocalVariableSymbol> theVariables = this.FunctionStatement.GetScope()!.GetVariableSymbols();
            if (theVariables.Count != 0)
                result += ((theVariables.Count * 8) & 0xfff0) + 16;  // take care of a 16 byte stack alignment
            */
            return result;
        }

        public void EmitClassNameLabel()
        {
            Emitter.InsertLabel(Emitter.ConvertToAssemblyFunctionName(ClassName));
        }

        public void Emit_Equ_InstanceVariables()
        {
            List<Scope.Symbol.LocalVariableSymbol> theVariables = this.ClassStatement.GetScope()!.GetVariableSymbols();

            int counter = 1;
            foreach (var varSymbol in theVariables)
            {
                int negativeOffset = /*(NeedsRefCount() ? ReferenceCountPointersAllocationSize() : 0)*/ 0 + (counter * 8);

                var theName = Emitter.AssemblyVariableNameForClassInstanceVariable(ClassName, varSymbol.Name);
                Emitter.Writeline($"{theName} equ {negativeOffset}");
                //Emitter.Writeline($"{varSymbol.Name}@{ProcedureName} equ rbp-{negativeOffset}");    // negative from RBP, because the variables are stored in the procedure frame, so below RBP
                counter++;
            }
        }

        public void Emit()
        {
            //Emit_Equ_InstanceVariables();

            foreach (var aFunctionStatement in ClassStatement.Methods)
            {
                var funcStatement = aFunctionStatement;
                var emittedProcedure = new EmittedProcedure(funcStatement, Emitter);
                emittedProcedure.MainCallback = () =>
                {
                    MethodCallback?.Invoke(funcStatement);
                };
                emittedProcedure.Emit();
            }


            //EmitClassNameLabel();
            Emitter.Writeline($"; Class {ClassName}  Size: {this.AmountStackSpaceToReserve()}");
        }

        /*
ASM_Function(1.1, 1, 2.2, 2, 3, 4, 3.3, 4.4, 5);

sub rsp,50
mov qword [rsp+40], 5
movsd xmm0, qword [storage 4.4]
movsd qword [rsp+38], xmm0
movsd xmm0, qword [storage 3.3]
movsd qword [rsp+30], xmm0
mov qword [rsp+28], 4
mov qword [rsp+20], 3
mov r9, 2
movsd xmm2, qword [storage 2.2]
mov rdx, 1
movsd xmm0, qword [storage 1.1]
call <ASM_Function>
add rsp,50
         */


    }
}
