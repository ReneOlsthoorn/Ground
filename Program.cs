using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Program
    {
        required public string sourceFilename, sourceFullFilepath;
        string sourcecode = "", generatedCode = "";
        string currentDir = System.IO.Directory.GetCurrentDirectory();
        string usedTemplate = "console";
        bool runAfterCompilation = true;
        bool generateDebugInfo = false;


        static void Main(string[] args)
        {
            string currentDir = System.IO.Directory.GetCurrentDirectory();
            string fileName, fullPath;
            if (args.Length == 0)
            {
                fileName = "smoothscroller.g";  //console.g, sudoku.g, smoothscroller.g, mode7.g, mode7_optimized.g
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Examples\\{fileName}"));
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
            sourcecode = File.ReadAllText(sourceFullFilepath);
            CheckCompilerDirectives();

            Console.WriteLine("*** Convert sourcecode to tokens.");
            var lexer = new Lexer(sourcecode);
            var tokens = lexer.GetTokens();
            lexer.WriteDebugInfo(tokens);

            Console.WriteLine("*** Convert tokens to AST (abstract syntax tree).");
            var parser = new Parser(tokens);
            var ast = parser.GetAbstractSyntaxTree();
            parser.WriteDebugInfo(ast);

            Console.WriteLine("*** Optimize the AST.");
            Optimizer.Optimize(ast);

            Console.WriteLine("*** Convert AST to x86-64 assembly.");
            Compiler compiler = new Compiler(template: usedTemplate);
            generatedCode = compiler.GenerateAssembly(ast);

            Assemble();
            RunExecutable();
        }


        public bool HandleDirective(int index)
        {
            int endOfLine = sourcecode.IndexOf('\n', index);
            string line = sourcecode.Substring(index, endOfLine-index);
            if (line.StartsWith("#template"))
            {
                usedTemplate = line.Split()[1].Trim();
                ClearLineAtIndex(index);
                return false;
            }
            if (line.StartsWith("#include"))
            {
                string fileToInclude = line.Split()[1].Trim();
                ClearLineAtIndex(index);
                IncludeFileAtIndex(index, fileToInclude);
                return true;
            }
            return false;
        }

        public void IncludeFileAtIndex(int index, string fileName)
        {
            string fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Include\\{fileName}"));
            string theText = File.ReadAllText(fullPath);
            StringBuilder sb = new StringBuilder(sourcecode);
            sb.Insert(index, theText);
            sourcecode = sb.ToString();
        }

        public void ClearLineAtIndex(int index)
        {
            int endOfLine = sourcecode.IndexOf('\n', index);
            StringBuilder sb = new StringBuilder(sourcecode);

            if (sourcecode[endOfLine - 1] == '\r')
                endOfLine--;

            for (int i = index; i < endOfLine; i++)
                sb[i] = ' ';
            sourcecode = sb.ToString();
        }

        public void CheckCompilerDirectives()
        {
            bool endMarkerFound = true;
            bool endReached = false;
            while (!endReached)
            {
                int sourcecodeCount = sourcecode.Length;
                for (int i = 0; i < sourcecodeCount; i++)
                {
                    if (endMarkerFound && sourcecode[i] == '#')
                        if (HandleDirective(i))
                            break;
                        else
                            endMarkerFound = false;

                    if (sourcecode[i] == '\n')
                        endMarkerFound = true;

                    if (i == sourcecodeCount - 1)
                        endReached = true;
                }
            }
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

            Console.WriteLine("*** Starting the executable.\r\n");

            string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.exe"));

            Process.Start(new ProcessStartInfo(startupFilename)); // { UseShellExecute = true });
        }

    }
}
