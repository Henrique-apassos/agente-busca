using Godot;
using System.Collections.Generic;

public class DfsAlgorithm : IPathfindingAlgorithm
{
	public string AlgorithmName => "DFS";

	public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal, bool recordSteps = false)
	{
		var resultado = new PathfindingResult();
		var visitados = new HashSet<Vector2I>();
		var veioDe = new Dictionary<Vector2I, Vector2I>();
		var pilha = new Stack<Vector2I>();

		pilha.Push(start);
		if (recordSteps) resultado.Steps.Add(new SearchStep(SearchStepType.FrontierAdded, start));

		while (pilha.Count > 0)
		{
			if (pilha.Count > resultado.MaxFrontier) resultado.MaxFrontier = pilha.Count;
			var atual = pilha.Pop();
			if (visitados.Contains(atual)) continue;
			visitados.Add(atual);

			resultado.VisitedOrder.Add(atual);
			if (recordSteps) resultado.Steps.Add(new SearchStep(SearchStepType.Expanded, atual));

			if (atual == goal)
			{
				resultado.Found = true;
				resultado.Path = ReconstruirCaminho(veioDe, start, goal);
				foreach (var passo in resultado.Path)
					if (passo != start)
						resultado.TotalCost += grid.Get(passo.X, passo.Y).Weight;
				return resultado;
			}

			foreach (var vizinho in grid.GetNeighbors(atual))
			{
				var celula = grid.Get(vizinho.X, vizinho.Y);
				if (!celula.IsWalkable || visitados.Contains(vizinho)) continue;

				veioDe[vizinho] = atual;
				pilha.Push(vizinho);
				if (recordSteps) resultado.Steps.Add(new SearchStep(SearchStepType.FrontierAdded, vizinho));
			}
		}

		return resultado;
	}

	private List<Vector2I> ReconstruirCaminho(Dictionary<Vector2I, Vector2I> veioDe, Vector2I inicio, Vector2I objetivo)
	{
		var caminho = new List<Vector2I> { objetivo };
		var atual = objetivo;
		while (atual != inicio)
		{
			atual = veioDe[atual];
			caminho.Add(atual);
		}
		caminho.Reverse();
		return caminho;
	}
}
