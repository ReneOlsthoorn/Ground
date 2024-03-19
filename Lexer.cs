using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Linq.Expressions;
using System.Text;

namespace GroundCompiler
{
    public class Lexer
    {
        public string sourcecode;
        public int needle;          // position of the lexer in the sourcecode
        public int lineCounter;     // linecounter of sourcecode

        public Lexer(string sourcecode)
        {
            this.sourcecode = sourcecode + "\n";
        }

        public IEnumerable<Token> GetTokens()
        {
            needle = 0;
            lineCounter = 1;
            while (true)
            {
                var token = ReadToken();
                if (token.Type == TokenType.EndOfFile) { yield break; }

                yield return token;
            }
        }

        public Token ReadToken()
        {
            try
            {
                Token token = new Token();
                while (token.Type == TokenType.Unknown)
                {
                    char c = GetFirstNonSpaceChar();
                    if (SkipIfMatch("//")) {
                        SkipUntil("\n");
                        continue;
                    }
                    if (IsIdentifierStart(c)) { Filter_ReservedWords(token);           break; }
                    if (IsDigit(c))           { ReadNumber(token);                     break; }
                    if (SkipIfMatch("==", token, TokenType.Operator, TokenType.IsEqual)) break;
                    if (SkipIfMatch("!=", token, TokenType.Operator, TokenType.NotIsEqual)) break;
                    if (SkipIfMatch("+=", token, TokenType.Operator, TokenType.AddAssign)) break;
                    if (SkipIfMatch("++", token, TokenType.Operator, TokenType.PlusPlus)) break;
                    if (SkipIfMatch("-=", token, TokenType.Operator, TokenType.SubtractAssign)) break;
                    if (SkipIfMatch("--", token, TokenType.Operator, TokenType.MinusMinus)) break;
                    if (SkipIfMatch(">=", token, TokenType.Operator, TokenType.GreaterEqual)) break;
                    if (SkipIfMatch("<=", token, TokenType.Operator, TokenType.LessEqual)) break;
                    if (SkipIfMatch(">>", token, TokenType.Operator, TokenType.ShiftRight)) break;
                    if (SkipIfMatch("<<", token, TokenType.Operator, TokenType.ShiftLeft)) break;
                    if (SkipIfMatch("&&", token, TokenType.Operator, TokenType.LogicalAnd)) break;
                    if (SkipIfMatch("||", token, TokenType.Operator, TokenType.LogicalOr)) break;

                    if (SkipIfMatch("=",  token, TokenType.Operator, TokenType.Assign)) break;
                    if (SkipIfMatch("!",  token, TokenType.Operator, TokenType.Not)) break;
                    if (SkipIfMatch("+",  token, TokenType.Operator, TokenType.Plus)) break;
                    if (SkipIfMatch("-",  token, TokenType.Operator, TokenType.Minus)) break;
                    if (SkipIfMatch(">",  token, TokenType.Operator, TokenType.Greater)) break;
                    if (SkipIfMatch("<",  token, TokenType.Operator, TokenType.Less)) break;
                    if (SkipIfMatch("&",  token, TokenType.Operator, TokenType.Ampersand)) break;
                    if (SkipIfMatch("|",  token, TokenType.Operator, TokenType.ArithmeticOr)) break;
                    if (SkipIfMatch("*",  token, TokenType.Operator, TokenType.Asterisk)) break;
                    if (SkipIfMatch("/",  token, TokenType.Operator, TokenType.Slash)) break;
                    if (SkipIfMatch("%",  token, TokenType.Operator, TokenType.Percentage, TokenType.Modulo)) break;

                    if (SkipIfMatch(";",  token, TokenType.Separator, TokenType.SemiColon)) break;
                    if (SkipIfMatch(",",  token, TokenType.Separator, TokenType.Comma)) break;
                    if (SkipIfMatch(".",  token, TokenType.Separator, TokenType.Dot)) break;
                    if (SkipIfMatch("(",  token, TokenType.Separator, TokenType.OpenBracket)) break;
                    if (SkipIfMatch(")",  token, TokenType.Separator, TokenType.CloseBracket)) break;
                    if (SkipIfMatch("{",  token, TokenType.Separator, TokenType.LeftBrace)) break;
                    if (SkipIfMatch("}",  token, TokenType.Separator, TokenType.RightBrace)) break;
                    if (SkipIfMatch("[",  token, TokenType.Separator, TokenType.LeftSquareBracket)) break;
                    if (SkipIfMatch("]",  token, TokenType.Separator, TokenType.RightSquareBracket)) break;

                    if (SkipIfMatch("\"")) { ReadString(token); break; }
                    if (SkipIfMatch("`"))  { ReadGraveAccentString(token); break; }

                    if (token.Type == TokenType.Unknown)
                    {
                        string[] sourcecodeLines = sourcecode.Split('\n');
                        Compiler.Error($"Unknown token: \'{c}\' at line {lineCounter}: {sourcecodeLines[lineCounter-1]}");
                    }
                }
                token.LineNumber = lineCounter;

                if (token.Contains(TokenType.Assembly))
                {
                    SkipUntil("{");
                    NextChar();
                    string s = ReadMatching(IsNotRightBrace);
                    token.Value = s;
                    NextChar();
                }

                return token;
            }
            catch (Exceptions.EndOfFileException)
            {
                return new Token(TokenType.EndOfFile);
            }
        }


        public void Filter_ReservedWords(Token token)
        {
            string s = ReadMatching(IsIdentifierRest);
            token.Lexeme = s;
            string sLower = s.ToLower();

            void fill(Token token, string lexeme, params TokenType[] tokentypes)
            {
                token.Lexeme = lexeme;
                foreach (TokenType theType in tokentypes)
                    token.AddType(theType);
            }

            if (sLower == "class") { fill(token, sLower, TokenType.Class); return; }
            if (sLower == "and") { fill(token, sLower, TokenType.Operator, TokenType.LogicalAnd); return; }
            if (sLower == "or") { fill(token, sLower, TokenType.Operator, TokenType.LogicalOr); return; }
            if (sLower == "not") { fill(token, sLower, TokenType.Operator, TokenType.Not); return; }
            if (sLower == "poke") { fill(token, sLower, TokenType.Keyword, TokenType.Poke); return; }
            if (sLower == "function") { fill(token, sLower, TokenType.Keyword, TokenType.Function); return; }
            if (sLower == "while") { fill(token, sLower, TokenType.Keyword, TokenType.While); return; }
            if (sLower == "if")    { fill(token, sLower, TokenType.Keyword, TokenType.If);    return; }
            if (sLower == "else")  { fill(token, sLower, TokenType.Keyword, TokenType.Else);  return; }
            if (sLower == "for")   { fill(token, sLower, TokenType.Keyword, TokenType.For);   return; }
            if (sLower == "asm")   { fill(token, sLower, TokenType.Keyword, TokenType.Assembly); return; }
            if (sLower == "break") { fill(token, sLower, TokenType.Keyword, TokenType.Break); return; }
            if (sLower == "null")  { fill(token, sLower, TokenType.Keyword, TokenType.Null); return; }
            if (sLower == "return") { fill(token, sLower, TokenType.Keyword, TokenType.Return); return; }
            if (sLower == "true" || sLower == "false")
            {
                fill(token, sLower, TokenType.Literal);
                token.Datatype = Datatype.GetDatatype("bool");
                token.Value = (sLower == "true");
                return;
            }
            if (Datatype.ContainsDatatype(sLower))
            {
                fill(token, sLower, TokenType.Type);
                token.Datatype = Datatype.GetDatatype(sLower);
                return;
            }

            token.Type = TokenType.Identifier;   // in other cases, it's an identifier
        }


        public string ReadMatching(Func<char, bool> CharValidFunction)
        {
            int startPos = needle;
            while (CharValidFunction(NextChar())) { }
            int endPos = needle;

            return sourcecode.Substring(startPos, endPos - startPos);
        }

        public void ReadHexadecimal(Token token)
        {
            string s = ReadMatching(IsHexadecimalDigit);
            long number = 0;
            foreach (char c in s)
            {
                number = (number * 16) + HexadecimalValue(c);
            }
            token.Datatype = Datatype.GetDatatype("u64");
            token.Value = number;
            token.Lexeme = "0x" + s;
        }

        public void ReadDecimal(Token token)
        {
            string s = ReadMatching(IsDigitOrPoint);

            if (s.Contains("."))
            {
                double d = double.Parse(s, CultureInfo.InvariantCulture);
                token.Datatype = Datatype.GetDatatype("f64");
                token.Value = d;
                token.Lexeme = d.ToString(CultureInfo.InvariantCulture);
                return;
            }

            long number = 0;
            foreach (char c in s)
            {
                number = (number * 10) + (c - '0');
            }
            token.Datatype = Datatype.GetDatatype("i64");
            token.Value = number;
            token.Lexeme = s;
        }

        public void ReadNumber(Token token)
        {
            token.Type = TokenType.Literal;

            if (SkipIfMatch("0X") || SkipIfMatch("0x"))
            {
                ReadHexadecimal(token);
                return;
            }
            ReadDecimal(token);
        }

        public void ReadString(Token token)
        {
            token.Type = TokenType.Literal;
            token.Datatype = Datatype.GetDatatype("string");
            if (CurrentChar() == '\"')
            {
                token.Value = "";
                token.Lexeme = $"\"\"";
            }
            else
            {
                string s = ReadMatching(IsNotStringEnd);
                s = s.Replace("\\r", "\r").Replace("\\n", "\n");
                token.Value = s;
                token.Lexeme = $"\"{s}\"";
            }
            NextChar();
        }

        public void ReadGraveAccentString(Token token)
        {
            token.Type = TokenType.Literal;
            token.Datatype = Datatype.GetDatatype("string");
            if (CurrentChar() == '`')
            {
                token.Value = "";
                token.Lexeme = $"\"\"";
            }
            else
            {
                string s = ReadMatching(IsNotGraveAccentStringEnd);
                s = s.Replace("\\r", "\r").Replace("\\n", "\n");
                token.Value = s;
                token.Lexeme = $"\"{s}\"";
            }
            NextChar();
        }


        public void SkipUntil(string text)
        {
            while (!Match(text)) { NextChar(); }
        }

        public void SkipUntilAfter(string text)
        {
            SkipUntil(text);
            needle += text.Length;
        }

        public bool SkipIfMatch(string text)
        {
            if (Match(text))
            {
                needle = needle + text.Length;
                return true;
            }
            return false;
        }

        public bool SkipIfMatch(string text, Token token, params TokenType[] tokeTypes)
        {
            if (Match(text))
            {
                needle = needle + text.Length;
                token.Lexeme = text;
                token.Types = tokeTypes.ToList();
                return true;
            }
            return false;
        }

        public bool Match(string text)
        {
            return (sourcecode.Substring(needle, text.Length) == text);
        }

        public char NextChar()
        {
            needle += 1;
            return CurrentChar();
        }
        public char UnreadChar()
        {
            needle -= 1;
            return CurrentChar();
        }

        public char CurrentChar()
        {
            if (needle >= sourcecode.Length)
                throw new Exceptions.EndOfFileException();

            return sourcecode[needle];
        }

        public bool IsDigit(char c) { return (c >= '0' && c <= '9'); }
        public bool IsDigitOrPoint(char c) { return (c >= '0' && c <= '9') || c == '.'; }
        public bool IsAlphabetical(char c) { return ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')); }
        public bool IsIdentifierStart(char c) { return (IsAlphabetical(c) || (c == '_')); }
        public bool IsIdentifierRest(char c) { return (IsIdentifierStart(c) || IsDigit(c) || (c == '$')); }
        public bool IsNotStringEnd(char c) { return (c != '\"'); }
        public bool IsNotGraveAccentStringEnd(char c) { return (c != '`'); }
        public bool IsNotRightBrace(char c) { return (c != '}'); }
        public bool IsSpace(char c) { return (c == ' ' || c == '\t' || c == '\r' || c == '\n'); }
        public bool IsHexadecimalDigit(char c) { return (IsDigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')); }
        static int HexadecimalValue(char c)
        {
            if (c >= '0' && c <= '9')
                return c - '0';
            if (c >= 'a' && c <= 'f')
                return c - 'a' + 10;
            return c - 'A' + 10;
        }

        public char GetFirstNonSpaceChar()
        {
            while (true)
            {
                char c = CurrentChar();

                if (c == '\n') { lineCounter++; }
                if (!IsSpace(c)) { return c; }

                NextChar();
            }
        }


        public void WriteDebugInfo(IEnumerable<Token> tokens)
        {
            return; // remove if you want debug info

            string[] sourcecodeLines = sourcecode.Split('\n');
            int lastSourcecodeLineShown = 0;
            foreach (var token in tokens) {
                if (token.LineNumber > lastSourcecodeLineShown)
                {
                    Console.WriteLine($"\r\n                        { sourcecodeLines[token.LineNumber - 1].Trim() }");
                    lastSourcecodeLineShown = token.LineNumber;
                }
                Console.WriteLine(token);
            }
        }


    }
}
