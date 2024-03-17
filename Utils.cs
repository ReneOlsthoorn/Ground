using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

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
