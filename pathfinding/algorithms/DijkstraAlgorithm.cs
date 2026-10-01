using Godot;
using System.Collections.Generic;

public class DijkstraAlgorithm : IPathfindingAlgorithm
{
	public string AlgorithmName => "Dijkstra";

	public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal)
	{
		var result = new PathfindingResult();
		var dist = new Dictionary<Vector2I, float> { [start] = 0f };
		var cameFrom = new Dictionary<Vector2I, Vector2I>();
		var pq = new PriorityQueue<Vector2I, float>();
		var visited = new HashSet<Vector2I>();
		pq.Enqueue(start, 0f);

		while (pq.Count > 0)
		{
			if (pq.Count > result.MaxFrontier) result.MaxFrontier = pq.Count;
			var current = pq.Dequeue();
			if (visited.Contains(current)) continue;
			visited.Add(current);
			result.VisitedOrder.Add(current);


			if (current == goal)
			{
				result.Found = true;
				result.Path = ReconstructPath(cameFrom, start, goal);
				result.TotalCost = dist[goal];
				return result;
			}

			foreach (var neighbor in grid.GetNeighbors(current))
			{
				var cell = grid.Get(neighbor.X, neighbor.Y);
				if (!cell.IsWalkable) continue;

				float newDist = dist[current] + cell.Weight;
				if (!dist.ContainsKey(neighbor) || newDist < dist[neighbor])
				{
					dist[neighbor] = newDist;
					cameFrom[neighbor] = current;
					pq.Enqueue(neighbor, newDist);
				}
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
