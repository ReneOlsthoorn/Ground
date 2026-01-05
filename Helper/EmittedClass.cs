using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class EmittedClass
    {
        public string ClassName;
        public ClassStatement ClassStatement { get; set; }
        public CodeEmitter Emitter { get; set; }
        public Action<FunctionStatement>? MethodCallback = null;     // callback which is called as main-part of the code generation.

        public EmittedClass(ClassStatement classStatement, CodeEmitter emitter, string? name = null)
        {
            this.ClassStatement = classStatement;
            Emitter = emitter;
            ClassName = (name != null) ? name : this.ClassStatement.Name.Lexeme;
        }

        public int AmountStackSpaceToReserve() => ClassStatement.SizeInBytes();

        public void EmitClassNameLabel()
        {
            Emitter.InsertLabel(Emitter.ConvertToAssemblyFunctionName(ClassName));
        }

        public void Emit_Equ_InstanceVariables()
        {
            List<LocalVariableSymbol> theVariables = this.ClassStatement.GetScope()!.GetVariableSymbols();

            int offset = 0;
            foreach (var varSymbol in theVariables)
            {
                int sizeOfVariable = varSymbol.DataType.SizeInBytes;
                int sizeAddedForAlignment = this.ClassStatement.Align(sizeOfVariable, offset);
                offset += sizeAddedForAlignment;
                Emitter.Writeline($"{varSymbol.Name}@{ClassName} = {offset}");
                offset += sizeOfVariable;
            }
        }

        public void Emit()
        {
            Emit_Equ_InstanceVariables();

            foreach (var aFunctionStatement in ClassStatement.FunctionNodes)
            {
                var funcStatement = aFunctionStatement;
                var emittedProcedure = new EmittedProcedure(functionStatement: funcStatement, classStatement: this.ClassStatement, Emitter);
                emittedProcedure.MainCallback = () =>
                {
                    MethodCallback?.Invoke(funcStatement);
                };
                emittedProcedure.Emit();
            }

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
