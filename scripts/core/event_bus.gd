extends Node
## Global event bus for decoupled communication between game systems.
## Enables damage floaters, status indicators, and animations to react to game events.

# Combat events
signal entity_damaged(entity: Node, damage: int, damage_type: String, source: Node)
signal entity_healed(entity: Node, amount: int, source: Node)
signal entity_died(entity: Node, killer: Node)
signal critical_hit(attacker: Node, target: Node, damage: int)
signal attack_missed(attacker: Node, defender: Node)
signal attack_blocked(attacker: Node, defender: Node, damage_blocked: int)

# Status effect events
signal status_applied(entity: Node, status_name: String, duration: int)
signal status_removed(entity: Node, status_name: String)
signal status_tick(entity: Node, status_name: String, remaining: int)

# Movement events
signal entity_moved(entity: Node, from_pos: Vector2i, to_pos: Vector2i)
signal entity_teleported(entity: Node, from_pos: Vector2i, to_pos: Vector2i)

# Turn events
signal turn_started(entity: Node)
signal turn_ended(entity: Node)
signal player_turn_started()
signal enemy_turn_started()
signal round_completed(round_number: int)

# Item events
signal item_picked_up(entity: Node, item: Resource)
signal item_dropped(entity: Node, item: Resource, position: Vector2i)
signal item_equipped(entity: Node, item: Resource, slot: String)
signal item_unequipped(entity: Node, item: Resource, slot: String)
signal item_used(entity: Node, item: Resource)
signal item_identified(item_data: Variant)

# Ability events
signal ability_used(entity: Node, ability: Resource, targets: Array)
signal ability_failed(entity: Node, ability: Resource, reason: String)
signal lore_learned(entity: Node, monster_type: String, lore_ability: Resource)

# Level events
signal level_entered(depth: int)
signal level_generated(depth: int, width: int, height: int)
signal stairs_found(position: Vector2i, direction: String)

# UI events
signal message_logged(text: String, color: Color)
signal popup_requested(title: String, content: String)
signal inventory_opened()
signal inventory_closed()

# Game state events
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(victory: bool, reason: String)
signal save_requested()
signal load_requested()

# Dialogue/NPC events
signal dialogue_started(npc: Node)
signal dialogue_advanced(npc: Node, text: String)
signal dialogue_ended(npc: Node)
signal npc_interacted(player: Node, npc: Node)

# Quest events
signal quest_updated(quest_state: int)
signal quest_item_received(item_name: String)
signal thrain_encountered()
signal escape_sequence_started()
