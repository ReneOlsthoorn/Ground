using System.Text;

namespace GroundCompiler
{
    public class Step1_PreProcessor
    {
        public string sourcecode;
        public Dictionary<string, Token> defines;
        public string usedTemplate = "console";
        string currentDir = System.IO.Directory.GetCurrentDirectory();

        public Step1_PreProcessor(string sourcecode) {
            this.sourcecode = sourcecode;
            defines = new Dictionary<string, Token>();
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
            if (line.StartsWith("#define"))
            {
                string defineKey = line.Split()[1].Trim();
                string defineValue = line.Split()[2].Trim();

                var defineLexer = new Step2_Lexer(defineValue);
                var defineTokens = defineLexer.GetTokens().ToList();
                defines[defineKey] = defineTokens[0];

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
