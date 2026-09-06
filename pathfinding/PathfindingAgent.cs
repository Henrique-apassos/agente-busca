using Godot;

public enum AlgorithmType
{
    BFS,
    AStar,
    Dijkstra,
    GreedyBestFirst
}

public partial class PathfindingAgent : MeshInstance3D
{
    [Export] public NodePath GridManagerPath;
    [Export] public NodePath EndMarkerPath;
    [Export] public AlgorithmType SelectedAlgorithm = AlgorithmType.BFS;

    private Node _gridManager;
    private Node3D _endMarker;

    public override void _Ready()
    {
        _gridManager = GetNode(GridManagerPath);
        _endMarker = GetNode<Node3D>(EndMarkerPath);
    }

    public void RunPathfinding()
    {
        var grid = BuildSnapshotFromGridManager();
        Vector2I start = WorldToGrid(GlobalPosition);
        Vector2I goal = WorldToGrid(_endMarker.GlobalPosition);

        IPathfindingAlgorithm algorithm = CreateAlgorithm();
        var result = algorithm.FindPath(grid, start, goal);

        if (result.Found)
        {
            GD.Print($"{algorithm.AlgorithmName}: caminho com {result.Path.Count} passos.");
            GD.Print($"Nós visitados durante a busca ({result.VisitedOrder.Count}): {string.Join(" -> ", result.VisitedOrder)}");
            GD.Print($"Caminho final: {string.Join(" -> ", result.Path)}");
        }
        else
        {
            GD.Print($"{algorithm.AlgorithmName}: nenhum caminho encontrado. Nós visitados: {result.VisitedOrder.Count}");
        }
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