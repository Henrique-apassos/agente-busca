using Godot;
using System;
using System.Collections.Generic;

public class GeneticAlgorithm : IPathfindingAlgorithm
{
	public string AlgorithmName => "Algoritmo Genético";

	private const int PopulationSize = 32;
	private const int MaxGenerations = 25;
	private const int EliteCount = 3;
	private const int TournamentSize = 3;
	private const float CrossoverRate = 0.80f;
	private const float MutationRate = 0.55f;

	private readonly Random _rng = new();

	private class Individual
	{
		public List<Vector2I> Path = new();
		public float Cost;
		public float Fitness;
		public bool ReachedGoal;
		public float HeuristicBias;
		public float TerrainWeightBias;
	}

	public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal, bool recordSteps = false)
	{
		var result = new PathfindingResult();

		if (start == goal)
		{
			result.Found = true;
			result.Path.Add(start);
			return result;
		}

		var allVisited = new HashSet<Vector2I>();

		// 1. População Inicial (mais exploratória para evidenciar a evolução ao longo das gerações)
		var population = new List<Individual>(PopulationSize);
		int initialMaxSteps = Math.Max(40, (grid.Width + grid.Depth) * 2);

		for (int i = 0; i < PopulationSize; i++)
		{
			float hBias = 0.15f + (float)_rng.NextDouble() * 0.55f;
			float wBias = 0.05f + (float)_rng.NextDouble() * 0.45f;
			var ind = CreateGuidedIndividual(grid, start, goal, initialMaxSteps, hBias, wBias);
			EvaluateFitness(ind, grid, goal);
			population.Add(ind);
		}

		Individual bestOverall = null;

		// 2. Ciclo Evolutivo
		for (int gen = 0; gen < MaxGenerations; gen++)
		{
			population.Sort((a, b) => b.Fitness.CompareTo(a.Fitness));

			int reachedCount = 0;
			var genUniqueCells = new HashSet<Vector2I>();

			foreach (var ind in population)
			{
				if (ind.ReachedGoal) reachedCount++;
				foreach (var cell in ind.Path)
				{
					genUniqueCells.Add(cell);
					if (allVisited.Add(cell))
						result.VisitedOrder.Add(cell);
				}
			}

			if (genUniqueCells.Count > result.MaxFrontier)
				result.MaxFrontier = genUniqueCells.Count;

			if (bestOverall == null || population[0].Fitness > bestOverall.Fitness)
				bestOverall = CloneIndividual(population[0]);

			// Grava os passos desta geração (indivíduos + melhor caminho da geração)
			if (recordSteps)
			{
				result.Steps.Add(new SearchStep(SearchStepType.GenerationStart, new Vector2I(gen + 1, reachedCount)));

				for (int i = 0; i < population.Count; i++)
				{
					var ind = population[i];
					int status = (i == 0 && ind.ReachedGoal) ? 2 : (ind.ReachedGoal ? 1 : 0);
					result.Steps.Add(new SearchStep(SearchStepType.IndividualStart, new Vector2I(i, status)));

					foreach (var cell in ind.Path)
						result.Steps.Add(new SearchStep(SearchStepType.IndividualStep, cell));
				}

				var bestToDisplay = (bestOverall != null && bestOverall.ReachedGoal) ? bestOverall : population[0];
				foreach (var cell in bestToDisplay.Path)
					result.Steps.Add(new SearchStep(SearchStepType.GenerationBestPath, cell));

				int encodedBestCost = Mathf.RoundToInt(bestToDisplay.Cost * 10f);
				result.Steps.Add(new SearchStep(SearchStepType.GenerationEnd, new Vector2I(encodedBestCost, population.Count)));
			}

			if (population[0].Path.Count <= 1)
				break;

			// Progresso adaptativo dos vieses ao longo das gerações
			float progress = (float)(gen + 1) / MaxGenerations;
			var nextGen = new List<Individual>(PopulationSize);

			// Elitismo
			for (int e = 0; e < EliteCount && e < population.Count; e++)
				nextGen.Add(CloneIndividual(population[e]));

			// Reprodução
			while (nextGen.Count < PopulationSize)
			{
				var parentA = TournamentSelect(population);
				var parentB = TournamentSelect(population);

				Individual child = _rng.NextDouble() < CrossoverRate
					? Crossover(parentA, parentB)
					: CloneIndividual(parentA);

				if (_rng.NextDouble() < MutationRate)
					Mutate(child, grid, goal, progress);

				EvaluateFitness(child, grid, goal);
				nextGen.Add(child);
			}

			population = nextGen;
		}

		if (bestOverall != null && bestOverall.ReachedGoal)
		{
			result.Found = true;
			result.Path = bestOverall.Path;
			result.TotalCost = bestOverall.Cost;
		}

		return result;
	}

	private Individual CreateGuidedIndividual(
		GridSnapshot grid,
		Vector2I start,
		Vector2I goal,
		int maxSteps,
		float hBias,
		float wBias)
	{
		var ind = new Individual
		{
			HeuristicBias = hBias,
			TerrainWeightBias = wBias
		};

		var visited = new HashSet<Vector2I> { start };
		var stack = new List<Vector2I> { start };

		int steps = 0;
		var candidates = new List<Vector2I>(4);
		var weights = new List<float>(4);

		while (stack.Count > 0 && steps < maxSteps)
		{
			steps++;
			Vector2I current = stack[^1];

			if (current == goal)
			{
				ind.ReachedGoal = true;
				break;
			}

			candidates.Clear();
			weights.Clear();
			float totalWeight = 0f;

			foreach (var n in grid.GetNeighbors(current))
			{
				var cell = grid.Get(n.X, n.Y);
				if (!cell.IsWalkable || visited.Contains(n))
					continue;

				float distDelta = Heuristic(current, goal) - Heuristic(n, goal);
				float hScore = Mathf.Exp(distDelta * hBias);
				float wScore = 1f / Mathf.Pow(Mathf.Max(1f, cell.Weight), wBias);
				float score = Mathf.Max(0.01f, hScore * wScore);

				candidates.Add(n);
				weights.Add(score);
				totalWeight += score;
			}

			if (candidates.Count == 0)
			{
				if (stack.Count > 1)
					stack.RemoveAt(stack.Count - 1);
				else
					break;
				continue;
			}

			float pick = (float)_rng.NextDouble() * totalWeight;
			Vector2I chosen = candidates[^1];
			float accum = 0f;
			for (int i = 0; i < candidates.Count; i++)
			{
				accum += weights[i];
				if (pick <= accum)
				{
					chosen = candidates[i];
					break;
				}
			}

			visited.Add(chosen);
			stack.Add(chosen);
		}

		ind.Path = EraseLoops(stack);
		ind.ReachedGoal = ind.Path.Count > 0 && ind.Path[^1] == goal;
		return ind;
	}

	private void EvaluateFitness(Individual ind, GridSnapshot grid, Vector2I goal)
	{
		float cost = 0f;
		for (int i = 1; i < ind.Path.Count; i++)
			cost += grid.Get(ind.Path[i].X, ind.Path[i].Y).Weight;

		ind.Cost = cost;
		ind.ReachedGoal = ind.Path.Count > 0 && ind.Path[^1] == goal;

		if (ind.ReachedGoal)
		{
			ind.Fitness = 10000f / (1f + cost);
		}
		else if (ind.Path.Count > 0)
		{
			float dist = Heuristic(ind.Path[^1], goal);
			ind.Fitness = 100f / (1f + dist * 8f + cost * 0.15f);
		}
		else
		{
			ind.Fitness = 0f;
		}
	}

	private Individual TournamentSelect(List<Individual> population)
	{
		Individual best = population[_rng.Next(population.Count)];
		for (int i = 1; i < TournamentSize; i++)
		{
			var contender = population[_rng.Next(population.Count)];
			if (contender.Fitness > best.Fitness)
				best = contender;
		}
		return best;
	}

	private Individual Crossover(Individual parentA, Individual parentB)
	{
		if (parentA.Path.Count < 3 || parentB.Path.Count < 3)
			return CloneIndividual(parentA);

		var indexInB = new Dictionary<Vector2I, int>(parentB.Path.Count);
		for (int i = 1; i < parentB.Path.Count - 1; i++)
			indexInB[parentB.Path[i]] = i;

		var commonIndices = new List<(int idxA, int idxB)>();
		for (int i = 1; i < parentA.Path.Count - 1; i++)
		{
			if (indexInB.TryGetValue(parentA.Path[i], out int idxB))
				commonIndices.Add((i, idxB));
		}

		if (commonIndices.Count == 0)
			return CloneIndividual(parentA.Fitness >= parentB.Fitness ? parentA : parentB);

		var (cutA, cutB) = commonIndices[_rng.Next(commonIndices.Count)];
		var rawPath = new List<Vector2I>(cutA + (parentB.Path.Count - cutB));

		for (int i = 0; i <= cutA; i++)
			rawPath.Add(parentA.Path[i]);

		for (int i = cutB + 1; i < parentB.Path.Count; i++)
			rawPath.Add(parentB.Path[i]);

		return new Individual
		{
			Path = EraseLoops(rawPath),
			HeuristicBias = Mathf.Clamp((parentA.HeuristicBias + parentB.HeuristicBias) * 0.5f, 0.2f, 2.2f),
			TerrainWeightBias = Mathf.Clamp((parentA.TerrainWeightBias + parentB.TerrainWeightBias) * 0.5f, 0.2f, 2.5f)
		};
	}

	private void Mutate(Individual ind, GridSnapshot grid, Vector2I goal, float progress)
	{
		if (ind.Path.Count < 2)
			return;

		// Se o indivíduo ainda não alcançou a comida, reconstrói a cauda a partir de um ponto intermediário
		if (!ind.ReachedGoal)
		{
			int cutIdx = _rng.Next(Math.Max(0, ind.Path.Count / 2), ind.Path.Count);
			Vector2I branchStart = ind.Path[cutIdx];
			float hBias = 0.5f + progress * 1.4f;
			float wBias = 0.4f + progress * 1.4f;

			var tail = CreateGuidedIndividual(grid, branchStart, goal, (grid.Width + grid.Depth) * 2, hBias, wBias);
			if (tail.Path.Count > 1)
			{
				var combined = new List<Vector2I>(cutIdx + tail.Path.Count);
				for (int i = 0; i < cutIdx; i++)
					combined.Add(ind.Path[i]);
				foreach (var cell in tail.Path)
					combined.Add(cell);

				ind.Path = EraseLoops(combined);
				ind.ReachedGoal = ind.Path[^1] == goal;
			}
			return;
		}

		// Operador 1: Deslizamento de esquina para suavizar curvas e sair da água/lama
		int flips = Math.Max(2, ind.Path.Count / 5);
		for (int f = 0; f < flips; f++)
		{
			if (ind.Path.Count < 3) break;
			int i = _rng.Next(1, ind.Path.Count - 1);
			Vector2I prev = ind.Path[i - 1];
			Vector2I curr = ind.Path[i];
			Vector2I next = ind.Path[i + 1];

			if (prev.X != next.X && prev.Y != next.Y)
			{
				Vector2I altCorner = new Vector2I(prev.X + next.X - curr.X, prev.Y + next.Y - curr.Y);
				if (altCorner.X >= 0 && altCorner.X < grid.Width && altCorner.Y >= 0 && altCorner.Y < grid.Depth)
				{
					var altCell = grid.Get(altCorner.X, altCorner.Y);
					var currCell = grid.Get(curr.X, curr.Y);

					if (altCell.IsWalkable && (altCell.Weight <= currCell.Weight || _rng.NextDouble() < 0.2))
						ind.Path[i] = altCorner;
				}
			}
		}

		// Operador 2: Reconstrução de sub-trecho (testa desvios por terrenos mais baratos)
		if (ind.Path.Count >= 6 && _rng.NextDouble() < 0.65)
		{
			int idxA = _rng.Next(0, ind.Path.Count - 3);
			int maxSpan = Math.Min(16, ind.Path.Count - 1 - idxA);
			int idxB = idxA + _rng.Next(2, maxSpan + 1);

			Vector2I subStart = ind.Path[idxA];
			Vector2I subGoal = ind.Path[idxB];

			var detour = CreateGuidedIndividual(
				grid,
				subStart,
				subGoal,
				maxSteps: (idxB - idxA) * 4,
				hBias: 0.7f + progress * 1.3f,
				wBias: 0.8f + progress * 1.8f);

			if (detour.ReachedGoal && detour.Path.Count > 1)
			{
				var newPath = new List<Vector2I>(idxA + detour.Path.Count + (ind.Path.Count - idxB));
				for (int i = 0; i < idxA; i++)
					newPath.Add(ind.Path[i]);
				foreach (var p in detour.Path)
					newPath.Add(p);
				for (int i = idxB + 1; i < ind.Path.Count; i++)
					newPath.Add(ind.Path[i]);

				ind.Path = EraseLoops(newPath);
				return;
			}
		}

		ind.Path = EraseLoops(ind.Path);
	}

	private List<Vector2I> EraseLoops(List<Vector2I> rawPath)
	{
		var clean = new List<Vector2I>(rawPath.Count);
		var indexMap = new Dictionary<Vector2I, int>(rawPath.Count);

		foreach (var cell in rawPath)
		{
			if (indexMap.TryGetValue(cell, out int existingIdx))
			{
				for (int j = clean.Count - 1; j > existingIdx; j--)
				{
					indexMap.Remove(clean[j]);
					clean.RemoveAt(j);
				}
			}
			else
			{
				indexMap[cell] = clean.Count;
				clean.Add(cell);
			}
		}

		return clean;
	}

	private Individual CloneIndividual(Individual src)
	{
		return new Individual
		{
			Path = new List<Vector2I>(src.Path),
			Cost = src.Cost,
			Fitness = src.Fitness,
			ReachedGoal = src.ReachedGoal,
			HeuristicBias = src.HeuristicBias,
			TerrainWeightBias = src.TerrainWeightBias
		};
	}

	private float Heuristic(Vector2I a, Vector2I b)
		=> Mathf.Abs(a.X - b.X) + Mathf.Abs(a.Y - b.Y);
}
