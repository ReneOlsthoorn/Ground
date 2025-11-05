using System.Text;
using System.Text.RegularExpressions;

namespace GroundCompiler
{
    public class Step1_PreProcessor
    {
        public string sourcecode;
        public Dictionary<string, Token> defines;
        public string usedTemplate = "console";
        string currentDir = System.IO.Directory.GetCurrentDirectory();
        public List<(string, string)> libraries;

        public Step1_PreProcessor(string sourcecode) {
            this.sourcecode = sourcecode;
            defines = new Dictionary<string, Token>();
            libraries = new List<(string, string)>();
        }

        public void ProcessCompilerDirectives()
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
                    else
                        endMarkerFound = false;

                    if (i == sourcecodeCount - 1)
                        endReached = true;
                }
            }
        }

        public bool HandleDirective(int index)
        {
            int endOfLine = sourcecode.IndexOf('\n', index);
            string line = sourcecode.Substring(index, endOfLine - index);
            if (line.StartsWith("#template"))
            {
                usedTemplate = line.Split()[1].Trim();
                ClearLineAtIndex(index);
                return false;
            }
            if (line.StartsWith("#include"))
            {
                string fileToInclude = line.Substring("#include".Length).Trim();
                ClearLineAtIndex(index);
                IncludeFileAtIndex(index, fileToInclude);
                return true;
            }
            if (line.StartsWith("#library"))
            {
                string[] parts = Regex.Split(line, @"\s+");
                var libraryName = parts[1].Trim();
                var dllFilename = parts[2].Trim();
                libraries.Add((libraryName, dllFilename));
                ClearLineAtIndex(index);
                IncludeFileAtIndex(index, $"{libraryName}.g");
                return true;
            }
            if (line.StartsWith("#define"))
            {
                string restOfLine = line.Substring("#define".Length);
                var defineLexer = new Step2_Lexer(restOfLine);
                var defineTokens = defineLexer.GetTokens().ToList();
                string defineKey = defineTokens[0].Lexeme;
                defines[defineKey] = Token.DetermineIntegerToken(defineTokens.Skip(1).ToList(), defines);

                ClearLineAtIndex(index);
                return true;
            }
            return false;
        }

        public void IncludeFileAtIndex(int index, string fileName)
        {
            string fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Include\\{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Examples\\{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"..\\..\\..\\Examples\\test\\{fileName}"));
            if (!File.Exists(fullPath))
                fullPath = Path.GetFullPath(Path.Combine(currentDir, $"{fileName}"));

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

    }
}
