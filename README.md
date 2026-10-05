# Agente Busca

Projeto em **Godot 4.7** que simula um agente autônomo coletando comida num
terreno gerado proceduralmente, usando algoritmos clássicos de busca em
grafo (BFS, DFS, A*, Dijkstra, Greedy Best-First) pra decidir o caminho.

O mundo (terreno, câmera, cena, HUD) é feito em **GDScript**. Os algoritmos
de busca e o comportamento do agente são feitos em **C#**, aproveitando o
suporte nativo do Godot 4 pras duas linguagens conviverem no mesmo projeto.

## Visão geral / ciclo de funcionamento

1. O terreno é gerado por ruído (Simplex noise), formando 4 tipos de célula:
   **grama** (custo baixo), **lama** (custo médio), **água** (custo alto) e
   **obstáculo** (intransitável — paredes geradas em clusters via um segundo
   campo de ruído)
2. O usuário escolhe o algoritmo de busca (tecla `B`)
3. O **agente** (prisma triangular) nasce em terreno seco (grama ou lama),
   nunca em cima de obstáculo
4. A **comida** (esfera amarela) nasce em qualquer célula que não seja
   obstáculo
5. Ao acionar a busca (`F`), o agente usa a posição da comida como estado
   objetivo e sua própria posição como estado inicial
6. O algoritmo selecionado calcula o caminho; o grid escurece célula por
   célula conforme é explorado (visualização da busca), e o caminho final
   fica destacado em dourado quando encontrado
7. O agente segue o caminho (`G`), com velocidade proporcional ao custo do
   terreno de cada célula (mais devagar na água, mais rápido na grama)
8. Quando o agente colide fisicamente com a comida (via `Area3D`/Jolt
   Physics), ela é contabilizada e some; uma nova comida nasce em outra
   posição aleatória automaticamente, repetindo o ciclo a partir do passo 4

## Controles

| Tecla | Ação |
|---|---|
| `C` | Alterna entre câmera livre (voo) e câmera top-down |
| `R` | Recentraliza a câmera livre na posição inicial (com o mouse capturado) |
| `F` | Inicia a busca com o algoritmo selecionado (aperte de novo pra cancelar a animação em andamento e já começar outra) |
| `G` | Agente segue o último caminho encontrado |
| `B` | Troca o algoritmo de busca (BFS → DFS → A* → Dijkstra → Greedy Best-First) |
| `T` | Reinicia agente, comida e contador pra posição/estado inicial — útil pra comparar algoritmos no mesmo cenário |
| `M` | Gera um mapa novo no nível atual |
| `L` | Troca o nível (Fácil → Médio → Difícil) e gera um mapa novo |

Movimentação da câmera livre: `WASD` move no plano horizontal, `Espaço`/`Ctrl`
sobe/desce, `Shift` acelera (sprint), mouse olha ao redor, `ESC` solta o
cursor e clique esquerdo captura de novo.

## HUD

O HUD mostra, em tempo real:

- Modo de câmera atual
- Algoritmo selecionado
- Status da ação atual (buscando, caminho encontrado, movendo, etc.)
- Métricas da busca: tempo real do algoritmo (medido com `Stopwatch`,
  independente da animação visual) e número de nós visitados
- Métricas do movimento: tempo decorrido e custo (peso) acumulado conforme o
  agente atravessa o terreno
- Contador de comidas coletadas (canto superior direito)

## Setup do ambiente

Este projeto usa C#, então é preciso o suporte a **.NET** do Godot, não a
versão "Standard". Os passos gerais são os mesmos em qualquer sistema:

1. Instalar o **.NET SDK 8.0**
2. Baixar/instalar a versão **.NET** do Godot 4.7
3. Abrir o projeto e gerar a solução C# (só na primeira vez)
4. Compilar e rodar

Abaixo, os comandos específicos por sistema operacional.

### Windows

1. Instale o .NET SDK 8.0 (via [winget](https://learn.microsoft.com/windows/package-manager/winget/)
   no PowerShell, ou baixando o instalador em
   [dotnet.microsoft.com/download/dotnet/8.0](https://dotnet.microsoft.com/download/dotnet/8.0)):

   ```powershell
   winget install Microsoft.DotNet.SDK.8
   ```

2. Baixe o **Godot 4.7 — .NET** (não a versão "Standard") em
   [godotengine.org/download/windows](https://godotengine.org/download/windows)
   — é um `.exe`, não precisa instalador, só rodar direto
3. Confirme que instalou certo abrindo um terminal (PowerShell ou cmd):

   ```powershell
   dotnet --version
   ```

### Linux (Debian, Ubuntu e derivados)

1. Instale o .NET SDK 8.0:

   ```bash
   sudo apt update
   sudo apt install -y dotnet-sdk-8.0
   ```

   Se seu Ubuntu/Debian for muito recente e o pacote não estiver disponível
   nos repositórios padrão, adicione o repositório da Microsoft antes:

   ```bash
   wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   rm packages-microsoft-prod.deb
   sudo apt update
   sudo apt install -y dotnet-sdk-8.0
   ```

2. Baixe o **Godot 4.7 — .NET** em
   [godotengine.org/download/linux](https://godotengine.org/download/linux)
   (procure a versão marcada ".NET"), extraia o `.zip` e dê permissão de
   execução:

   ```bash
   chmod +x Godot_v4.7-stable_mono_linux_x86_64
   ```

3. Confirme a instalação:

   ```bash
   dotnet --version
   ```

### Linux (Fedora)

1. Instale o .NET SDK 8.0:

   ```bash
   sudo dnf install dotnet-sdk-8.0
   ```

2. Escolha uma das duas formas de obter o Godot com suporte a .NET:

   - **Flatpak** (recomendado, já vem com o .NET embutido no sandbox):

     ```bash
     flatpak install flathub org.godotengine.GodotSharp
     ```

   - **Ou baixe o `.zip`** em
     [godotengine.org/download/linux](https://godotengine.org/download/linux)
     (versão marcada ".NET"), extraia e dê permissão de execução:

     ```bash
     chmod +x Godot_v4.7-stable_mono_linux_x86_64
     ```

3. Confirme a instalação:

   ```bash
   dotnet --version
   ```

### macOS

1. Instale o .NET SDK 8.0 via Homebrew:

   ```bash
   brew install --cask dotnet-sdk@8
   ```

   (ou baixe o instalador `.pkg` em
   [dotnet.microsoft.com/download/dotnet/8.0](https://dotnet.microsoft.com/download/dotnet/8.0))

2. Baixe o **Godot 4.7 — .NET** em
   [godotengine.org/download/macos](https://godotengine.org/download/macos)
   e arraste pra pasta Aplicativos, como qualquer app do macOS

3. Confirme a instalação:

   ```bash
   dotnet --version
   ```

### Depois de instalado (qualquer sistema)

1. Abra o projeto na versão **.NET** do Godot
2. Na primeira vez, gere a solução C#: **Project → Tools → C# → Create C#
   Solution** (isso cria `agente busca.csproj` e `agente busca.sln` — eles
   ficam versionados no Git, então esse passo só é necessário se esses
   arquivos ainda não existirem no repositório)
3. Compile o projeto (ícone de martelo 🔨 na barra superior do editor)
4. Rode a cena principal (`F5`)

## Estrutura do projeto

```
agente-busca/
├── assets/                           # Ícones e recursos visuais
├── pathfinding/                      # C# — contrato compartilhado e agente
│   ├── GridSnapshot.cs               # Representação do grid pro C# (célula, vizinhos, custo)
│   ├── PathfindingResult.cs          # Resultado padronizado (caminho, nós visitados, custo total)
│   ├── IPathfindingAlgorithm.cs      # Interface que todo algoritmo implementa
│   ├── PathfindingAgent.cs           # Ponte com o GDScript, movimento, colisão, sinais pro HUD
│   └── algorithms/                   # Um arquivo por algoritmo — evita conflito de merge
│       ├── BfsAlgorithm.cs
│       ├── DfsAlgorithm.cs
│       ├── AStarAlgorithm.cs
│       ├── DijkstraAlgorithm.cs
│       └── GreedyBestFirstAlgorithm.cs
├── scenes/
│   └── mundo.tscn                    # Cena principal (grid, agente, comida, câmeras, HUD)
└── scripts/                          # GDScript — mundo, câmera, entidades visuais
    ├── entities/
    │   ├── agente.gd
    │   └── end_marker.gd
    └── world/
        ├── camera_3d.gd              # Câmera livre (WASD + mouse) e reset (R)
        ├── grid_manager.gd           # Geração do terreno + funções de cor/visualização
        └── mundo.gd                  # Orquestração da cena, HUD, input, ciclo de comida
```

## Algoritmos de busca

Todos implementam `IPathfindingAlgorithm` e seguem a mesma convenção: cada
nó é adicionado a `result.VisitedOrder` no momento em que é **expandido**
(retirado da fila/pilha/heap), garantindo que a visualização da busca e as
métricas comparadas no HUD sejam consistentes entre os algoritmos.

| Algoritmo | Estrutura de dados | Considera o custo do terreno? | Garante caminho ótimo? |
|---|---|---|---|
| BFS | Fila (FIFO) | Não (conta só passos) | Só se todos os custos forem iguais |
| DFS | Pilha (LIFO) | Não | Não |
| Dijkstra | Fila de prioridade | Sim | Sim |
| A* | Fila de prioridade + heurística (Manhattan) | Sim | Sim (heurística é admissível) |
| Greedy Best-First | Fila de prioridade (só heurística) | Não | Não |

## Como adicionar um novo algoritmo de busca

Cada algoritmo é uma classe C# independente, isolada num arquivo dentro de
`pathfinding/algorithms/`. Isso evita conflitos de merge entre os membros
do time.

1. Crie um arquivo novo, ex: `pathfinding/algorithms/MeuAlgoritmo.cs`
2. Implemente a interface `IPathfindingAlgorithm`:

   ```csharp
   using Godot;
   using System.Collections.Generic;

   public class MeuAlgoritmo : IPathfindingAlgorithm
   {
       public string AlgorithmName => "Meu Algoritmo";

       public PathfindingResult FindPath(GridSnapshot grid, Vector2I start, Vector2I goal)
       {
           var result = new PathfindingResult();
           // ... sua lógica aqui, registrando cada nó expandido em
           // result.VisitedOrder.Add(...) e preenchendo result.Path,
           // result.Found e result.TotalCost no final
           return result;
       }
   }
   ```

3. Adicione o novo caso em `AlgorithmType` (enum no topo de `PathfindingAgent.cs`)
4. Em `PathfindingAgent.cs`, registre a linha correspondente em `GetAlgorithmName()`
   e em `CreateAlgorithm()`:

   ```csharp
   AlgorithmType.MeuAlgoritmo => new MeuAlgoritmo(),
   ```

5. Compile e teste trocando o algoritmo pela tecla `B` in-game.

Use `BfsAlgorithm.cs` ou `AStarAlgorithm.cs` como modelo de referência pro
padrão de `VisitedOrder` descrito acima.

## Análise dos algoritmos

Os cinco algoritmos foram comparados em 300 mapas aleatórios (mesmo mapa, início
e comida para todos), medindo tempo, custo do caminho, nós expandidos e fronteira.

| Algoritmo | Custo médio | Nós expandidos | Tempo médio (µs) |
|---|---|---|---|
| Largura (BFS) | 74,1 | 1286 | 654 |
| Profundidade (DFS) | 1646 | 1263 | 775 |
| Custo Uniforme (Dijkstra) | 52,7 | 1265 | 1134 |
| Gulosa | 75,2 | 36 | 37 |
| A* | 52,7 | 483 | 475 |

O **A\*** é o melhor no geral: caminho ótimo com ~62% menos nós que o Custo
Uniforme. Detalhes, metodologia e como reproduzir em [ANALISE.md](ANALISE.md).

## Tecnologias

- [Godot Engine 4.7](https://godotengine.org/) (.NET/C# build)
- GDScript + C#
- Jolt Physics (colisão agente ↔ comida via `Area3D`)
