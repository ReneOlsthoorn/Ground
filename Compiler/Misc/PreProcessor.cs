
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    // All directives start with a #. They can be redefined. Once defined, they are used immediately.
    public class PreProcessor
    {
        public Dictionary<string, Token> Defines;
        public List<(string, string, string)> Libraries;
        public string Template;
        public CompilationSession CompilationSession;

        string currentDir = System.IO.Directory.GetCurrentDirectory();

        public PreProcessor(CompilationSession session)
        {
            Defines = new Dictionary<string, Token>();
            Libraries = new List<(string, string, string)>();
            Template = "console";
            this.CompilationSession = session;
        }

        public void HandleDirective(string line)
        {
            if (line.StartsWith("#template"))
            {
                Template = line.Split()[1].Trim();
                return;
            }
            if (line.StartsWith("#include"))
            {
                string fileToInclude = line.Substring("#include".Length).Trim();
                IncludeFile(fileToInclude);             // immediate tokenize this newly included file
                return;
            }
            if (line.StartsWith("#library"))
            {
                string[] parts = Regex.Split(line, @"\s+");
                var libraryName = parts[1].Trim();
                var dllFilename = parts[2].Trim();
                var linuxLib = "";
                if (parts.Length > 3)
                    linuxLib = parts[3].Trim();
                Libraries.Add((libraryName, dllFilename, linuxLib));
                IncludeFile($"{libraryName}.g");
                return;
            }
            if (line.StartsWith("#define"))
            {
                string restOfLine = line.Substring("#define".Length);
                var defineLexer = new Lexer(restOfLine);
                var defineTokens = defineLexer.GetTokens().ToList();
                string defineKey = defineTokens[0].Lexeme;
                Defines[defineKey] = Token.DetermineIntegerToken(defineTokens.Skip(1).ToList(), Defines);
                return;
            }
        }

        public void IncludeFile(string fileName)
        {
#if DEBUG
            string fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Include/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"Include/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples/{fileName}"));
            if (!File.Exists(fullPath) && !CompilationSession.IsCurrentlyOnLinux)
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Windows/{fileName}"));
            if (!File.Exists(fullPath) && CompilationSession.IsCurrentlyOnLinux)
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Examples_Linux/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"../../Test/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"{fileName}"));
#else
            string fullPath = Path.GetFullPath(Path.Combine(currentDir, $"Include/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"GroundCode/{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"{fileName}"));
#endif

            string theIncludedSourceCode = File.ReadAllText(fullPath);
            this.CompilationSession.PushSourcecodeFile(fileName, fullPath, theIncludedSourceCode);
        }

    }
}
