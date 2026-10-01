
# Análise dos algoritmos de busca

Comparação de desempenho dos cinco algoritmos implementados no projeto:
**Largura (BFS)**, **Profundidade (DFS)**, **Custo Uniforme (Dijkstra)**,
**Gulosa (Greedy Best-First)** e **A\***.

## Metodologia

Cada algoritmo foi executado em **300 mapas aleatórios** (50×50, com os mesmos
parâmetros de geração do jogo: grama, lama, água e obstáculos). Em cada mapa,
os cinco algoritmos receberam **o mesmo grid, o mesmo ponto de partida e a
mesma comida**, o que torna a comparação justa. O início sempre cai em grama ou
lama e a comida em qualquer célula livre, como no jogo.

Um dos 300 cenários não tinha caminho entre início e comida e foi descartado,
restando **299 cenários**. Os mapas usam seed fixa, então o teste é
reproduzível. Foram descartadas 30 execuções de aquecimento (JIT) antes das
medições.

### Pesos dos terrenos

| Terreno | Peso |
|---|---|
| Grama | 1,0 |
| Lama | 1,5 a 4,0 (cresce com a umidade) |
| Água | 3,0 a 8,0 (cresce com a profundidade) |
| Obstáculo | intransponível |

### Critérios de análise

| Critério | Como foi medido |
|---|---|
| Tempo de busca | `Stopwatch` em volta do `FindPath`, em microssegundos (sem a animação) |
| Custo do caminho | Soma dos pesos dos terrenos em que o agente entra (o início não conta) |
| Distância do ótimo | (custo − custo do Dijkstra) ÷ custo do Dijkstra, em % |
| Ótimo em quantos % | Percentual de mapas em que o custo foi igual ao do Dijkstra |
| Nós expandidos | Quantidade de nós em `VisitedOrder` |
| Fronteira máxima | Maior tamanho da fila ou pilha durante a busca |
| Passos | Número de células do caminho |

O custo foi recalculado igual para todos os algoritmos a partir do caminho
final (`PathMetrics.WeightedCost`), porque o `TotalCost` interno do BFS e do
Greedy guarda o número de passos, e não o peso.

## Resultados

Média ± desvio padrão em 299 mapas.

| Algoritmo | Tempo (µs) | Custo do caminho | Acima do ótimo | Ótimo em | Nós expandidos | Fronteira máx. | Passos |
|---|---|---|---|---|---|---|---|
| Largura (BFS) | 438 ± 286 | 73,6 ± 42,8 | +33% | 14% | 1215 | 54 | 34,6 |
| Profundidade (DFS) | 526 ± 371 | 1456 ± 920 | +3063% | 0% | 1143 | 888 | 669,7 |
| Custo Uniforme (Dijkstra) | 839 ± 656 | **53,8 ± 26,3** | 0% | 100% | 1203 | 77 | 37,1 |
| Gulosa | **30 ± 23** | 77,3 ± 47,0 | +38% | 12% | **39** | 66 | 35,9 |
| A* | 374 ± 382 | **53,8 ± 26,3** | 0% | 100% | 484 | 97 | 37,1 |

A coluna "Acima do ótimo" é a média, por cenário, da diferença percentual
entre o custo do algoritmo e o custo ótimo.

## Interpretação

**A\* é o melhor no geral.** Encontrou o caminho de custo mínimo em 100% dos
mapas, igual ao Custo Uniforme, mas expandindo cerca de 60% menos nós (484
contra 1203) e levando menos da metade do tempo. A heurística de Manhattan é
**admissível** neste ambiente, porque o menor peso de terreno é 1 (grama):
ela nunca superestima o custo restante, e por isso o A* mantém a garantia de
otimalidade. Os custos idênticos de A* e Dijkstra em todos os cenários
confirmam isso.

**Custo Uniforme (Dijkstra)** também é ótimo, mas explora em todas as direções
por ordem de custo acumulado (f = g), sem nenhuma informação sobre onde está a
comida. Por isso é o mais lento dos cinco.

**Gulosa** foi a mais rápida, com cerca de 30 µs e apenas 39 nós expandidos.
Porém, como usa só h(n) e ignora o custo já gasto, seu caminho custou em média
38% acima do ótimo e só foi ótimo em 12% dos mapas: ela atravessa água e lama
sem perceber que são caras.

**Largura** encontra o caminho com menos passos (34,6), mas, como não
considera os pesos, trata grama e água como se custassem o mesmo. Resultado:
33% acima do ótimo e ótimo em apenas 14% dos mapas, quando o caminho mais
curto por acaso também era o mais barato.

**Profundidade** teve o pior desempenho. Os caminhos têm quase 670 passos em
média, num grid onde o caminho mais curto tem cerca de 35, e o custo médio é
27 vezes o ótimo. Ela segue um ramo até o fim antes de voltar, não oferece
nenhuma garantia de qualidade, e a pilha chegou a guardar 888 nós pendentes.

### Resumo

| Critério | Melhor |
|---|---|
| Qualidade do caminho (custo) | A* e Custo Uniforme (empate, ambos ótimos) |
| Velocidade | Gulosa |
| Equilíbrio entre custo e esforço | **A\*** |
| Menos passos | Largura |
| Pior em todos os critérios | Profundidade |

Como o objetivo do agente é coletar a comida gastando pouca energia, o que
importa é o custo do caminho, e por isso o A* é a melhor escolha: ele entrega o
caminho ótimo com bem menos esforço de busca que o Custo Uniforme.

### Tempo × nós expandidos

O tempo não é proporcional ao número de nós expandidos. BFS e DFS usam fila e
pilha, que são baratas (cerca de 0,4 µs por nó), enquanto Dijkstra, A* e
Gulosa usam fila de prioridade (cerca de 0,7 a 0,8 µs por nó). Por isso a BFS
é mais rápida que o Dijkstra mesmo expandindo quase o mesmo número de nós, e a
vantagem do A* vem principalmente de expandir bem menos nós.

## Limitações

- O tempo em microssegundos depende da máquina; vale comparar as proporções
  entre os algoritmos, e não os valores absolutos.
- A fronteira máxima do Dijkstra e do A* é levemente superestimada, porque a
  fila de prioridade pode conter o mesmo nó mais de uma vez (a versão antiga é
  ignorada ao sair da fila). Por isso ela não é diretamente comparável à da BFS
  e da DFS.
- Os resultados valem para este gerador de mapas (50×50, pesos de 1 a 8). Mapas
  com outra proporção de obstáculos ou outros pesos podem mudar as diferenças.
- Cenários sem caminho (1 em 300) foram descartados.

## Como reproduzir

1. Abra o projeto no Godot 4.7 (.NET) e compile (ícone do martelo).
2. Abra a cena `benchmark.tscn`.
3. Execute a cena atual (**F6**, ou o botão de claquete no canto superior
   direito). Ela roda sozinha, imprime o resumo na aba **Saída** e fecha.
4. O CSV completo (uma linha por algoritmo e cenário) é salvo na pasta de
   dados do usuário do projeto; o caminho aparece na linha `CSV salvo em:`.

Os parâmetros do teste (quantidade de cenários, seed e dimensões do mapa) ficam
nas constantes no topo de `pathfinding/Benchmark.cs`. Os valores do mapa devem
ser iguais aos do nó `GridManager` (`grid_width`, `grid_depth`, `noise_scale`,
`water_level`, `mud_level`, `obstacle_threshold`).

## O que foi adicionado ao código

- `pathfinding/Benchmark.cs`: script do benchmark.
- `pathfinding/PathMetrics.cs`: cálculo do custo real de um caminho.
- `PathfindingResult.MaxFrontier`: métrica de fronteira, atualizada com uma
  linha no início do laço de cada algoritmo. A lógica das buscas não foi
  alterada.
- `benchmark.tscn`: cena que executa o benchmark.