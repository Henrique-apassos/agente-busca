# Agente Busca

Projeto em **Godot 4.7** que simula um agente navegando por um terreno gerado
proceduralmente até encontrar um objetivo, usando algoritmos clássicos de
busca (BFS, A*, Dijkstra, Greedy Best-First).

O mundo (terreno, câmera, cena) é feito em **GDScript**. Os algoritmos de
busca e o comportamento do agente são feitos em **C#**, aproveitando o
suporte nativo do Godot 4 pras duas linguagens conviverem no mesmo projeto.

## Visão geral

- O terreno é gerado por ruído (Simplex noise), formando **grama**, **lama**,
  **água** e **obstáculos** (paredes intransitáveis, geradas em clusters via
  um segundo campo de ruído).
- O **objetivo** (esfera amarela) nasce em qualquer célula que não seja
  obstáculo.
- O **agente** (prisma triangular) nasce em terreno seco (grama ou lama),
  nunca em cima de água, obstáculo ou do próprio objetivo.
- Ao acionar a busca, o agente calcula o caminho com o algoritmo selecionado,
  o grid escurece célula por célula conforme é explorado, e o caminho final
  fica destacado quando encontrado.

## Controles

| Tecla | Ação |
|---|---|
| `C` | Alterna entre câmera livre (voo) e câmera top-down |
| `R` | Recentraliza a câmera livre na posição inicial (com o mouse capturado) |
| `F` | Inicia a busca com o algoritmo selecionado |
| `G` | Agente segue o último caminho encontrado |
| `B` | Troca o algoritmo de busca (BFS → A* → Dijkstra → Greedy) |

Movimentação da câmera livre: `WASD` move no plano horizontal, `Espaço`/`Ctrl`
sobe/desce, `Shift` acelera (sprint), mouse olha ao redor, `ESC` solta o
cursor e clique esquerdo captura de novo.

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
├── assets/                     # Ícones e recursos visuais
├── pathfinding/                # C# — algoritmos de busca e agente
│   ├── GridSnapshot.cs         # Representação do grid pro C# (célula, vizinhos)
│   ├── PathfindingResult.cs    # Resultado padronizado (caminho, nós visitados)
│   ├── IPathfindingAlgorithm.cs# Interface que todo algoritmo implementa
│   ├── PathfindingAgent.cs     # Ponte com o GDScript + controle do agente
│   └── BfsAlgorithm.cs         # Implementação de referência (BFS)
├── scenes/
│   └── mundo.tscn              # Cena principal
└── scripts/                    # GDScript — mundo, câmera, entidades visuais
    ├── entities/
    │   ├── agente.gd
    │   └── end_marker.gd
    └── world/
        ├── camera_3d.gd
        ├── grid_manager.gd     # Geração do terreno + funções de cor/visualização
        └── mundo.gd            # Orquestração da cena, HUD, input
```

## Como adicionar um novo algoritmo de busca

Cada algoritmo é uma classe C# independente, isolada num arquivo dentro de
`pathfinding/`. Isso evita conflitos de merge entre os membros do time.

1. Crie um arquivo novo, ex: `pathfinding/AStarAlgorithm.cs`
2. Implemente a interface `IPathfindingAlgorithm`:

   ```csharp
   using Godot;

   public class AStarAlgorithm : IPathfindingAlgorithm
   {
       public string AlgorithmName => "A*";

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

3. Em `PathfindingAgent.cs`, descomente/adicione a linha correspondente no
   `CreateAlgorithm()`:

   ```csharp
   AlgorithmType.AStar => new AStarAlgorithm(),
   ```

4. Compile e teste trocando o algoritmo pela tecla `B` in-game.

Use o `BfsAlgorithm.cs` como modelo de referência — o padrão de registrar
`VisitedOrder` no momento em que o nó é expandido (retirado da
fila/heap) deve ser seguido por todos os algoritmos, pra visualização e
comparação de métricas ficarem consistentes.

## Tecnologias

- [Godot Engine 4.7](https://godotengine.org/) (.NET/C# build)
- GDScript + C#
- Jolt Physics
