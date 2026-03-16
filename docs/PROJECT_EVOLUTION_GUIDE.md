# SharKnight Project Evolution Guide

Este documento foi feito para quem quiser continuar evoluindo o projeto `SharKnight` sem precisar descobrir a estrutura atual por tentativa e erro.

Ele explica:

- como o projeto esta organizado
- como editar e expandir o player
- como substituir placeholders por arte real
- como montar fases
- como configurar inimigos, hazards, agua, escadas, checkpoints e portas
- como manter o projeto consistente
- onde consultar a revisao de prontidao para beta

## 1. Visao Geral da Arquitetura

O projeto foi dividido em modulos para facilitar expansao.

### Core

Responsavel por fluxo do jogo, estado global, fases e objetos de suporte.

Arquivos importantes:

- `scripts/core/main.gd`
- `scripts/core/game_state.gd`
- `scripts/core/level_base.gd`
- `scripts/core/checkpoint.gd`
- `scripts/core/level_door.gd`
- `scripts/core/water_area.gd`
- `scripts/core/ladder_area.gd`
- `scripts/core/game_manager.gd`
- `scripts/core/save_manager.gd`
- `scripts/core/heal_pickup.gd`
- `scripts/core/mana_pickup.gd`
- `scripts/core/upgrade_pickup.gd`

### Player

Separado em orquestracao, movimento, combate e estados.

Arquivos importantes:

- `scripts/player/player.gd`
- `scripts/player/player_movement.gd`
- `scripts/player/player_combat.gd`
- `scripts/player/player_state_machine.gd`
- `scripts/player/player_state.gd`
- `scripts/player/states/*.gd`

### Combat

Scripts reutilizaveis de hitbox, hurtbox e projeteis.

- `scripts/combat/attack_hitbox.gd`
- `scripts/combat/hurtbox.gd`
- `scripts/combat/projectile.gd`

### Enemies

Base compartilhada e inimigos derivados.

- `scripts/enemies/enemy_base.gd`
- `scripts/enemies/*.gd`
- variantes leves por bioma, como `coral_crab.gd` e `abyss_wisp.gd`

### Bosses

- `scripts/bosses/boss_base.gd`
- `scripts/bosses/pirate_captain.gd`
- `scripts/bosses/sea_dragon.gd`
- `scenes/bosses/*.tscn`

### Levels

Cada fase deve seguir a hierarquia padronizada da `LevelBase`.

- `scenes/levels/LevelBase.tscn`
- `scenes/levels/...`

### UI

Telas e HUD desacopladas do resto da logica.

- `scripts/ui/main_menu.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/pause_menu.gd`
- `scripts/ui/game_over_screen.gd`
- `scripts/ui/victory_screen.gd`

## 1.1 Fluxo Atual de UI

O fluxo principal da interface fica em `scripts/core/main.gd`.

Ele controla:

- menu inicial
- HUD
- pause
- game over
- vitoria/fim de fase

As cenas de UI ficam em `scenes/ui/`.

## 2. Como Abrir e Rodar

1. Use Godot `4.6`.
2. Abra `project.godot`.
3. Rode `res://scenes/Main.tscn`.

Para uma revisao priorizada de polimento, sensacao de controle, feedback, testes e preparacao para uma beta jogavel, consulte:

- `docs/BETA_READINESS.md`

## 2.1 Como a HUD se Conecta ao Jogo

A HUD e desacoplada e atualizada por sinais.

Fontes de dados:

- `GameState`: vida, estamina, magia, moedas, projeteis, nome da area e boss
- `Player`: estado atual do personagem

Fluxo atual:

1. `Main.gd` instancia a HUD.
2. `Main.gd` chama `hud.bind_game_state(game_state)`.
3. Quando o level instancia o player, `Main.gd` chama `hud.bind_player(player)`.

### Sinais usados

Do `GameState`:

- `stats_changed`
- `area_changed`
- `boss_changed`

Do `Player`:

- `state_changed`

Isso permite expandir a HUD sem acoplamento forte com scripts de gameplay.

## 2.2 Como Funciona Save e Load

O projeto usa uma solucao simples em JSON.

### Responsabilidades

- `SaveManager`: le e grava o arquivo de save em `user://sharknight_save.json`
- `GameManager`: decide quando criar novo jogo, continuar, salvar progresso e aplicar os dados carregados
- `GameState`: concentra os dados persistentes em memoria

### O que e salvo

- vida maxima
- vida atual
- estamina maxima e atual
- magia maxima e atual
- moedas
- projeteis
- habilidades desbloqueadas
- fase atual
- ultimo checkpoint
- nome da area atual

### Fluxo ao entrar no jogo

1. `Main.gd` cria `GameState`, `SaveManager` e `GameManager`.
2. O menu inicial consulta `game_manager.has_save()`.
3. Se existir save, o botao `Continuar` fica disponivel.
4. Ao clicar em `Continuar`, `GameManager.load_game()` aplica os dados salvos no `GameState`.
5. `Main.gd` carrega a fase salva em `current_level_path`.
6. `LevelBase` usa `checkpoint_tag` e `checkpoint_position` para spawnar o player no ultimo ponto salvo.

### Fluxo de novo jogo

1. `GameManager.new_game()` reseta o `GameState`.
2. Define a fase inicial em `scenes/levels/coast/Level_CoastKingdom.tscn`.
3. Salva um novo arquivo base.
4. `Main.gd` carrega a primeira fase.

## 3. Como o Player Esta Organizado

O player foi montado em composicao.

### `player.gd`

Responsavel por:

- integrar movimento e combate
- conversar com a state machine
- receber dano
- emitir sinais de estado e acao

### `player_movement.gd`

Responsavel por:

- movimento no chao e no ar
- coyote time
- jump buffering
- pulo duplo
- dash
- wall slide
- wall jump
- escadas
- borda
- agua e nado

As habilidades podem ser ativadas e desativadas no Inspector pelo no `Movement`.

Tambem ficam no `Movement` os ajustes finos de sensacao, como:

- `coyote_time`
- `jump_buffer_time`

Exemplos:

- `enable_double_jump`
- `enable_dash`
- `enable_wall_slide`
- `enable_wall_jump`
- `enable_ladder_climb`
- `enable_ledge_hang`
- `enable_swim`

### `player_combat.gd`

Responsavel por:

- combo
- ataques especiais
- projeteis
- bloqueio
- cooldowns
- custos de estamina e magia
- hitboxes temporarias

### `states/`

Cada estado existe em um arquivo separado.

Quando for adicionar uma habilidade nova, o padrao recomendado e:

1. criar ou reutilizar logica em `player_movement.gd` ou `player_combat.gd`
2. criar um estado novo em `scripts/player/states/`
3. adicionar o no do estado em `Player.tscn`
4. ligar as transicoes no estado adequado

## 4. Como Substituir Placeholders por Imagens Reais

Hoje varios elementos ainda usam placeholders gerados por script ou `ColorRect`.

### Player e inimigos

Atualmente alguns sprites sao criados em runtime como blocos coloridos.

Para substituir:

1. Abra a cena correspondente no editor.
2. Selecione o `Sprite2D`.
3. Defina uma textura real no campo `Texture`.
4. Ajuste `offset`, `scale` e `flip_h` se necessario.
5. Se for usar sprite sheet, troque `Sprite2D` por `AnimatedSprite2D` ou `AnimationTree` quando fizer sentido.

Se mudar para `AnimatedSprite2D`, revise os scripts que hoje acessam:

- `BodySprite`
- `ShieldSprite`
- `Sprite2D`

### Tiles e cenarios

Os visuais de fase ainda usam `ColorRect` e corpos simples em alguns pontos.

Para substituir por tiles reais:

1. Crie uma textura com tiles 16x16.
2. Crie um `TileSet` na Godot.
3. Configure o tamanho das celulas para `16x16`.
4. Crie uma ou mais `TileMapLayer`.
5. Use as layers certas para chao, detalhe, agua e decoracao.

## 5. Como Trabalhar com TileMap e TileSet 16x16

Recomendacao:

- 1 `TileSet` por bioma ou por conjunto grande de tiles
- `TileMapLayer` separados por funcao

Sugestao de layers:

- `Ground`
- `OneWay`
- `Hazards`
- `WaterVisual`
- `DecorationBack`
- `DecorationFront`

Boas praticas:

- mantenha colisao apenas nos tiles que realmente precisam
- nao misture decoracao e colisao na mesma layer
- trate agua de gameplay com `WaterArea` e nao apenas com tile visual
- use `DecorationFront` para vegetacao, correntes, algas, colunas e detalhes nao solidos

## 6. Como Montar uma Fase Nova

Sempre parta de `LevelBase` ou duplique uma fase existente ja organizada.

Hierarquia recomendada:

- `Backgrounds/Far`
- `Backgrounds/Mid`
- `Backgrounds/Near`
- `TileLayers/Ground`
- `TileLayers/Details`
- `TileLayers/Hazards`
- `TileLayers/Water`
- `TileLayers/Decoration`
- `Gameplay/Actors`
- `Gameplay/Enemies`
- `Gameplay/Pickups`
- `Gameplay/HazardInstances`
- `Gameplay/Checkpoints`
- `Gameplay/Doors`
- `Gameplay/Triggers`
- `SpawnPoints`

### Como usar `SpawnPoints`

Adicione `Marker2D` com nomes claros:

- `start`
- `door_north`
- `door_boss`
- `secret_exit`

### Como usar checkpoints

Instancie `scenes/core/Checkpoint.tscn` dentro de:

- `Gameplay/Checkpoints`

Configure no Inspector:

- `checkpoint_tag`

### Como usar portas

Instancie `scenes/core/LevelDoor.tscn` dentro de:

- `Gameplay/Doors`

Configure no Inspector:

- `next_level_path`
- `target_spawn_tag`

As fases atuais tambem usam portas especiais para rotas alternativas entre biomas. Para isso, basta apontar a porta para a mesma fase de destino com outro `target_spawn_tag`.

## 7. Como Usar Agua e Escadas

### Agua

Use:

- `scenes/core/WaterArea.tscn`

Coloque a instancia em uma regiao liquida e ajuste o `CollisionShape2D`.

O player detecta a zona e entra na logica de nado.

### Escada

Use:

- `scenes/core/LadderArea.tscn`

Ajuste a altura da escada no `CollisionShape2D`.

O player sobe quando entra na area e usa input vertical.

## 8. Como Configurar Inimigos

Todos os inimigos foram reorganizados para seguir a base:

- `scripts/enemies/enemy_base.gd`

### O que a base ja oferece

- vida
- dano
- patrulha
- perseguição
- knockback
- morte
- drops opcionais
- estado simples textual para IA

### Como criar um inimigo novo

1. Crie um script em `scripts/enemies/`.
2. Faça `extends EnemyBase`.
3. Implemente `update_enemy(delta)`.
4. Ajuste exports como:
   - `max_health`
   - `patrol_speed`
   - `chase_range`
   - `attack_range`
   - `drop_scene`
   - `drop_count`
5. Crie a cena correspondente em `scenes/enemies/`.

Exemplos atuais:

- `CoralCrab`: pressao curta no chao, bom para recifes e planicies alagadas
- `AbyssWisp`: flutua e investe, bom para areas de baixa visibilidade

### Nós recomendados na cena do inimigo

- `Sprite2D`
- `Hurtbox`
- `HurtFlashTimer`
- `AttackCooldownTimer`
- opcional `PlayerDetector`
- opcional `ContactArea`
- opcional `ProjectileSpawn`

## 9. Como Substituir Drops, Pickups e Props

Hoje os drops podem usar cenas simples como moedas.

Para criar itens novos:

1. Crie a cena em `scenes/core/` ou `scenes/items/`.
2. Adicione o script com a logica de coleta.
3. Atribua essa cena em `drop_scene` no inimigo.
4. Defina `drop_count`.

## 9.1 Itens de Progressao e Consumiveis

Exemplos prontos:

- `scenes/core/Coin.tscn`
- `scenes/core/HealPickup.tscn`
- `scenes/core/ManaPickup.tscn`
- `scenes/core/UpgradePickup.tscn`

### HealPickup

Recupera vida atual.

### ManaPickup

Recupera magia e pode tambem reabastecer projeteis.

### UpgradePickup

Pode fazer tres coisas:

- aumentar vida maxima
- aumentar magia maxima
- desbloquear habilidade permanente

No Inspector, configure:

- `upgrade_type`
- `amount`
- `ability_id`

Exemplos de `ability_id`:

- `double_jump`
- `dash`
- `wall_slide`
- `wall_jump`
- `ledge_hang`
- `swim`

## 9.2 Como Checkpoints Salvam o Progresso

Cada checkpoint pode ter um `checkpoint_tag`.

Quando o player toca o checkpoint:

1. o script `checkpoint.gd` detecta o player
2. recupera o `GameState`
3. registra:
   - posicao do checkpoint
   - tag do checkpoint
   - caminho da fase atual
4. emite mudanca de progressao
5. o `GameManager` faz autosave

Na hora de carregar:

1. `LevelBase` verifica se existe checkpoint salvo
2. tenta usar um `Marker2D` com o mesmo nome da `checkpoint_tag`
3. se nao encontrar, usa a posicao salva diretamente

## 10. Como Ligar Animacoes no Futuro

O projeto foi preparado para isso, mas ainda nao esta com arte final.

### Player

Sinais uteis:

- `state_changed`
- `combat_action_started`
- `combat_action_finished`
- `mobility_state_changed`

### Inimigos

Sinais uteis:

- `state_changed`
- `enemy_died`

Recomendacao:

- usar `AnimatedSprite2D` para prototipagem
- migrar para `AnimationTree` quando o numero de animacoes crescer

## 10.1 Como Evoluir a UI

Telas atuais:

- `scenes/ui/MainMenu.tscn`
- `scenes/ui/PauseMenu.tscn`
- `scenes/ui/GameOverScreen.tscn`
- `scenes/ui/VictoryScreen.tscn`
- `scenes/ui/HUD.tscn`

### Substituir placeholders visuais da UI

Para trocar os placeholders atuais por arte real:

1. abra a cena da UI no editor
2. substitua `PanelContainer`, `ColorRect` e labels simples por assets reais
3. mantenha a hierarquia dos nos quando possivel
4. ajuste margens, fontes e tamanhos sem quebrar os caminhos usados nos scripts

Direcao visual sugerida:

- conchas
- coral
- metal enferrujado
- pergaminho molhado

### Barra de boss

A HUD ja possui um bloco de boss.

Para usar:

1. chame `game_state.set_boss_state(true, "Nome do Boss", vida_atual, vida_maxima)`
2. atualize os valores durante a luta
3. ao encerrar a luta, chame `game_state.set_boss_state(false)`

### Nome da area

As fases baseadas em `LevelBase` usam `area_name`.

Quando o level e carregado, o nome da area vai para o `GameState`, e a HUD atualiza automaticamente.

## 11. Como Manter o Projeto Organizado

Padroes recomendados:

- um script por responsabilidade principal
- cenas pequenas e reutilizaveis
- estados separados por arquivo
- hazards e props como cenas independentes
- fases seguindo a mesma hierarquia
- nomes claros e previsiveis

Evite:

- adicionar logica grande direto em `Main.tscn`
- misturar decoracao com colisao
- colocar tudo em um unico script de player
- criar fases fora do padrao de `LevelBase`

## 12. Roadmap Tecnico Natural

Boas proximas evolucoes:

- integrar arte final e sprite sheets
- conectar animacoes
- migrar visuais de fase para `TileMapLayer`
- adicionar audio e VFX
- ligar portas entre fases reais
- criar bosses e mini-bosses
- expandir hazards por bioma

## 13. Resumo Pratico

Se voce for evoluir o projeto:

1. use Godot 4.6
2. respeite a hierarquia de `LevelBase`
3. mantenha player dividido em movimento, combate e estados
4. estenda inimigos a partir de `EnemyBase`
5. troque placeholders gradualmente por arte real
6. use cenas reutilizaveis para hazards, portas, agua e escadas
