using Godot;

public interface IPathfindingAlgorithm
{
    string AlgorithmName { get; }
    PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal);
}