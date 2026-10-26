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

func start(faction: String = "Greek", seed_value: int = 0) -> void:
 if seed_value == 0: rng.randomize()
 else: rng.seed = seed_value
 sides.clear()
 history.clear()
 current = 0
 turn = 0
 winner = -1
 next_uid = 1
 for f in [faction, "Norse" if faction == "Greek" else "Greek"]:
  var deck := DB.deck(f)
  for i in range(deck.size() - 1, 0, -1):
   var j := rng.randi_range(0, i)
   var temp = deck[i]
   deck[i] = deck[j]
   deck[j] = temp
  sides.append({"faction":f,"hp":MAX_HP,"power":0,"max_power":0,"deck":deck,"hand":[],"board":[],"fatigue":0})
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
  s.hp -= s.fatigue
  log_event("%s suffers %d fatigue damage." % [s.faction, s.fatigue])
 elif s.hand.size() < 9:
  s.hand.append(s.deck.pop_back())
 else:
  var burned: String = s.deck.pop_back()
  log_event("%s's full hand loses %s." % [s.faction, DB.card(burned).name])
 check_winner()

func begin_turn(p: int) -> void:
 if winner != -1: return
 current = p
 turn += 1
 var s: Dictionary = sides[p]
 s.max_power = mini(s.max_power + 1, 10)
 s.power = s.max_power
 for unit in s.board:
  unit.ready = true
  unit.fresh = false
 log_event("%s turn · %d Power." % [s.faction, s.power])
 draw_card(p)

func end_turn(p: int) -> bool:
 if winner != -1 or p != current: return false
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
 return c.cost <= sides[p].power and (c.category == "Spell" or sides[p].board.size() < MAX_BOARD)

# target_uid -1 denotes the opposing Sanctum. Damage spells bypass Guard.
func play_card(p: int, index: int, target_uid: int = -1) -> bool:
 if not can_play(p, index): return false
 var s: Dictionary = sides[p]
 var c := DB.card(s.hand[index])
 var enemy: Dictionary = sides[1-p]
 if c.get("effect", "") == "damage" and target_uid != -1 and unit_by_uid(1-p,target_uid).is_empty(): return false
 s.power -= c.cost
 s.hand.remove_at(index)
 if c.category == "Spell":
  if c.effect == "heal": s.hp = mini(MAX_HP, s.hp + c.amount)
  elif target_uid == -1: enemy.hp -= c.amount
  else: unit_by_uid(1-p,target_uid).hp -= c.amount
 else:
  c["uid"] = next_uid
  next_uid += 1
  c["hp"] = c.health
  c["ready"] = c.get("rush",false)
  c["fresh"] = true
  s.board.append(c)
  if c.has("heal"): s.hp = mini(MAX_HP,s.hp+c.heal)
  if c.has("arrival_damage"):
   for unit in enemy.board: unit.hp -= c.arrival_damage
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
 if target_uid == -1:
  sides[1-p].hp -= attacker.attack
  log_event("%s struck the Sanctum for %d." % [attacker.name,attacker.attack])
 else:
  var defender := unit_by_uid(1-p,target_uid)
  defender.hp -= attacker.attack
  attacker.hp -= defender.attack
  log_event("%s fought %s." % [attacker.name,defender.name])
 cleanup()
 return true

func cleanup() -> void:
 for s in sides:
  for i in range(s.board.size()-1,-1,-1):
   if s.board[i].hp <= 0: s.board.remove_at(i)
 check_winner()

func check_winner() -> void:
 if sides.size() < 2: return
 if sides[0].hp <= 0 and sides[1].hp <= 0: winner = 2
 elif sides[0].hp <= 0: winner = 1
 elif sides[1].hp <= 0: winner = 0

func concede(p: int) -> void:
 if winner == -1:
  winner = 1-p
  log_event("%s conceded." % sides[p].faction)

# Returns an action without changing state; UI controls pacing.
func ai_action() -> Dictionary:
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
  "end": return end_turn(1)
 return false
