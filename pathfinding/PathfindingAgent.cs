using Godot;
using System;
using System.Collections.Generic;

public enum AlgorithmType
{
	BFS,
	AStar,
	Dijkstra,
	GreedyBestFirst
}

public partial class PathfindingAgent : MeshInstance3D
{
	[Signal] public delegate void SearchCompletedEventHandler(string algorithmName, Godot.Collections.Array visitedOrder, Godot.Collections.Array path, bool found);
	[Signal] public delegate void MovementFinishedEventHandler();

	[Export] public NodePath GridManagerPath;
	[Export] public NodePath EndMarkerPath;
	[Export] public AlgorithmType SelectedAlgorithm = AlgorithmType.BFS;
	[Export] public float MoveSpeed = 3.0f;

	private Node _gridManager;
	private Node3D _endMarker;
	private GridSnapshot _lastGrid;
	private List<Vector2I> _lastPath = new();
	private Queue<Vector3> _moveQueue = new();
	private bool _isMoving = false;

	public override void _Ready()
	{
		_gridManager = GetNode(GridManagerPath);
		_endMarker = GetNode<Node3D>(EndMarkerPath);
	}

	public override void _Process(double delta)
	{
		if (!_isMoving || _moveQueue.Count == 0)
			return;

		Vector3 target = _moveQueue.Peek();
		Vector3 direction = target - GlobalPosition;
		float distance = direction.Length();

		if (distance < 0.05f)
		{
			_moveQueue.Dequeue();
			if (_moveQueue.Count == 0)
			{
				_isMoving = false;
				EmitSignal(SignalName.MovementFinished);
			}
			return;
		}

		GlobalPosition += direction.Normalized() * MoveSpeed * (float)delta;
	}

	public void RunPathfinding()
	{
		_lastGrid = BuildSnapshotFromGridManager();
		Vector2I start = WorldToGrid(GlobalPosition);
		Vector2I goal = WorldToGrid(_endMarker.GlobalPosition);

		IPathfindingAlgorithm algorithm = CreateAlgorithm();
		var result = algorithm.FindPath(_lastGrid, start, goal);
		_lastPath = result.Path;

		var visitedArr = new Godot.Collections.Array();
		foreach (var v in result.VisitedOrder)
			visitedArr.Add(v);

		var pathArr = new Godot.Collections.Array();
		foreach (var p in result.Path)
			pathArr.Add(p);

		EmitSignal(SignalName.SearchCompleted, GetAlgorithmName(), visitedArr, pathArr, result.Found);
	}

	public void FollowPath()
	{
		if (_lastPath == null || _lastPath.Count < 2 || _lastGrid == null)
			return;

		_moveQueue.Clear();
		// Pula o índice 0: é a célula onde o agente já está
		for (int i = 1; i < _lastPath.Count; i++)
		{
			var cell = _lastGrid.Get(_lastPath[i].X, _lastPath[i].Y);
			_moveQueue.Enqueue(cell.WorldPos + new Vector3(0, 0.4f, 0));
		}
		_isMoving = true;
	}

	public void CycleAlgorithm()
	{
		int count = Enum.GetValues(typeof(AlgorithmType)).Length;
		SelectedAlgorithm = (AlgorithmType)(((int)SelectedAlgorithm + 1) % count);
	}

	public string GetAlgorithmName()
	{
		return SelectedAlgorithm switch
		{
			AlgorithmType.BFS => "BFS",
			AlgorithmType.AStar => "A*",
			AlgorithmType.Dijkstra => "Dijkstra",
			AlgorithmType.GreedyBestFirst => "Greedy Best-First",
			_ => "Desconhecido"
		};
	}

	private IPathfindingAlgorithm CreateAlgorithm()
	{
		return SelectedAlgorithm switch
		{
			AlgorithmType.BFS => new BfsAlgorithm(),
			// AlgorithmType.AStar => new AStarAlgorithm(),
			// AlgorithmType.Dijkstra => new DijkstraAlgorithm(),
			// AlgorithmType.GreedyBestFirst => new GreedyBestFirstAlgorithm(),
			_ => new BfsAlgorithm()
		};
	}

	private GridSnapshot BuildSnapshotFromGridManager()
	{
		int width = (int)_gridManager.Get("grid_width");
		int depth = (int)_gridManager.Get("grid_depth");
		var snapshot = new GridSnapshot(width, depth);

		var flatData = (Godot.Collections.Array)_gridManager.Call("get_grid_snapshot");

		foreach (Godot.Collections.Dictionary cellDict in flatData)
		{
			int x = (int)cellDict["x"];
			int z = (int)cellDict["z"];
			string terrainStr = (string)cellDict["terrain"];
			float weight = (float)cellDict["weight"];
			Vector3 worldPos = (Vector3)cellDict["world_pos"];

			TerrainType terrain = terrainStr switch
			{
				"water" => TerrainType.Water,
				"mud" => TerrainType.Mud,
				"obstacle" => TerrainType.Obstacle,
				_ => TerrainType.Grass
			};

			snapshot.Set(x, z, new GridCell
			{
				GridPos = new Vector2I(x, z),
				WorldPos = worldPos,
				Terrain = terrain,
				Weight = weight
			});
		}

		return snapshot;
	}

	private Vector2I WorldToGrid(Vector3 worldPos)
	{
		float spacing = (float)_gridManager.Get("cell_spacing");
		return new Vector2I(Mathf.RoundToInt(worldPos.X / spacing), Mathf.RoundToInt(worldPos.Z / spacing));
	}
}
