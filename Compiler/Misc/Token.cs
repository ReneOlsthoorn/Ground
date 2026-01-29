
using GroundCompiler.Expressions;

namespace GroundCompiler
{
    public enum TokenType
    {
        Unknown,
        EndOfFile,
        Identifier,
        Keyword,
        Type,
        Separator,
        Operator,
        BooleanResultOperator,
        Literal,
        Comment,
        Poke,
        IsEqual,      // ==
        NotIsEqual,   // !=
        Not,          // !
        Assign,       // =
        Plus,         // +
        PlusPlus,     // ++
        AddAssign,    // +=
        Minus,        // -
        MinusMinus,   // --
        SubtractAssign, // -=
        Ampersand,    // &
        LogicalAnd,   // &&
        ArithmeticOr, // |
        LogicalOr,    // ||
        Less,         // <
        LessEqual,    // <=
        ShiftLeft,    // <<
        Greater,      // >
        GreaterEqual, // >=
        ShiftRight,   // >>
        SemiColon,    // ;
        Colon,        // :
        OpenBracket,  // (
        CloseBracket, // )
        LeftSquareBracket,  // [
        RightSquareBracket, // ]
        LeftBrace,    // {
        RightBrace,   // }
        Comma,        // ,
        Dot,          // .
        QuestionMark, // ?
        RangeTo,      // ..
        RangeUntil,   // ..<
        Asterisk,     // *
        Slash,        // /
        Caret,        // ^  (xor)
        Percentage,   // %
        Modulo,       // %
        While,        // while
        For,          // for
        In,           // in
        Assembly,     // asm keyword
        Null,         // null
        This,         // this
        LiteralAssemblyPiece, 
        If,           // if
        Else,         // else
        Break,        // break
        Continue,     // continue
        Return,       // return
        Print,        // print statement
        Function,     // function statement
        Class,        // class statement
        Group,        // group statement
        Dll           // Dll statement
    }


    public class Token
    {
        public Token()
        {
            this.Types = new List<TokenType>();
            this.Value = null;
            this.Lexeme = "";
            this.Datatype = null;
            this.Properties = new Dictionary<string, object?>();
        }
        public Token(params TokenType[] types) : this()
        {
            this.Types = types.ToList();
        }

        public List<TokenType> Types;
        public string Lexeme;
        public object? Value;
        public Datatype? Datatype;
        public Dictionary<string, object?> Properties;

        public CompilationSession? CompilationSession;
        public int SourcecodePackIndex;                     // The index in the SourcecodePackHistory list
        public int SourcecodeNeedle;

        public string StringValue
        {
            get
            {
                if (Value == null)
                    return "";

                return (string)Value;
            }
        }

        public TokenType Type { 
            get
            {
                if (Types.Count() == 0)
                    return TokenType.Unknown;

                return Types[Types.Count()-1];
            }
            set { Types = new List<TokenType> { value }; }
        }

        public void AddType(TokenType type) => Types.Add(type);
        public bool Contains(TokenType tokenType) => Types.Contains(tokenType);

        public SourcecodePack? SourcecodePack() => this.CompilationSession?.SourcecodePackHistory[SourcecodePackIndex];

        public int LineNumber()
        {
            int linenr = this.SourcecodePack()?.LineCounter?.GetLineNumberForIndex(this.SourcecodeNeedle) ?? 0;
            return linenr;
        }

        public string LineLocation()
        {
            if (this.SourcecodePack() == null)
                return "";
            return $"line {this.LineNumber()} in {this.SourcecodePack()?.SourceFilename}"; 
        }

        public string SourceFilename() => this.SourcecodePack()?.SourceFilename ?? "";

        public override string ToString()
        {
            string valueAsString = Value?.ToString() ?? "";

            if (this.Datatype?.Name == "string")
                return $"{Types[0]} \"{Utils.StringAsDebug(valueAsString)}\" : {this.LineLocation()}";

            if (Types.Contains(TokenType.Literal))
                return $"{Types[0]} {Utils.StringAsDebug(valueAsString)} : {this.LineLocation()}";

            return $"{Types[0]} {Utils.StringAsDebug(Lexeme)} {valueAsString} : {this.LineLocation()}";
        }

        public static Token GetDefaultIntegerToken()
        {
            Token token = new Token();
            token.Type = TokenType.Literal;
            token.Datatype = Datatype.GetDatatype("i64");
            token.Value = 0;
            token.Lexeme = "0";
            return token;
        }

        public static Token DetermineIntegerToken(List<Token> tokenList, Dictionary<string, Token> defines)
        {
            if (tokenList.Count == 1 && tokenList[0].Contains(TokenType.Literal))
                return tokenList[0];

            for (int i = 0; i < tokenList.Count; i++)
            {
                Token token = tokenList[i];
                if (token.Contains(TokenType.Identifier))
                    tokenList[i] = defines[token.Lexeme];
            }

            // Only i64 multiplications and additions are allowed in define's.
            Token resultToken = GetDefaultIntegerToken();
            resultToken.Value = tokenList[0].Value;
            resultToken.Lexeme = tokenList[0].Lexeme;
            TokenDispenser dispenser = new TokenDispenser(tokenList.Skip(1).ToList());
            while (true)
            {
                Token operatorToken = dispenser.GetNextToken();
                if (operatorToken.Contains(TokenType.EndOfFile))
                    break;
                Token valueToken = dispenser.GetNextToken();
                if (valueToken.Contains(TokenType.EndOfFile))
                    break;
                if (operatorToken.Contains(TokenType.Asterisk))
                    resultToken.Value = Convert.ToInt64(resultToken.Value) * Convert.ToInt64(valueToken.Value);
                if (operatorToken.Contains(TokenType.Plus))
                    resultToken.Value = Convert.ToInt64(resultToken.Value) + Convert.ToInt64(valueToken.Value);
            }
            resultToken.Lexeme = resultToken.Value.ToString();
            return resultToken;
        }
    }
}
