using System.Diagnostics;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Program
    {
        required public string sourceFilename, sourceFullFilepath;
        string? sourcecode, generatedCode;
        string currentDir = System.IO.Directory.GetCurrentDirectory();
        bool isGuiApplication = true;
        bool runAfterCompilation = false;
        bool generateDebugInfo = true;


        static void Main(string[] args)
        {
            var fileName = "source_console";
            var fullPath = Path.GetFullPath(Path.Combine(System.IO.Directory.GetCurrentDirectory(), $"..\\..\\..\\..\\GroundCompiler\\Examples\\{fileName}.g"));

            Program compilation = new() { sourceFilename = fileName, sourceFullFilepath = fullPath };
            compilation.Build();
        }


        public void Build()
        {
            sourcecode = File.ReadAllText(sourceFullFilepath);
            CheckAnnotations();

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
            Compiler compiler = new Compiler(isGuiApplication);
            generatedCode = compiler.GenerateAssembly(ast);

            Assemble();
            RunExecutable();
        }


        public void CheckAnnotations()
        {
            if (sourcecode!.StartsWith("//run"))
                runAfterCompilation = true;

            if (sourcecode.StartsWith("//debug"))
            {
                runAfterCompilation = false;
                generateDebugInfo = true;
            }

            if (sourcecode.StartsWith("//run console") || sourcecode.StartsWith("//!run console") || sourcecode.StartsWith("//debug console"))
                isGuiApplication = false;
        }

        public void Assemble()
        {
            //Console.WriteLine("*** Write generated code to disk.");

            string outputAsmFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.asm"));
            string outputFasFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.fas"));
            string outputLstFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.lst"));

            if (isGuiApplication)
            {
                outputAsmFilename = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\..\\GroundOutput\\GroundUser.asm"));
                outputFasFilename = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\..\\GroundOutput\\GroundUser.fas"));
                outputLstFilename = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\..\\GroundOutput\\GroundUser.lst"));
                var baseInclude = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\base_gui_include.asm.txt"));
                var baseIncludeDest = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\..\\GroundOutput\\GroundUser_include.asm"));
                File.Copy(baseInclude, baseIncludeDest, overwrite: true);
            }

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

                if (isGuiApplication)
                    Generate_x64dbg_DLL(outputLstFilename);
                else
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


        public void Generate_x64dbg_DLL(string outputLstFilename)
        {
            string[] lines = File.ReadAllLines(outputLstFilename);
            int start = -1, end = -1, counter = 0;

            foreach (var line in lines)
            {
                if (line.Contains("section '.text'"))
                    start = counter;

                if (line.Contains("section '.edata'"))
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
                getal = getal - 0x400 + 0x1000;

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
                commentLittlePart += "   \"module\": \"grounduser.dll\",\n";
                commentLittlePart += $"   \"address\": \"{outputAddress}\",\n";
                commentLittlePart += $"   \"manual\": true,\n";
                commentLittlePart += $"   \"text\": \"{text}\"\n";
                commentLittlePart += "  }";

                commentPart += commentLittlePart;
                counterCommentPart++;
            }

            string dd64 = "{\n \"comments\": [\n";
            dd64 += commentPart;
            dd64 += "\n ]\n}";

            string dd64Filename = $"{x64dbgDbFolder}\\Ground.exe.dd64";
            File.WriteAllText(dd64Filename, dd64);
        }


        public void RunExecutable()
        {
            if (!runAfterCompilation)
                return;

            Console.WriteLine("*** Starting the executable.\r\n\r\n");

            string startupFilename = Path.GetFullPath(Path.Combine(currentDir, $"{sourceFilename}.exe"));
            if (isGuiApplication)
                startupFilename = Path.GetFullPath(Path.Combine(currentDir, "..\\..\\..\\..\\GroundOutput\\Ground.exe"));

            Process.Start(new ProcessStartInfo(startupFilename)); // { UseShellExecute = true });
        }

    }
}
