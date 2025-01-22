using System;

namespace GroundCompiler
{
    public class Utils
    {
        public static string StringAsDebug(string? str)
        {
            if (str == null)
                return "null";

            return str.Replace("\r", "\\r").Replace("\n", "\\n");
        }
    }
}
