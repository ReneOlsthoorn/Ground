using System.Diagnostics;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Program
    {
        required public CompilationSession theSession;
        private string currentDir = System.IO.Directory.GetCurrentDirectory();


        static void Main(string[] args)
        {
            string currentDir = System.IO.Directory.GetCurrentDirectory();
            string fileName, fullPath;
            CompilationSession session = new CompilationSession() { IsCurrentlyOnLinux = OperatingSystem.IsLinux(), CompileForLinux = OperatingSystem.IsLinux(), RunAfterCompilation = false, GenerateDebugInformation = false };
#if DEBUG
            session.RunAfterCompilation = true;
#else
            if (args.Length == 0) { Console.WriteLine("GroundCompiler. Error: provide a filename with extension .g"); return; }
#endif
            bool crossCompileLinuxOnWindows = false;
            if (crossCompileLinuxOnWindows)
            {
                session.IsCurrentlyOnLinux = false;
                session.CompileForLinux = true;
                session.RunAfterCompilation = false;
            }

            if (args.Length == 0)
            {
                fileName = "bertus.g";    //  racer  jump  bertus  tetrus  snake  bugs  game_of_life  unittests  sudoku  smoothscroller  mode7  mode7_optimized  plasma_non_colorcycling  fire  win32_screengrab  connect4  chess  star_taste  high_noon  memory  fireworks  3d  electronic_life  snippet_circles  snippet_spiral  hexacubes  raylib_zoom  raylib_fireball  raylib_onderwater  raylib_starfall  gpu_tempotypen
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples/{fileName}"));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Test/{fileName}")); }
                if (!File.Exists(fullPath) && !OperatingSystem.IsLinux()) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Windows/{fileName}")); }
                if (!File.Exists(fullPath) && OperatingSystem.IsLinux()) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Linux/{fileName}")); }
                fileName = Path.GetFileNameWithoutExtension(fullPath);
            }
            else
            {
                fileName = args[0];
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"GroundCode/{fileName}"));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, fileName)); }
                if (!File.Exists(fullPath)) { Console.WriteLine($"GroundCompiler. Error: cannot find {fileName}"); return; }
                fileName = Path.GetFileNameWithoutExtension(fullPath);
            }

            session.PushSourcecodeFile(fileName, fullPath, File.ReadAllText(fullPath));
            Program compilation = new() { theSession = session };
            compilation.Build();
        }


        public void Build()
        {
            theSession.PreProcessor = new PreProcessor(theSession);

            Console.WriteLine("*** Step 1: Lexer. Convert sourcecode to tokens.");
            theSession.Lexer = new Lexer(theSession);
            theSession.Tokens = theSession.Lexer.GetTokens().ToList();

            Console.WriteLine("*** Step 2: Parser: Convert tokens into an Abstract Syntax Tree.");
            theSession.Parser = new Parser(theSession.Tokens);
            theSession.AST = theSession.Parser.GetAbstractSyntaxTree();                           //WriteASTDebugInfo(session.AST);

            Console.WriteLine("*** Step 3a: Type Checker. Initialize the Abstract Syntax Tree.");
            TypeChecker.Initialize(theSession.AST);
            Console.WriteLine("*** Step 3b: Type Checker. Evaluate the Abstract Syntax Tree.");     
            TypeChecker.Evaluate(theSession.AST);

            Console.WriteLine("*** Step 4: Optimizer. Literal folding, Unused variable removal, etc...Optimize the AST.");
            Optimizer.Optimize(theSession.AST);

            Console.WriteLine("*** Step 5: Compiler. Convert AST to x86-64 assembly.");
            theSession.Compiler = new Compiler(theSession);
            theSession.GeneratedCode = theSession.Compiler.GenerateAssembly(theSession.AST);

            Console.WriteLine("*** Assemble with FASM.");
            Assemble();

            Console.WriteLine("*** Run the executable.");
            RunExecutable();
        }


        public void Assemble()
        {
            //Console.WriteLine("*** Write generated code to disk.");

            string outputAsmFilenameClean = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}"));
            string outputAsmFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}.asm"));
            string outputFasFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}.fas"));
            string outputLstFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}.lst"));

            File.WriteAllText(outputAsmFilename, theSession.GeneratedCode);
            Console.WriteLine("*** Start assembler.");

            string assemblerParameters = $"{outputAsmFilename}";
            if (theSession.GenerateDebugInformation)
                assemblerParameters = $"{outputAsmFilename} -s {outputFasFilename}";

            var startInfo = new ProcessStartInfo
            {
                FileName = theSession.IsCurrentlyOnLinux ? "fasm" : "fasm\\fasm.exe",
                Arguments = assemblerParameters,
                WorkingDirectory = currentDir
            };

            System.Diagnostics.ProcessStartInfo info = startInfo;
            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo = info;
            p.Start();
            p.WaitForExit();

            if (theSession.IsCurrentlyOnLinux)
            {
                List<string> libsToLink = new List<string>();
                foreach (var item in theSession.PreProcessor.Libraries) {
                    if (item.Item3 != "")
                        libsToLink.Add(item.Item3);
                }
                string allLibs = string.Join(" ", libsToLink.Select(lib => $"-l{lib}"));
                string processStart = $"{outputAsmFilenameClean}.o -o {outputAsmFilenameClean} -lm -lpthread -ldl -lrt {allLibs} -no-pie";
                Console.WriteLine("gcc " + processStart);
                info = new System.Diagnostics.ProcessStartInfo("gcc", processStart);
                info.WorkingDirectory = currentDir;
                p = new System.Diagnostics.Process();
                p.StartInfo = info;
                p.Start();
                p.WaitForExit();
            }

            if (theSession.GenerateDebugInformation)
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
                commentLittlePart += "   \"module\": \"" + theSession.SourceFilename + ".exe\",\n";
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

            string dd64Filename = $"{ x64dbgDbFolder }\\{theSession.SourceFilename}.exe.dd64";
            File.WriteAllText(dd64Filename, dd64);
        }


        public void RunExecutable()
        {
            if (!theSession.RunAfterCompilation)
                return;

            if (theSession.IsCurrentlyOnLinux)
            {
                Console.WriteLine($"*** Starting {theSession.SourceFilename}\r\n");
                string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}"));
                var psi = new ProcessStartInfo(startupFilename);
                var proces = Process.Start(psi);
                proces.WaitForExit();
            }
            else
            {
                Console.WriteLine($"*** Starting {theSession.SourceFilename}.exe\r\n");
                string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}.exe"));
                Process.Start(new ProcessStartInfo(startupFilename)); // { UseShellExecute = true });
            }
        }


        public void WriteASTDebugInfo(Statements.ProgramNode node)
        {
            var astPrinter = new AstPrinter();
            foreach (AstNode statement in node.BodyNode.AllNodes())
                Console.WriteLine(astPrinter.Print(statement));
        }
    }
}
