using Godot;
using System.Collections.Generic;

public class AStarAlgorithm : IPathfindingAlgorithm
{
	public string AlgorithmName => "A*";

	public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal)
	{
		var result = new PathfindingResult();
		var gCost = new Dictionary<Vector2I, float> { [start] = 0f };
		var cameFrom = new Dictionary<Vector2I, Vector2I>();
		var pq = new PriorityQueue<Vector2I, float>();
		var visited = new HashSet<Vector2I>();
		pq.Enqueue(start, Heuristic(start, goal));

		while (pq.Count > 0)
		{
			if (pq.Count > result.MaxFrontier) result.MaxFrontier = pq.Count;
    		var current = pq.Dequeue();
			
			var current = pq.Dequeue();
			if (visited.Contains(current)) continue;
			visited.Add(current);
			result.VisitedOrder.Add(current);

			if (current == goal)
			{
				result.Found = true;
				result.Path = ReconstructPath(cameFrom, start, goal);
				result.TotalCost = gCost[goal];
				return result;
			}

			foreach (var neighbor in grid.GetNeighbors(current))
			{
				var cell = grid.Get(neighbor.X, neighbor.Y);
				if (!cell.IsWalkable) continue;

				float tentativeG = gCost[current] + cell.Weight;
				if (!gCost.ContainsKey(neighbor) || tentativeG < gCost[neighbor])
				{
					gCost[neighbor] = tentativeG;
					cameFrom[neighbor] = current;
					pq.Enqueue(neighbor, tentativeG + Heuristic(neighbor, goal));
				}
			}
		}

		return result;
	}

	private float Heuristic(Vector2I a, Vector2I b)
		=> Mathf.Abs(a.X - b.X) + Mathf.Abs(a.Y - b.Y);

	private List<Vector2I> ReconstructPath(Dictionary<Vector2I, Vector2I> cameFrom, Vector2I start, Vector2I goal)
	{
		var path = new List<Vector2I> { goal };
		var current = goal;
		while (current != start)
		{
			current = cameFrom[current];
			path.Add(current);
		}
		path.Reverse();
		return path;
	}
}
