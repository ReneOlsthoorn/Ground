using System.Diagnostics;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Program
    {
        required public string sourceFilename, sourceFullFilepath;
        string generatedCode = "";
        string currentDir = System.IO.Directory.GetCurrentDirectory();
        bool runAfterCompilation = true;
        bool generateDebugInfo = false;

        static void Main(string[] args)
        {
            string currentDir = System.IO.Directory.GetCurrentDirectory();
            string fileName, fullPath;
            if (args.Length == 0)
            {
                fileName = "sudoku.g";  //unittests  sudoku  smoothscroller  smoothscroller_optimized  mode7  mode7_optimized  chipmunk_tennis  starfield  plasma_non_colorcycling  fire  win32-screengrab  bertus  snake  game-of-life  tetrus  racer
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Examples\\{fileName}"));
                if (!File.Exists(fullPath))
                    fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Examples\\test\\{fileName}"));
                fileName = fileName.Substring(0, fileName.Length - 2);
            }
            else
            {
                fileName = args[0];
                if (fileName.EndsWith(".g", StringComparison.InvariantCultureIgnoreCase))
                    fileName = fileName.Substring(0, fileName.Length - 2);
                fullPath = Path.GetFullPath(Path.Combine(currentDir, fileName + ".g"));
            }

            Program compilation = new() { sourceFilename = fileName, sourceFullFilepath = fullPath };
            compilation.Build();
        }


        public void Build()
        {
            string sourcecode = File.ReadAllText(sourceFullFilepath);

            Console.WriteLine("*** Preprocessor. Process compiler directives and collect defines.");
            var preprocessor = new PreProcessor(sourcecode);
            preprocessor.ProcessCompilerDirectives();

            Console.WriteLine("*** Convert sourcecode to tokens.");
            var lexer = new Lexer(preprocessor);
            var tokens = lexer.GetTokens();
            lexer.WriteDebugInfo(tokens);

            Console.WriteLine("*** Convert tokens into an Abstract Syntax Tree.");
            var parser = new Parser(tokens);
            var ast = parser.GetAbstractSyntaxTree();
            parser.WriteDebugInfo(ast);

            Console.WriteLine("*** Type Checking: Initialize the Abstract Syntax Tree.");
            TypeChecker.Initialize(ast);
            Console.WriteLine("*** Type Checking: Evaluate the Abstract Syntax Tree.");     
            TypeChecker.Evaluate(ast);

            Console.WriteLine("*** Optimize the AST.");
            Optimizer.Optimize(ast);

            Console.WriteLine("*** Convert AST to x86-64 assembly.");
            Compiler compiler = new Compiler(template: preprocessor.usedTemplate, defines: preprocessor.defines);
            generatedCode = compiler.GenerateAssembly(ast);

            Assemble();
            RunExecutable();
        }


        public void Assemble()
        {
            //Console.WriteLine("*** Write generated code to disk.");

            string outputAsmFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.asm"));
            string outputFasFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.fas"));
            string outputLstFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.lst"));

            File.WriteAllText(outputAsmFilename, generatedCode);
            Console.WriteLine("*** Start assembler.");

            string assemblerParameters = $"{outputAsmFilename}";
            if (generateDebugInfo)
                assemblerParameters = $"{outputAsmFilename} -s {outputFasFilename}";

            System.Diagnostics.ProcessStartInfo info = new System.Diagnostics.ProcessStartInfo("fasm.exe", assemblerParameters);
            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo = info;
            p.Start();
            p.WaitForExit();

            if (generateDebugInfo)
            {
                Console.WriteLine("*** Generating Debug information.");

                info = new System.Diagnostics.ProcessStartInfo("listing.exe", $"{outputFasFilename} {outputLstFilename}");
                p = new System.Diagnostics.Process();
                p.StartInfo = info;
                p.Start();
                p.WaitForExit();

                Generate_x64dbg_EXE(outputLstFilename);
            }
        }


        public string x64dbgDbFolder = "c:\\prg\\xdbg\\x64\\db";

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
                commentLittlePart += "   \"module\": \"" + sourceFilename + ".exe\",\n";
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

            string dd64Filename = $"{ x64dbgDbFolder }\\{sourceFilename}.exe.dd64";
            File.WriteAllText(dd64Filename, dd64);
        }


        public void RunExecutable()
        {
            if (!runAfterCompilation)
                return;

            Console.WriteLine($"*** Starting {sourceFilename}.exe\r\n");
            string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.exe"));
            Process.Start(new ProcessStartInfo(startupFilename)); // { UseShellExecute = true });
        }

    }
}
