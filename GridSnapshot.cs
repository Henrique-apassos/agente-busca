using Godot;
using System.Collections.Generic;

public enum TerrainType
{
    Grass,
    Mud,
    Water,
    Obstacle
}

public struct GridCell
{
    public Vector2I GridPos;
    public Vector3 WorldPos;
    public TerrainType Terrain;
    public float Weight;

    public bool IsWalkable => Terrain != TerrainType.Obstacle;
}

public class GridSnapshot
{
    public int Width;
    public int Depth;
    private GridCell[,] _cells;

    public GridSnapshot(int width, int depth)
    {
        Width = width;
        Depth = depth;
        _cells = new GridCell[width, depth];
    }

    public GridCell Get(int x, int z) => _cells[x, z];
    public void Set(int x, int z, GridCell cell) => _cells[x, z] = cell;

    public IEnumerable<Vector2I> GetNeighbors(Vector2I pos)
    {
        Vector2I[] dirs = { new Vector2I(1, 0), new Vector2I(-1, 0), new Vector2I(0, 1), new Vector2I(0, -1) };
        foreach (var d in dirs)
        {
            var n = pos + d;
            if (n.X >= 0 && n.X < Width && n.Y >= 0 && n.Y < Depth)
                yield return n;
        }
    }
}