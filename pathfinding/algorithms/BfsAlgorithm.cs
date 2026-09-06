using Godot;
using System.Collections.Generic;

public class BfsAlgorithm : IPathfindingAlgorithm
{
	public string AlgorithmName => "BFS";

	public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal)
	{
		var result = new PathfindingResult();
		var visited = new HashSet<Vector2I> { start };
		var cameFrom = new Dictionary<Vector2I, Vector2I>();
		var queue = new Queue<Vector2I>();
		queue.Enqueue(start);

		while (queue.Count > 0)
		{
			var current = queue.Dequeue();
			result.VisitedOrder.Add(current);

			if (current == goal)
			{
				result.Found = true;
				result.Path = ReconstructPath(cameFrom, start, goal);
				result.TotalCost = result.Path.Count - 1;
				return result;
			}

			foreach (var neighbor in grid.GetNeighbors(current))
			{
				var cell = grid.Get(neighbor.X, neighbor.Y);
				if (!cell.IsWalkable || visited.Contains(neighbor))
					continue;

				visited.Add(neighbor);
				cameFrom[neighbor] = current;
				queue.Enqueue(neighbor);
			}
		}

		return result;
	}

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
