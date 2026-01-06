
namespace GroundCompiler
{
    public class LineCounter
    {
        private List<int> lineStarts = new List<int>();

        public LineCounter(string sourcecode) {
            this.Count(sourcecode);
        }

        public void Count(string sourcecode)
        {
            lineStarts = new List<int>();
            int sourcecodeCount = sourcecode.Length;
            lineStarts.Add(0);
            for (int i = 0; i < sourcecodeCount; i++)
            {
                if (sourcecode[i] == '\n' && ((i+1) != sourcecodeCount))
                    lineStarts.Add(i+1);
            }
        }

        public int GetLineNumberForIndex(int index)
        {
            for (int i = 0; i< lineStarts.Count; i++)
            {
                int lineIndex = lineStarts[i];
                if (lineIndex > index)
                {
                    if (lineIndex == 0)
                        return 1;
                    else
                        return i;
                }
            }
            return lineStarts.Count;
        }

    }
}
