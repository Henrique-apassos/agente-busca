using Godot;
using System.Collections.Generic;

public enum SearchStepType
{
	FrontierAdded,
	Expanded
}

public struct SearchStep
{
	public SearchStepType Type;
	public Vector2I Position;

	public SearchStep(SearchStepType type, Vector2I position)
	{
		Type = type;
		Position = position;
	}
}

public class PathfindingResult
{
	public List<Vector2I> Path = new List<Vector2I>();
	public List<Vector2I> VisitedOrder = new List<Vector2I>();
	public List<SearchStep> Steps = new List<SearchStep>(); // só preenchido quando recordSteps = true
	public int NodesExplored => VisitedOrder.Count;
	public float TotalCost = 0f;
	public bool Found = false;
	public int MaxFrontier = 0;
}
