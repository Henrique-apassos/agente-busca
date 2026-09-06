using Godot;
using System.Collections.Generic;

public class PathfindingResult
{
    public List<Vector2I> Path = new List<Vector2I>();
    public List<Vector2I> VisitedOrder = new List<Vector2I>(); // Ordem em que os nós foram explorados
    public int NodesExplored => VisitedOrder.Count;
    public float TotalCost = 0f;
    public bool Found = false;
}