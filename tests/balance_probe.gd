extends SceneTree

# Balance probe: AI vs AI across every pantheon pairing; reports how games end, by winning pantheon.
const MATCH = preload("res://scripts/match_state.gd")
const DB = preload("res://scripts/card_database.gd")

func _initialize() -> void:
 var games_per_pair := 4
 var oath_by := {}
 var wins_by := {}
 var turns_total := 0
 var games := 0
 var oath_total := 0
 for fa in DB.FACTIONS:
  for fb in DB.FACTIONS:
   if fa == fb: continue
   for g in range(games_per_pair):
    var m = MATCH.new()
    m.ai_level = 1
    m.start(fa,5000 + games,fb)
    var guard := 0
    while m.winner == -1 and guard < 3000 and m.turn < 120:
     guard += 1
     var seat: int = m.current
     if seat == 0:
      var tmp = m.sides[0]
      m.sides[0] = m.sides[1]
      m.sides[1] = tmp
      m.current = 1
     var action: Dictionary = m.ai_action()
     var acted: bool = m.execute_ai(action)
     if seat == 0:
      var tmp2 = m.sides[0]
      m.sides[0] = m.sides[1]
      m.sides[1] = tmp2
      m.current = 1 if action.type == "end" else 0
      if m.winner == 0: m.winner = 1
      elif m.winner == 1: m.winner = 0
     if not acted: break
    games += 1
    turns_total += m.turn
    if m.winner >= 0 and m.winner < 2:
     var wf: String = m.sides[m.winner].faction
     wins_by[wf] = int(wins_by.get(wf,0)) + 1
     if m.win_reason == "oath":
      oath_by[wf] = int(oath_by.get(wf,0)) + 1
      oath_total += 1
 print("BALANCE games=%d avg_turns=%.1f oath_wins=%d (%.0f%%)" % [games,float(turns_total)/games,oath_total,100.0*oath_total/games])
 for f in DB.FACTIONS: print("  %-9s wins=%2d oath_wins=%2d" % [f,int(wins_by.get(f,0)),int(oath_by.get(f,0))])
 quit()