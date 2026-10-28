class_name MatchState
extends RefCounted

const DB = preload("res://scripts/card_database.gd")
const MAX_HP = 25
const MAX_BOARD = 5
var sides: Array = []
var current := 0
var turn := 0
var winner := -1
var next_uid := 1
var history: Array[String] = []
var rng := RandomNumberGenerator.new()
var ai_level := 1 # 0 easy, 1 normal, 2 hard
# Presentation events (damage, heal, death, ...) queued for the UI; call drain_fx() to consume them.
var fx: Array = []
var win_reason := ""
var omen := ""
var omen_turns := 0
var pending_omen := ""

func fx_add(type: String, side: int, uid: int = -1, amount: int = 0, extra: String = "") -> void:
 fx.append({"type":type,"side":side,"uid":uid,"amount":amount,"extra":extra})
 if fx.size() > 200: fx.pop_front()

func drain_fx() -> Array:
 var events := fx
 fx = []
 return events

func damage_sanctum(side: int, amount: int) -> void:
 if amount <= 0: return
 sides[side].hp -= amount
 fx_add("damage",side,-1,amount)

func heal_sanctum(side: int, amount: int) -> void:
 if omen == "eclipse": return
 var before: int = sides[side].hp
 sides[side].hp = mini(MAX_HP,before + amount)
 var gained: int = sides[side].hp - before
 if gained > 0:
  sides[side].healed = sides[side].get("healed",0) + gained
  fx_add("heal",side,-1,gained)

func start(faction: String = "Greek", seed_value: int = 0, rival: String = "", player_deck: Array = []) -> void:
 if seed_value == 0: rng.randomize()
 else: rng.seed = seed_value
 sides.clear()
 history.clear()
 current = 0
 turn = 0
 winner = -1
 next_uid = 1
 fx.clear()
 win_reason = ""
 omen = ""
 omen_turns = 0
 pending_omen = ""
 if rival == "" or rival == faction:
  var others: Array = DB.FACTIONS.filter(func(f): return f != faction)
  rival = others[rng.randi_range(0,others.size()-1)]
 for f in [faction, rival]:
  var deck := DB.deck(f)
  if sides.is_empty() and not player_deck.is_empty(): deck = player_deck.duplicate()
  for i in range(deck.size() - 1, 0, -1):
   var j := rng.randi_range(0, i)
   var temp = deck[i]
   deck[i] = deck[j]
   deck[j] = temp
  sides.append({"faction":f,"hp":MAX_HP,"power":0,"max_power":0,"deck":deck,"hand":[],"board":[],"fatigue":0,"power_used":false,"mulligan_done":false,"deaths":0,"spells_cast":0,"healed":0})
 for p in range(2):
  for i in range(4): draw_card(p)
 begin_turn(0)

func log_event(message: String) -> void:
 history.push_front(message)
 if history.size() > 40: history.pop_back()

func draw_card(p: int) -> void:
 var s: Dictionary = sides[p]
 if s.deck.is_empty():
  s.fatigue += 1
  damage_sanctum(p,s.fatigue)
  log_event("%s suffers %d fatigue damage." % [s.faction, s.fatigue])
 elif s.hand.size() < 9:
  s.hand.append(s.deck.pop_back())
  fx_add("draw",p)
 else:
  var burned: String = s.deck.pop_back()
  log_event("%s's full hand loses %s." % [s.faction, DB.card(burned).name])
 check_winner()

func begin_turn(p: int) -> void:
 if winner != -1: return
 current = p
 turn += 1
 update_omen(p)
 var s: Dictionary = sides[p]
 s.max_power = mini(s.max_power + 1, 10)
 s.power = s.max_power
 s.power_used = false
 for unit in s.board:
  unit.ready = true
  unit.fresh = false
 log_event("%s turn · %d Power." % [s.faction, s.power])
 fx_add("turn",p)
 check_oath(p,"turn")
 if winner != -1: return
 draw_card(p)
 if omen == "plenty": draw_card(p)

func end_turn(p: int) -> bool:
 if winner != -1 or p != current: return false
 for unit in sides[p].board:
  if unit.get("temp_attack",0) > 0:
   unit.attack -= unit.temp_attack
   unit.temp_attack = 0
 begin_turn(1-p)
 return true

func unit_by_uid(p: int, uid: int) -> Dictionary:
 for unit in sides[p].board:
  if unit.uid == uid: return unit
 return {}

func guards(p: int) -> Array:
 var result: Array = []
 for unit in sides[p].board:
  if unit.get("guard", false): result.append(unit.uid)
 return result

func can_play(p: int, index: int) -> bool:
 if winner != -1 or current != p or index < 0 or index >= sides[p].hand.size(): return false
 var c := DB.card(sides[p].hand[index])
 return card_cost(c) <= sides[p].power and (c.category == "Spell" or sides[p].board.size() < MAX_BOARD)

func card_cost(c: Dictionary) -> int:
 return maxi(0,c.cost - (1 if omen == "stillness" and c.category == "Spell" else 0))

func eff_attack(unit: Dictionary) -> int:
 return unit.get("attack",0) + (1 if omen == "tempest" else 0)

# target_uid -1 denotes the opposing Sanctum. Damage spells bypass Guard.
func play_card(p: int, index: int, target_uid: int = -1) -> bool:
 if not can_play(p, index): return false
 var s: Dictionary = sides[p]
 var c := DB.card(s.hand[index])
 var enemy: Dictionary = sides[1-p]
 if c.get("effect", "") == "damage" and target_uid != -1 and unit_by_uid(1-p,target_uid).is_empty(): return false
 s.power -= card_cost(c)
 s.hand.remove_at(index)
 if c.category == "Spell":
  fx_add("spell",p,target_uid,0,c.effect)
  s.spells_cast = s.get("spells_cast",0) + 1
  match c.effect:
   "heal": heal_sanctum(p,c.amount)
   "damage":
    if target_uid == -1: damage_sanctum(1-p,c.amount)
    else: hurt(unit_by_uid(1-p,target_uid),c.amount)
   "sweep":
    for unit in enemy.board: hurt(unit,c.amount)
   "draw":
    for i in range(c.amount): draw_card(p)
   "buff": buff_allies(p,c.get("buff_attack",0),c.get("buff_health",0),-1)
 else:
  c["uid"] = next_uid
  next_uid += 1
  c["hp"] = c.health
  c["ready"] = c.get("rush",false)
  c["fresh"] = true
  s.board.append(c)
  fx_add("summon",p,c.uid)
  if c.has("heal"): heal_sanctum(p,c.heal)
  if c.has("arrival_damage"):
   for unit in enemy.board: hurt(unit,c.arrival_damage)
  if c.has("arrival_draw"):
   for i in range(c.arrival_draw): draw_card(p)
  if c.has("buff_attack") or c.has("buff_health"):
   buff_allies(p,c.get("buff_attack",0),c.get("buff_health",0),c.uid)
 log_event("%s played %s." % [s.faction,c.name])
 cleanup()
 return true

func can_attack(p: int, uid: int, target_uid: int) -> bool:
 if winner != -1 or current != p: return false
 var attacker := unit_by_uid(p,uid)
 if attacker.is_empty() or not attacker.ready: return false
 var blockers := guards(1-p)
 if not blockers.is_empty() and not blockers.has(target_uid): return false
 if target_uid == -1: return not attacker.fresh
 return not unit_by_uid(1-p,target_uid).is_empty()

func attack(p: int, uid: int, target_uid: int) -> bool:
 if not can_attack(p,uid,target_uid): return false
 var attacker := unit_by_uid(p,uid)
 attacker.ready = false
 fx_add("attack",p,uid,0,str(target_uid))
 if target_uid == -1:
  damage_sanctum(1-p,eff_attack(attacker))
  lifesteal(p,attacker,eff_attack(attacker))
  log_event("%s struck the Sanctum for %d." % [attacker.name,eff_attack(attacker)])
 else:
  var defender := unit_by_uid(1-p,target_uid)
  var dealt := hurt(defender,eff_attack(attacker))
  var taken := hurt(attacker,eff_attack(defender))
  lifesteal(p,attacker,dealt)
  lifesteal(1-p,defender,taken)
  log_event("%s fought %s." % [attacker.name,defender.name])
 cleanup()
 return true

# Removes fallen units, then resolves their Deathrattles until the board settles.
func cleanup() -> void:
 for round in range(20):
  var fallen: Array = []
  for p in range(sides.size()):
   var board: Array = sides[p].board
   for i in range(board.size()-1,-1,-1):
    if board[i].hp <= 0:
     fallen.push_front({"owner":p,"unit":board[i]})
     fx_add("death",p,board[i].uid if board[i].has("uid") else -1)
     sides[p].deaths = sides[p].get("deaths",0) + 1
     board.remove_at(i)
  if fallen.is_empty(): break
  for entry in fallen: trigger_deathrattle(entry.owner,entry.unit)
 check_winner()

func trigger_deathrattle(p: int, unit: Dictionary) -> void:
 var kind: String = unit.get("deathrattle","")
 if kind == "": return
 var amount: int = unit.get("deathrattle_amount",1)
 log_event("%s's last breath triggers." % unit.get("name","A unit"))
 fx_add("deathrattle",p,unit.get("uid",-1),amount,kind)
 match kind:
  "draw":
   for i in range(amount): draw_card(p)
  "damage": damage_sanctum(1-p,amount)
  "heal": heal_sanctum(p,amount)

# Applies damage to a unit; Ward absorbs one instance entirely. Returns damage dealt.
func hurt(unit: Dictionary, amount: int) -> int:
 if amount <= 0: return 0
 if unit.get("ward",false):
  unit.ward = false
  log_event("%s's Ward shatters." % unit.get("name","A unit"))
  fx_add("ward",-1,unit.get("uid",-1))
  return 0
 unit.hp -= amount
 fx_add("damage",-1,unit.get("uid",-1),amount)
 return amount

func lifesteal(p: int, unit: Dictionary, dealt: int) -> void:
 if dealt > 0 and unit.get("lifesteal",false): heal_sanctum(p,dealt)

func buff_allies(p: int, attack_bonus: int, health_bonus: int, except_uid: int) -> void:
 for unit in sides[p].board:
  if unit.get("uid",-2) == except_uid: continue
  unit.attack += attack_bonus
  unit.hp += health_bonus
  fx_add("buff",p,unit.get("uid",-1))

func check_winner() -> void:
 if sides.size() < 2: return
 if winner == -1:
  if sides[0].hp <= 0 and sides[1].hp <= 0: winner = 2
  elif sides[0].hp <= 0: winner = 1
  elif sides[1].hp <= 0: winner = 0
  if winner != -1: win_reason = "sanctum"
 if winner == -1:
  check_oath(current,"total")
  check_oath(1 - current,"total")

func concede(p: int) -> void:
 if winner == -1:
  winner = 1-p
  win_reason = "concede"
  log_event("%s conceded." % sides[p].faction)

# Returns an action without changing state; UI controls pacing.
func ai_action_normal() -> Dictionary:
 var p := current
 if p != 1 or winner != -1: return {}
 var s: Dictionary = sides[p]
 var enemy: Dictionary = sides[0]
 # Always take a legal lethal attack or spell before development.
 for unit in s.board:
  if can_attack(p,unit.uid,-1) and unit.attack >= enemy.hp:
   return {"type":"attack","uid":unit.uid,"target":-1}
 for i in range(s.hand.size()):
  if not can_play(p,i): continue
  var c := DB.card(s.hand[i])
  if c.get("effect","") == "damage" and c.amount >= enemy.hp:
   return {"type":"play","index":i,"target":-1}
 var best_index := -1
 var best_score := -100.0
 for i in range(s.hand.size()):
  if not can_play(p,i): continue
  var c := DB.card(s.hand[i])
  var score := float(c.cost)
  if c.get("effect","") == "heal":
   if s.hp >= MAX_HP-2: continue
   score = 8.0 if s.hp < 10 else 1.0
  elif c.get("effect","") == "damage": score = 2.5
  elif c.get("effect","") == "draw":
   if s.hand.size() >= 8: continue
   score = 2.0
  elif c.get("effect","") == "buff":
   if s.board.is_empty(): continue
   score = 1.5 + s.board.size()
  elif c.get("effect","") == "sweep":
   if enemy.board.size() < 2: continue
   score = 2.0 + enemy.board.size()
  else: score += 2.0
  if score > best_score:
   best_score = score
   best_index = i
 if best_index >= 0:
  var c := DB.card(s.hand[best_index])
  var target := -1
  if c.get("effect","") == "damage":
   var max_attack := -1
   for unit in enemy.board:
    if unit.hp <= c.amount and unit.attack > max_attack:
     max_attack = unit.attack
     target = unit.uid
  return {"type":"play","index":best_index,"target":target}
 for unit in s.board:
  if not unit.ready: continue
  var candidates: Array = []
  for other in enemy.board:
   if can_attack(p,unit.uid,other.uid): candidates.append(other)
  if not candidates.is_empty():
   candidates.sort_custom(func(a,b): return a.attack > b.attack)
   for other in candidates:
    if other.hp <= unit.attack and (unit.hp > other.attack or other.attack >= unit.attack):
     return {"type":"attack","uid":unit.uid,"target":other.uid}
   if not guards(0).is_empty() or not can_attack(p,unit.uid,-1):
    return {"type":"attack","uid":unit.uid,"target":candidates[0].uid}
  if can_attack(p,unit.uid,-1): return {"type":"attack","uid":unit.uid,"target":-1}
 return {"type":"end"}

func execute_ai(action: Dictionary) -> bool:
 match action.get("type",""):
  "play": return play_card(1,action.index,action.target)
  "attack": return attack(1,action.uid,action.target)
  "power": return use_power(1,action.target)
  "end": return end_turn(1)
 return false

# Dispatches to the AI for the configured difficulty. Returns an action without changing state.
func ai_action() -> Dictionary:
 if current != 1 or winner != -1: return {}
 var action: Dictionary
 match ai_level:
  0: action = ai_action_easy()
  2: action = ai_action_hard()
  _: action = ai_action_normal()
 if action.get("type","") == "end" and (ai_level > 0 or rng.randf() < 0.5):
  var extra := ai_power_action()
  if not extra.is_empty(): return extra
 return action

# Easy: plays and attacks at random, only occasionally noticing lethal.
func ai_action_easy() -> Dictionary:
 var s: Dictionary = sides[1]
 var options: Array = []
 for i in range(s.hand.size()):
  if can_play(1,i):
   var c := DB.card(s.hand[i])
   var target := -1
   if c.get("effect","") == "damage" and not sides[0].board.is_empty() and rng.randf() < 0.7:
    target = sides[0].board[rng.randi_range(0,sides[0].board.size()-1)].uid
   options.append({"type":"play","index":i,"target":target})
 for unit in s.board:
  if not unit.ready: continue
  var targets: Array = [-1]
  for other in sides[0].board: targets.append(other.uid)
  targets.shuffle()
  for t in targets:
   if can_attack(1,unit.uid,t):
    options.append({"type":"attack","uid":unit.uid,"target":t})
    break
 if options.is_empty() or rng.randf() < 0.15: return {"type":"end"}
 return options[rng.randi_range(0,options.size()-1)]

# Hard: scores each attack by trade value, prefers lethal, and keeps heals for when they matter.
func ai_action_hard() -> Dictionary:
 var p := 1
 var s: Dictionary = sides[p]
 var enemy: Dictionary = sides[0]
 for unit in s.board:
  if can_attack(p,unit.uid,-1) and unit.attack >= enemy.hp:
   return {"type":"attack","uid":unit.uid,"target":-1}
 for i in range(s.hand.size()):
  if not can_play(p,i): continue
  var c := DB.card(s.hand[i])
  if c.get("effect","") == "damage" and c.amount >= enemy.hp:
   return {"type":"play","index":i,"target":-1}
 # Total reachable face damage this turn plus a burn spell may be lethal; press the Sanctum then.
 var best_play := -1
 var best_play_score := -100.0
 var best_target := -1
 for i in range(s.hand.size()):
  if not can_play(p,i): continue
  var c := DB.card(s.hand[i])
  var score := float(c.cost) + 1.0
  var target := -1
  match c.get("effect",""):
   "heal":
    if s.hp > MAX_HP - 4: continue
    score = (9.0 if s.hp < 9 else 2.0) + (2.0 if DB.oath(s.faction).kind == "healed" else 0.0)
   "draw":
    if s.hand.size() >= 7: continue
    score = 3.0 + (1.5 if s.hand.size() <= 3 else 0.0)
   "buff":
    if s.board.size() < 2: continue
    score = 2.0 + 1.5 * s.board.size()
   "sweep":
    var kills := 0
    for unit in enemy.board:
     if unit.hp <= c.amount: kills += 1
    if kills < 2 and enemy.board.size() < 3: continue
    score = 3.0 + 2.5 * kills + enemy.board.size()
   "damage":
    var best_value := 0.0
    for unit in enemy.board:
     if unit.hp <= c.amount:
      var value: float = unit.cost + unit.attack
      if unit.get("guard",false): value += 2.0
      if value > best_value:
       best_value = value
       target = unit.uid
    if target == -1: continue
    score = 2.0 + best_value
   _:
    score += 2.0
    score += 1.5 * oath_unit_value(p,c)
    if c.has("arrival_draw") or c.has("deathrattle") or c.get("ward",false): score += 0.5
    if c.get("guard",false) and s.hp < 12: score += 2.0
    if s.board.size() >= MAX_BOARD - 1: score -= 1.0
  if score > best_play_score:
   best_play_score = score
   best_play = i
   best_target = target
 var best_attack := {}
 var best_attack_score := 0.0
 for unit in s.board:
  if not unit.ready: continue
  var targets: Array = [-1]
  for other in enemy.board: targets.append(other.uid)
  for t in targets:
   if not can_attack(p,unit.uid,t): continue
   var score := 0.0
   if t == -1:
    score = 2.5 + unit.attack * 0.6 + (4.0 if enemy.hp <= 10 else 0.0)
    if enemy.board.is_empty(): score += 2.0
   else:
    var defender := unit_by_uid(0,t)
    var dealt: int = 0 if defender.get("ward",false) else unit.attack
    var kills: bool = dealt >= defender.hp
    var dies: bool = (0 if unit.get("ward",false) else defender.attack) >= unit.hp
    score = -1.0
    if kills: score += 3.0 + defender.cost + defender.attack * 0.5
    # Break the rival's Oath: remove units it is counting on, most urgently when it is one step away.
    var rival_oath := DB.oath(sides[0].faction)
    var urgency := 1.0 if rival_oath.timing == "turn" and oath_progress(0) >= rival_oath.goal - 1 else 0.35
    if kills: score += 4.0 * oath_unit_value(0,defender) * urgency
    if dies: score -= 2.0 + unit.cost
    if not kills and not dies: score += 1.0
    if defender.get("guard",false): score += 1.5
    if defender.get("deathrattle","") != "" and kills: score -= 1.0
   if score > best_attack_score:
    best_attack_score = score
    best_attack = {"type":"attack","uid":unit.uid,"target":t}
 if best_play >= 0 and (best_attack.is_empty() or best_play_score >= best_attack_score):
  return {"type":"play","index":best_play,"target":best_target}
 if not best_attack.is_empty(): return best_attack
 if best_play >= 0: return {"type":"play","index":best_play,"target":best_target}
 return {"type":"end"}

# --- Pantheon Power -------------------------------------------------------------------
func hero_power_of(p: int) -> Dictionary:
 return DB.hero_power(sides[p].faction)

func power_target_ok(effect: String, unit: Dictionary) -> bool:
 match effect:
  "ward": return not unit.get("ward",false)
  "orders": return not unit.get("ready",false) and not unit.get("fresh",false)
 return true

func can_use_power(p: int, target_uid: int = -1) -> bool:
 if winner != -1 or current != p or sides[p].power_used: return false
 var power := hero_power_of(p)
 if power_cost(p) > sides[p].power: return false
 match power.target:
  "ally":
   var unit := unit_by_uid(p,target_uid)
   return not unit.is_empty() and power_target_ok(power.effect,unit)
  "enemy": return not unit_by_uid(1-p,target_uid).is_empty()
 return true

# Valid targets for the hero power right now: unit uids, [-1] for a targetless power, or [].
func power_targets(p: int) -> Array:
 var power := hero_power_of(p)
 var result: Array = []
 if power.target == "none":
  if can_use_power(p): result.append(-1)
  return result
 var side: int = p if power.target == "ally" else 1 - p
 for unit in sides[side].board:
  if can_use_power(p,unit.uid): result.append(unit.uid)
 return result

func use_power(p: int, target_uid: int = -1) -> bool:
 if not can_use_power(p,target_uid): return false
 var s: Dictionary = sides[p]
 var power := hero_power_of(p)
 s.power -= power_cost(p)
 s.power_used = true
 fx_add("power",p,target_uid,0,power.effect)
 match power.effect:
  "ward": unit_by_uid(p,target_uid).ward = true
  "fury":
   var unit := unit_by_uid(p,target_uid)
   unit.attack += 2
   unit.temp_attack = unit.get("temp_attack",0) + 2
  "orders": unit_by_uid(p,target_uid).ready = true
  "whisper":
   damage_sanctum(1-p,1)
   heal_sanctum(p,1)
  "foxfire": hurt(unit_by_uid(1-p,target_uid),1)
  "harmony":
   draw_card(p)
   heal_sanctum(p,1)
  "blessing":
   var unit := unit_by_uid(p,target_uid)
   unit.attack += 1
   unit.hp += 1
   fx_add("buff",p,target_uid)
 log_event("%s used %s." % [s.faction,power.name])
 cleanup()
 return true

# Spends leftover Power on the hero ability when it is clearly useful.
func ai_power_action() -> Dictionary:
 var p := 1
 var targets := power_targets(p)
 if targets.is_empty(): return {}
 var power := hero_power_of(p)
 var best := -1
 var best_score := -1000.0
 for uid in targets:
  var score := 0.0
  match power.target:
   "none": score = 1.0
   "ally":
    var unit := unit_by_uid(p,uid)
    match power.effect:
     "ward": score = unit.cost + (2.0 if unit.get("guard",false) else 0.0)
     "fury": score = unit.attack + (3.0 if unit.get("ready",false) else -5.0)
     "orders": score = unit.attack + 1.0
     _: score = unit.cost + unit.attack
   "enemy":
    var unit := unit_by_uid(1-p,uid)
    score = 5.0 if unit.hp <= 1 else 2.0 - unit.hp * 0.1 + unit.attack * 0.1
  if score > best_score:
   best_score = score
   best = uid
 if best_score < 0.0: return {}
 return {"type":"power","target":best}

# --- Mulligan -------------------------------------------------------------------------
# Once per side, before the first turn passes: shuffle the chosen hand cards back into the
# deck and draw the same number of replacements. Returns how many cards were swapped.
func can_mulligan(p: int) -> bool:
 return winner == -1 and turn <= 1 and p >= 0 and p < sides.size() and not sides[p].mulligan_done

func mulligan(p: int, indices: Array) -> int:
 if not can_mulligan(p): return -1
 var s: Dictionary = sides[p]
 s.mulligan_done = true
 var picked: Array = []
 for index in indices:
  if index is int and index >= 0 and index < s.hand.size() and not picked.has(index): picked.append(index)
 picked.sort()
 picked.reverse()
 var returned: Array = []
 for index in picked: returned.append(s.hand.pop_at(index))
 if returned.is_empty(): return 0
 # Draw the replacements first so a swapped card cannot come straight back, then reshuffle.
 for i in range(returned.size()):
  if s.deck.is_empty(): break
  s.hand.append(s.deck.pop_back())
 for card_id in returned: s.deck.append(card_id)
 for i in range(s.deck.size() - 1, 0, -1):
  var j := rng.randi_range(0,i)
  var temp = s.deck[i]
  s.deck[i] = s.deck[j]
  s.deck[j] = temp
 log_event("%s swapped %d opening card%s." % [s.faction,returned.size(),"" if returned.size() == 1 else "s"])
 return returned.size()

# The AI throws back expensive cards it cannot cast early (at most two), keeping the rest.
func ai_mulligan() -> int:
 if not can_mulligan(1): return -1
 var picks: Array = []
 for i in range(sides[1].hand.size()):
  if DB.card(sides[1].hand[i]).cost >= 5 and picks.size() < 2: picks.append(i)
 return mulligan(1,picks)

# --- Oaths ----------------------------------------------------------------------------
func oath_progress(p: int) -> int:
 var s: Dictionary = sides[p]
 var oath := DB.oath(s.faction)
 var n := 0
 match oath.kind:
  "gods":
   for unit in s.board: if unit.get("category","") == "God": n += 1
  "attack":
   for unit in s.board: n += unit.get("attack",0)
  "mortals":
   for unit in s.board: if unit.get("category","") == "Mortal": n += 1
  "categories":
   var seen := {}
   for unit in s.board:
    var category: String = unit.get("category","")
    if ["God","Beast","Mortal"].has(category): seen[category] = true
   n = seen.size() if s.board.size() >= oath.get("min_units",0) else 0
  "deaths": n = s.get("deaths",0)
  "spells": n = s.get("spells_cast",0)
  "healed": n = s.get("healed",0)
 return n

func check_oath(p: int, timing: String) -> void:
 if winner != -1 or p < 0 or p >= sides.size(): return
 var oath := DB.oath(sides[p].faction)
 if oath.timing != timing: return
 if oath_progress(p) >= oath.goal:
  winner = p
  win_reason = "oath"
  log_event("%s fulfilled the %s!" % [sides[p].faction,oath.name])
  fx_add("oath",p)

# --- Omens ----------------------------------------------------------------------------
func round_number() -> int:
 return ceili(turn / 2.0)

# Called at the start of every turn. Round 2, 5, 8... announces an omen; the following round it applies.
func update_omen(p: int) -> void:
 var activated := false
 if p == 0 and pending_omen != "" and round_number() % 3 == 0:
  omen = pending_omen
  omen_turns = 2
  pending_omen = ""
  activated = true
  log_event("Omen: %s — %s" % [DB.OMENS[omen].name,DB.OMENS[omen].text])
  fx_add("omen",-1,-1,0,omen)
 if omen != "" and not activated:
  omen_turns -= 1
  if omen_turns <= 0:
   omen = ""
   fx_add("omen_end",-1)
 if p == 0 and omen == "" and pending_omen == "" and round_number() % 3 == 2:
  pending_omen = DB.OMEN_IDS[rng.randi_range(0,DB.OMEN_IDS.size() - 1)]
  log_event("An omen looms: %s next round." % DB.OMENS[pending_omen].name)
  fx_add("omen_warning",-1,-1,0,pending_omen)

func power_cost(p: int) -> int:
 return maxi(0,hero_power_of(p).cost - (1 if omen == "favor" else 0))

# How much a unit (or card) counts toward a side's Oath, 0 to 1; used by the Hard AI.
func oath_unit_value(p: int, unit: Dictionary) -> float:
 var oath := DB.oath(sides[p].faction)
 var category: String = unit.get("category","")
 match oath.kind:
  "gods": return 1.0 if category == "God" else 0.0
  "mortals": return 1.0 if category == "Mortal" else 0.0
  "attack": return clampf(float(unit.get("attack",0)) / 6.0,0.0,1.0)
  "categories":
   var have := {}
   for u in sides[p].board: have[u.get("category","")] = true
   return 1.0 if ["God","Beast","Mortal"].has(category) and not have.has(category) else 0.0
 return 0.0