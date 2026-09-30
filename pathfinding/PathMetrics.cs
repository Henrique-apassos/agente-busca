using Godot;
using System.Collections.Generic;

public static class PathMetrics
{
    // Soma o peso das células em que o agente ENTRA (ignora a célula inicial)
    public static float WeightedCost(GridSnapshot grid, List<Vector2I> path)
    {
        float total = 0f;
        for (int i = 1; i < path.Count; i++)
            total += grid.Get(path[i].X, path[i].Y).Weight;
        return total;
    }
}