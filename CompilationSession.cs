
using GroundCompiler.Statements;

namespace GroundCompiler
{
    public class SourcecodePack
    {
        public string SourceFilename;
        public string SourceFullFilepath;
        public string SourceCode;
        public int Needle = 0;
        public LineCounter LineCounter;
    }

    public class CompilationSession
    {
        public Stack<SourcecodePack> SourcecodePackStack = new();
        public List<SourcecodePack> SourcecodePackHistory = new();      // When a sourcecodefile is handled, it will remain in the history so each token still can know it's linenumber.

        public SourcecodePack? Current {
            get {
                if (this.SourcecodePackStack.Count == 0)
                    return null;
                return this.SourcecodePackStack.Peek();
            }
        }
        public int CurrentIndex = -1;

        public bool RunAfterCompilation = false;
        public bool GenerateDebugInformation = false;
        public string GeneratedCode;

        public PreProcessor PreProcessor;
        public List<Token> Tokens;
        public ProgramNode AST;
        public Lexer Lexer;
        public Parser Parser;
        public Compiler Compiler;

        public void SaveOldNeedle()
        {
            if (this.Current == null)
                return;
            this.Current.Needle = Lexer.needle;
        }

        public void ActivateCurrentSourcecode()
        {
            Lexer?.needle = this.Needle;
            Lexer?.sourcecode = this.SourceCode;
            this.CurrentIndex = -1;
            for (int i = 0; i < SourcecodePackHistory.Count; i++)
            {
                if (SourcecodePackHistory[i].SourceFullFilepath == SourcecodePackStack.Peek().SourceFullFilepath)
                    this.CurrentIndex = i;
            }
        }

        public void PushSourcecodeFile(string sourceFilename, string sourceFullFilepath, string sourceCode, int NeedlePosition = 0)
        {
            SaveOldNeedle();
            LineCounter lineCounter = new LineCounter(sourceCode);
            var newPack = new SourcecodePack { SourceFilename = sourceFilename, SourceFullFilepath = sourceFullFilepath, SourceCode = sourceCode, Needle = NeedlePosition, LineCounter = lineCounter };
            SourcecodePackStack.Push(newPack);
            SourcecodePackHistory.Add(newPack);
            ActivateCurrentSourcecode();
        }

        public void Pop()
        {
            if (SourcecodePackStack.Count >= 2) {
                SourcecodePackStack.Pop();
                ActivateCurrentSourcecode();
            }
        }

        public bool IsRoot() => (this.CurrentIndex == 0 || this.CurrentIndex == -1);
        public string SourceFilename { get { return SourcecodePackStack.Peek().SourceFilename; } }
        public string SourceFullFilepath { get { return SourcecodePackStack.Peek().SourceFullFilepath; } }
        public string SourceCode { get { return SourcecodePackStack.Peek().SourceCode; } }
        public int Needle { get { return SourcecodePackStack.Peek().Needle; } }
        public LineCounter LineCounter { get { return SourcecodePackStack.Peek().LineCounter; } }
    }
}
