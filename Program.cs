using System.Diagnostics;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Program
    {
        required public CompilationSession sess;
        private string currentDir = System.IO.Directory.GetCurrentDirectory();


        static void Main(string[] args)
        {
            string currentDir = System.IO.Directory.GetCurrentDirectory();
            string fileName, fullPath;
            bool runAfterCompilation = false;
            if (args.Length == 0)
            {
#if DEBUG
                fileName = "bertus.g";    //  racer  jump  bertus  tetrus  snake  bugs  game_of_life  unittests  sudoku  smoothscroller  mode7  mode7_optimized  plasma_non_colorcycling  fire  win32_screengrab  connect4  chess  star_taste  high_noon  memory  fireworks  3d  electronic_life  snippet_circles  snippet_spiral  hexacubes
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\Examples\\{fileName}"));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\Test\\{fileName}")); }
                fileName = Path.GetFileNameWithoutExtension(fullPath);
                runAfterCompilation = true;
#else
                Console.WriteLine("GroundCompiler. Error: provide a filename with extension .g");
                return;
#endif
            }
            else
            {
                fileName = args[0];
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"GroundCode\\{fileName}"));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, fileName)); }
                if (!File.Exists(fullPath)) { Console.WriteLine($"GroundCompiler. Error: cannot find {fileName}"); return; }
                fileName = Path.GetFileNameWithoutExtension(fullPath);
            }

            CompilationSession newSession = new CompilationSession() { RunAfterCompilation = runAfterCompilation, GenerateDebugInformation = false };
            newSession.PushSourcecodeFile(fileName, fullPath, File.ReadAllText(fullPath));
            Program compilation = new() { sess = newSession };
            compilation.Build();
        }


        public void Build()
        {
            sess.PreProcessor = new PreProcessor(sess);

            Console.WriteLine("*** Step 1: Lexer. Convert sourcecode to tokens.");
            sess.Lexer = new Lexer(sess);
            sess.Tokens = sess.Lexer.GetTokens().ToList();                            //WriteTokensDebugInfo(session.Tokens);

            Console.WriteLine("*** Step 2: Parser: Convert tokens into an Abstract Syntax Tree.");
            sess.Parser = new Parser(sess.Tokens);
            sess.AST = sess.Parser.GetAbstractSyntaxTree();                           //WriteASTDebugInfo(session.AST);

            Console.WriteLine("*** Step 3a: Type Checker. Initialize the Abstract Syntax Tree.");
            TypeChecker.Initialize(sess.AST);
            Console.WriteLine("*** Step 3b: Type Checker. Evaluate the Abstract Syntax Tree.");     
            TypeChecker.Evaluate(sess.AST);

            Console.WriteLine("*** Step 4: Optimizer. Literal folding, Unused variable removal, etc...Optimize the AST.");
            Optimizer.Optimize(sess.AST);

            Console.WriteLine("*** Step 5: Compiler. Convert AST to x86-64 assembly.");
            sess.Compiler = new Compiler(sess);
            sess.GeneratedCode = sess.Compiler.GenerateAssembly(sess.AST);

            Console.WriteLine("*** Assemble with FASM.");
            Assemble();

            Console.WriteLine("*** Run the executable.");
            RunExecutable();
        }


        public void Assemble()
        {
            //Console.WriteLine("*** Write generated code to disk.");

            string outputAsmFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sess.SourceFilename}.asm"));
            string outputFasFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sess.SourceFilename}.fas"));
            string outputLstFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sess.SourceFilename}.lst"));

            File.WriteAllText(outputAsmFilename, sess.GeneratedCode);
            Console.WriteLine("*** Start assembler.");

            string assemblerParameters = $"{outputAsmFilename}";
            if (sess.GenerateDebugInformation)
                assemblerParameters = $"{outputAsmFilename} -s {outputFasFilename}";

            var startInfo = new ProcessStartInfo
            {
                FileName = "fasm\\fasm.exe",
                Arguments = assemblerParameters,
                WorkingDirectory = currentDir
            };

            System.Diagnostics.ProcessStartInfo info = startInfo;
            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo = info;
            p.Start();
            p.WaitForExit();

            if (sess.GenerateDebugInformation)
            {
                Console.WriteLine("*** Generating Debug information.");

                info = new System.Diagnostics.ProcessStartInfo("fasm\\listing.exe", $"{outputFasFilename} {outputLstFilename}");
                p = new System.Diagnostics.Process();
                p.StartInfo = info;
                p.Start();
                p.WaitForExit();

                Generate_x64dbg_EXE(outputLstFilename);
            }
        }


        public string x64dbgDbFolder = "c:\\prg\\x64dbg2025\\x64\\db";

        public void Generate_x64dbg_EXE(string outputLstFilename)
        {
            string[] lines = File.ReadAllLines(outputLstFilename);
            int start = -1, end = -1, counter = 0;

            foreach (var line in lines)
            {
                if (line.Contains("section '.text'"))
                    start = counter;

                if (line.Contains("section '.idata'"))
                    end = counter;

                counter++;
            }
            if (start == -1 || end == -1) { return; }

            string commentPart = "";
            int counterCommentPart = 0;
            int needle = start;
            while (needle < end)
            {
                string line = lines[needle++];
                if (line.Length < 8) { continue; }
                string address = line.Substring(0, 8);
                if (!Char.IsAsciiHexDigit(address[0])) continue;
                if (!Char.IsAsciiHexDigit(address[1])) continue;
                if (!Char.IsAsciiHexDigit(address[2])) continue;
                if (!Char.IsAsciiHexDigit(address[3])) continue;
                if (!Char.IsAsciiHexDigit(address[4])) continue;
                if (!Char.IsAsciiHexDigit(address[5])) continue;
                if (!Char.IsAsciiHexDigit(address[6])) continue;
                if (!Char.IsAsciiHexDigit(address[7])) continue;

                int getal = Convert.ToInt32(address, 16);
                getal = getal - 0x200 + 0x1000;

                string outputAddress = $"0x{getal.ToString("X")}";
                string text = line.Substring(66);
                int firstSemicolon = text.IndexOf(";");
                if (firstSemicolon != -1)
                    text = text.Substring(0, firstSemicolon);

                text = text.Trim();
                text = text.Replace("\t", " ");
                text = Regex.Replace(text, @"[^a-zA-Z0-9,_\*\+\-\.\[\]\(\)\@ ]", string.Empty);
                if (commentPart != "") { commentPart += ",\n"; }

                string commentLittlePart = "  {\n";
                commentLittlePart += "   \"module\": \"" + sess.SourceFilename + ".exe\",\n";
                commentLittlePart += $"   \"address\": \"{outputAddress}\",\n";
                commentLittlePart += $"   \"manual\": true,\n";
                commentLittlePart += $"   \"text\": \"{ text }\"\n";
                commentLittlePart += "  }";

                commentPart += commentLittlePart;
                counterCommentPart++;
            }

            string dd64 = "{\n \"comments\": [\n";
            dd64 += commentPart;
            dd64 += "\n ]\n}";

            string dd64Filename = $"{ x64dbgDbFolder }\\{sess.SourceFilename}.exe.dd64";
            File.WriteAllText(dd64Filename, dd64);
        }


        public void RunExecutable()
        {
            if (!sess.RunAfterCompilation)
                return;

            Console.WriteLine($"*** Starting {sess.SourceFilename}.exe\r\n");
            string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sess.SourceFilename}.exe"));
            Process.Start(new ProcessStartInfo(startupFilename)); // { UseShellExecute = true });
        }


        public void WriteASTDebugInfo(Statements.ProgramNode node)
        {
            return; // remove if you want debug info

            var astPrinter = new AstPrinter();
            foreach (AstNode statement in node.BodyNode.AllNodes())
                Console.WriteLine(astPrinter.Print(statement));
        }


        public void WriteTokensDebugInfo(IEnumerable<Token> tokens)
        {
        }

    }
}
