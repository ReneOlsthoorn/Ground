
namespace GroundCompiler
{
    public abstract class AstNode
    {
        public AstNode? Parent;
        private List<AstNode> _Nodes;
        public Dictionary<string, object?> Properties;

        public AstNode()
        {
            Parent = null;
            _Nodes = new List<AstNode>();
            Properties = new Dictionary<string, object?>();
        }

        // You can override this Nodes property if you want to add AstNode elements that are outside the _Nodes list, like Expression variables such as Condition, ThenClause, etc...
        // So, Nodes is the list that contains the _Nodes list plus the extra custom Node elements like Condition, ThenClause, etc...
        public virtual IEnumerable<AstNode> Nodes
        {
            get
            {
                foreach (AstNode node in _Nodes)
                    yield return node;
            }
        }

        // AllNodes is recursive. Nodes is not recursive.
        public virtual IEnumerable<AstNode> AllNodes()
        {
            yield return this;
            foreach (AstNode node in Nodes)
            {
                foreach (AstNode child in node.AllNodes())
                    yield return child;
            }
        }

        public void AddNode(AstNode node, int? theIndex = null) {
            if (theIndex != null)
                _Nodes.Insert(theIndex.Value, node);
            else
                _Nodes.Add(node);
        }

        public AstNode? FindParentType(Type typeToFind)
        {
            if (this.GetType().IsAssignableTo(typeToFind))
                return this;

            if (Parent != null)
                return Parent.FindParentType(typeToFind);

            return null;
        }

        public virtual IEnumerable<AstNode> FindAllNodes(Type typeToFind)
        {
            if (this.GetType() == typeToFind)
                yield return this;

            foreach (AstNode node in Nodes)
            {
                foreach (AstNode child in node.FindAllNodes(typeToFind))
                    yield return child;
            }
        }

        public void UpdateParentInNodes()
        {
            foreach (AstNode node in Nodes)
                node.Parent = this;
        }

        public virtual void Reinitialize() => Initialize();

        public virtual void Initialize()
        {
            UpdateParentInNodes();  // The Initialize might rely on the Parent of all elements already been set, so we have a double Node loop.

            foreach (AstNode node in Nodes)
                node.Initialize();
        }

        public virtual void InitializeDirectNodes()
        {
            foreach (AstNode node in _Nodes)
                node.Parent = this;

            foreach (AstNode node in _Nodes)
                node.Initialize();
        }

        // You must override this method if you have other instance variables like Expression ThenClause, Condition, etc... because those variables must also receive a ReplaceInteralAstNode.
        public virtual bool ReplaceNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < _Nodes.Count; i++)
            {
                AstNode node = _Nodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    _Nodes[i] = newNode;
                    return true;
                }
            }
            return false;
        }

        public virtual void RemoveNode(AstNode nodeToRemove) => _Nodes.Remove(nodeToRemove);

        public Scope? GetScope()
        {
            var scopeStmt = this as IScopeStatement;
            Scope? scope = scopeStmt?.GetScopeFromStatement();
            return (scope != null) ? scope : Parent?.GetScope();
        }

        public Scope? GetRootScope()
        {
            return GetScope()?.GetRootScope();
        }

    }
}
