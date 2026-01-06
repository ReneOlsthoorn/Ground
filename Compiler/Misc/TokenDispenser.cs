
namespace GroundCompiler
{
    public class TokenDispenser
    {
        readonly IEnumerator<Token> _tokenEnumerator;
        Stack<Token> pushedBackTokens;

        public TokenDispenser(IEnumerable<Token> tokens) {
            _tokenEnumerator = tokens.GetEnumerator();
            pushedBackTokens = new Stack<Token>();
        }

        public Token GetNextToken()
        {
            if (pushedBackTokens.Count > 0)
                return pushedBackTokens.Pop();

            bool hasNext = _tokenEnumerator.MoveNext();
            if (hasNext)
                return _tokenEnumerator.Current;

            return new Token(TokenType.EndOfFile);
        }

        public void SkipToken()
        {
            GetNextToken();
        }

        public void Match(Token token, TokenType tokenType)
        {
            if (token.Type != tokenType)
                Compiler.Error($"Expected {tokenType.ToString()}.");
        }

        public void MatchNext(TokenType tokenType)
        {
            Token token = GetNextToken();
            Match(token, tokenType);
        }

        public Token PeekNextToken()
        {
            var token = GetNextToken();
            pushedBackTokens.Push(token);
            return token;
        }

        public Token PeekNextToken2()
        {
            var token = GetNextToken();
            var token2 = GetNextToken();
            pushedBackTokens.Push(token2);
            pushedBackTokens.Push(token);
            return token2;
        }

    }
}
