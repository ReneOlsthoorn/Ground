using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace GroundCompiler.AstNodes
{
    public abstract class AstNode
    {
        public AstNode? Parent;
        public List<AstNode> Nodes;
        public Dictionary<string, object?> Properties;

        public AstNode()
        {
            Parent = null;
            Nodes = new List<AstNode>();
            Properties = new Dictionary<string, object?>();
        }

        public virtual IEnumerable<AstNode> AllNodes()
        {
            yield return this;
            foreach (AstNode node in Nodes)
            {
                foreach (AstNode child in node.AllNodes())
                    yield return child;
            }
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


        public virtual void UpdateParentInNodes()
        {
            foreach (AstNode node in Nodes)
                node.Parent = this;
        }

        public virtual void Initialize()
        {
            foreach (AstNode node in Nodes)
                node.Initialize();
        }

        public virtual bool ReplaceInternalAstNode(AstNode oldNode, AstNode newNode)
        {
            for (int i = 0; i < Nodes.Count; i++)
            {
                AstNode node = Nodes[i];
                if (Object.ReferenceEquals(node, oldNode))
                {
                    newNode.Parent = this;
                    Nodes[i] = newNode;
                    return true;
                }
            }
            return false;
        }

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
