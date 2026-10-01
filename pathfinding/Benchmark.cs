using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

public partial class Benchmark : Node
{
	// Devem ser iguais aos do GridManager 
	const int GridWidth = 50;
	const int GridDepth = 50;
	const float NoiseScale = 0.25f;
	const float WaterLevel = -0.4f;
	const float MudLevel = 0.1f;
	const float ObstacleThreshold = 0.5f;

	// Parâmetros do teste
	const int Scenarios = 300;
	const int BaseSeed = 12345;
	const int Warmup = 30;

	class Row
	{
		public int Scenario;
		public string Algorithm;
		public bool Found;
		public double TimeUs;
		public float Cost;
		public int Expanded;
		public int MaxFrontier;
		public int PathLen;
		public float OptimalCost;
	}

	public override void _Ready()
	{
		var algorithms = new IPathfindingAlgorithm[]
		{
			new BfsAlgorithm(),
			new DfsAlgorithm(),
			new DijkstraAlgorithm(),
			new GreedyBestFirstAlgorithm(),
			new AStarAlgorithm()
		};

		// Aquecimento do JIT 
		for (int i = 0; i < Warmup; i++)
		{
			var (g, s, e) = BuildScenario(-1 - i);
			if (s == e) continue;
			foreach (var alg in algorithms) alg.FindPath(g, s, e);
		}

		var rows = new List<Row>();
		int unreachable = 0;

		for (int i = 0; i < Scenarios; i++)
		{
			var (grid, start, goal) = BuildScenario(i);
			var scenarioRows = new List<Row>();

			foreach (var alg in algorithms)
			{
				var sw = Stopwatch.StartNew();
				var res = alg.FindPath(grid, start, goal);
				sw.Stop();

				scenarioRows.Add(new Row
				{
					Scenario = i,
					Algorithm = alg.AlgorithmName,
					Found = res.Found,
					TimeUs = sw.ElapsedTicks * 1_000_000.0 / Stopwatch.Frequency,
					Cost = res.Found ? PathMetrics.WeightedCost(grid, res.Path) : 0f,
					Expanded = res.NodesExplored,
					MaxFrontier = res.MaxFrontier,
					PathLen = res.Found ? res.Path.Count - 1 : 0
				});
			}

			if (!scenarioRows[0].Found) { unreachable++; continue; }

			float optimal = scenarioRows.First(r => r.Algorithm == "Dijkstra").Cost;
			foreach (var r in scenarioRows) { r.OptimalCost = optimal; rows.Add(r); }
		}

		WriteCsv(rows);
		PrintSummary(rows, algorithms, unreachable);
		GetTree().Quit();
	}

	static (GridSnapshot, Vector2I, Vector2I) BuildScenario(int index)
	{
		var rng = new Random(BaseSeed + index);
		var grid = GenerateGrid(rng.Next(), rng.Next());

		Vector2I goal, start;
		do { goal = new Vector2I(rng.Next(GridWidth), rng.Next(GridDepth)); }
		while (!grid.Get(goal.X, goal.Y).IsWalkable);

		do { start = new Vector2I(rng.Next(GridWidth), rng.Next(GridDepth)); }
		while (start == goal ||
			!(grid.Get(start.X, start.Y).Terrain == TerrainType.Grass ||
			  grid.Get(start.X, start.Y).Terrain == TerrainType.Mud));

		return (grid, start, goal);
	}

	static GridSnapshot GenerateGrid(int seedTerrain, int seedObstacle)
	{
		var noise = new FastNoiseLite { NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex, Seed = seedTerrain };
		var obstacleNoise = new FastNoiseLite { NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex, Seed = seedObstacle };
		var grid = new GridSnapshot(GridWidth, GridDepth);
		float k = 1.0f / NoiseScale;

		for (int x = 0; x < GridWidth; x++)
		{
			for (int z = 0; z < GridDepth; z++)
			{
				float n = noise.GetNoise2D(x * k, z * k);
				TerrainType terrain;
				float weight;

				if (n < WaterLevel)
				{
					terrain = TerrainType.Water;
					float depth = Mathf.InverseLerp(WaterLevel, -1.0f, n);
					weight = Mathf.Lerp(3.0f, 8.0f, depth);
				}
				else if (n < MudLevel)
				{
					terrain = TerrainType.Mud;
					float wetness = Mathf.InverseLerp(MudLevel, WaterLevel, n);
					weight = Mathf.Lerp(1.5f, 4.0f, wetness);
				}
				else
				{
					terrain = TerrainType.Grass;
					weight = 1.0f;
				}

				if (obstacleNoise.GetNoise2D(x * k, z * k) > ObstacleThreshold)
				{
					terrain = TerrainType.Obstacle;
					weight = -1.0f;
				}

				grid.Set(x, z, new GridCell
				{
					GridPos = new Vector2I(x, z),
					WorldPos = new Vector3(x, 0, z),
					Terrain = terrain,
					Weight = weight
				});
			}
		}
		return grid;
	}

	static void WriteCsv(List<Row> rows)
	{
		var sb = new StringBuilder();
		sb.AppendLine("cenario,algoritmo,tempo_us,custo,custo_otimo,expandidos,max_fronteira,tam_caminho");
		foreach (var r in rows)
			sb.AppendLine(FormattableString.Invariant(
				$"{r.Scenario},{r.Algorithm},{r.TimeUs:F2},{r.Cost:F2},{r.OptimalCost:F2},{r.Expanded},{r.MaxFrontier},{r.PathLen}"));

		string path = ProjectSettings.GlobalizePath("user://benchmark.csv");
		File.WriteAllText(path, sb.ToString());
		GD.Print("CSV salvo em: " + path);
	}

	static (double mean, double std) Stats(IEnumerable<double> values)
	{
		var a = values.ToArray();
		if (a.Length == 0) return (0, 0);
		double m = a.Average();
		double s = a.Length > 1 ? Math.Sqrt(a.Sum(x => (x - m) * (x - m)) / (a.Length - 1)) : 0;
		return (m, s);
	}

	static void PrintSummary(List<Row> rows, IPathfindingAlgorithm[] algorithms, int unreachable)
	{
		int valid = rows.Count / algorithms.Length;
		GD.Print($"=== RESUMO: {valid} cenários com caminho ({unreachable} sem caminho, descartados) ===");

		foreach (var alg in algorithms)
		{
			var r = rows.Where(x => x.Algorithm == alg.AlgorithmName).ToList();
			var t = Stats(r.Select(x => x.TimeUs));
			var c = Stats(r.Select(x => (double)x.Cost));
			var e = Stats(r.Select(x => (double)x.Expanded));
			var f = Stats(r.Select(x => (double)x.MaxFrontier));
			var p = Stats(r.Select(x => (double)x.PathLen));
			var gap = r.Average(x => (x.Cost - x.OptimalCost) / x.OptimalCost * 100.0);
			var pctOpt = r.Count(x => x.Cost <= x.OptimalCost + 1e-3f) * 100.0 / r.Count;

			GD.Print(FormattableString.Invariant(
				$"{alg.AlgorithmName,-18} tempo_us {t.mean,8:F1} ±{t.std,7:F1} | custo {c.mean,7:F2} ±{c.std,6:F2} | gap_vs_otimo {gap,6:F1}% | otimo em {pctOpt,5:F1}% | expandidos {e.mean,7:F1} ±{e.std,6:F1} | fronteira {f.mean,6:F1} | passos {p.mean,6:F1}"));
		}
	}
}