using System.Diagnostics;

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
            CompilationSession session = new CompilationSession(OperatingSystem.IsLinux());
            if (args.Length == 0)
            {
#if DEBUG
                fileName = "bertus.g";
                //fileName = "bugs.g";
                //fileName = "fire.g";
                //fileName = "game_of_life.g";
                //fileName = "gpu_circles.g";
                //fileName = "gpu_fireworks.g";
                //fileName = "gpu_spiral.g";
                //fileName = "gpu_tempotypen.g";
                //fileName = "hexacubes.g";
                //fileName = "high_noon.g";
                //fileName = "jump.g";
                //fileName = "memory.g";
                //fileName = "mode7.g";
                //fileName = "plasma.g";
                //fileName = "plasma_non_colorcycling.g";
                //fileName = "racer.g";
                //fileName = "raylib_loga.g";
                //fileName = "raylib_plasma.g";
                //fileName = "raylib_rubbercube.g";
                //fileName = "raylib_octahedralis.g";
                //fileName = "raylib_slitscan.g";
                //fileName = "raylib_zoom.g";
                //fileName = "snake.g";
                //fileName = "snippet_spiral.g";
                //fileName = "snippet_circles.g";
                //fileName = "sudoku.g";
                //fileName = "tetrus.g";
                //fileName = "unittests.g";

                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples/{fileName}"));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Test/{fileName}")); }
                if (!File.Exists(fullPath) && session.IsCurrentlyOnWindows) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Windows/{fileName}")); }
                if (!File.Exists(fullPath) && session.IsCurrentlyOnLinux) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Linux/{fileName}")); }
                fileName = Path.GetFileNameWithoutExtension(fullPath);

                //Cross Compilation (generate Linux Output on a Windows):  session.CompileForLinux = true;
                session.RunAfterCompilation = true;
#else
                Console.WriteLine("GroundCompiler. Error: provide a filename with extension .g");
                return;
#endif
            }
            else
            {
                fileName = args[0];
                fullPath = Path.GetFullPath(Path.Combine(currentDir, fileName));
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"GroundCode/{fileName}")); }
                if (!File.Exists(fullPath)) { fullPath = Path.GetFullPath(Path.Combine(currentDir, $"Examples/{fileName}")); }
                if (!File.Exists(fullPath)) { Console.WriteLine($"GroundCompiler. Error: cannot find {fileName}"); return; }
                fileName = Path.GetFileNameWithoutExtension(fullPath);

                if (args.Length > 1)
                    session.CompileForLinux = !(args[1].ToLower() == "windows");
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
            theSession.Parser = new Parser(theSession, theSession.Tokens);
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

            if (theSession.RunAfterCompilation)
            {
                Console.WriteLine("*** Run the executable.");
                RunExecutable();
            }
        }


        public void Assemble()
        {
            string outputFilepath = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}"));
            string outputAsmFilepath = $"{outputFilepath}.asm";

            File.WriteAllText(outputAsmFilepath, theSession.GeneratedCode);
            Console.WriteLine("*** Start assembler.");

            string assemblerFilename = "";
            string assemblerParameters = "";

            if (theSession.CompileForLinux)
            {
                assemblerFilename = "nasm";
                assemblerParameters = $"-f elf64 {outputAsmFilepath} -o {outputFilepath}.o";
            } 
            else
            {
                if (theSession.CompileForNASM)
                {
                    assemblerFilename = "nasm.exe";
                    assemblerParameters = $"-f win64 {outputAsmFilepath} -o {outputFilepath}.obj";
                }
                else
                {
                    assemblerFilename = "fasm2\\fasm2.cmd";
                    assemblerParameters = $"{outputAsmFilepath}";
                }
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = assemblerFilename,
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
                string processStart = $"{outputFilepath}.o -o {outputFilepath} -lm -lpthread -ldl -lrt {allLibs} -no-pie";
                Console.WriteLine($"gcc {processStart}");
                info = new System.Diagnostics.ProcessStartInfo("gcc", processStart);
                info.WorkingDirectory = currentDir;
                p = new System.Diagnostics.Process();
                p.StartInfo = info;
                p.Start();
                p.WaitForExit();
            }
        }


        public void RunExecutable()
        {
            if (theSession.IsCurrentlyOnLinux)
            {
                Console.WriteLine($"*** Starting {theSession.SourceFilename}\r\n");
                string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{theSession.SourceFilename}"));
                var psi = new ProcessStartInfo(startupFilename);
                var process = Process.Start(psi);
                process?.WaitForExit();
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
