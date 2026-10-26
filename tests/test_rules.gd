extends SceneTree

const MATCH = preload("res://scripts/match_state.gd")
const DB = preload("res://scripts/card_database.gd")
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: "+message)

func fixture():
 var m = MATCH.new()
 m.start("Greek",123)
 m.sides[0].hand = ["hoplite","bolt","aegis","zeus","cerberus"]
 m.sides[0].power = 10
 m.sides[0].max_power = 10
 m.sides[0].board.clear()
 m.sides[1].board.clear()
 return m

func _initialize() -> void:
 var m = fixture()
 expect(m.sides[0].hp==25 and m.sides[1].hp==25,"Sanctums start at 25")
 m.sides[0].power=0
 expect(not m.play_card(0,0),"Cannot overspend Power")
 expect(not m.play_card(1,0),"Cannot act outside turn")
 m.sides[0].power=10
 expect(m.play_card(0,0),"Summon succeeds")
 expect(m.sides[0].power==9 and m.sides[0].board.size()==1,"Summon consumes resource and enters board")
 var uid: int = m.sides[0].board[0].uid
 expect(not m.attack(0,uid,-1),"Summoning sickness blocks attack")
 m.end_turn(0)
 m.end_turn(1)
 expect(m.attack(0,uid,-1),"Ready unit attacks Sanctum")
 expect(m.sides[1].hp==23,"Combat deals attack damage")
 expect(not m.attack(0,uid,-1),"Unit cannot attack twice")
 m=fixture()
 m.sides[1].board=[{"uid":50,"name":"Guard","attack":3,"hp":3,"guard":true}]
 m.play_card(0,0)
 var unit: Dictionary = m.sides[0].board[0]
 unit.ready=true
 unit.fresh=false
 expect(not m.attack(0,unit.uid,-1),"Guard protects Sanctum")
 expect(m.attack(0,unit.uid,50),"Guard can be attacked")
 expect(m.sides[0].board.is_empty() and m.sides[1].board[0].hp==1,"Damage simultaneous and deaths cleaned")
 expect(m.play_card(0,0,-1),"Damage spell bypasses Guard")
 expect(m.sides[1].hp==22,"Spell damages Sanctum")
 m=fixture()
 m.sides[0].hp=24
 expect(m.play_card(0,2),"Heal cast succeeds")
 expect(m.sides[0].hp==25,"Healing capped")
 m=fixture()
 var before: int=m.sides[0].power
 expect(not m.play_card(0,1,999),"Invalid target rejected")
 expect(m.sides[0].power==before and m.sides[0].hand.size()==5,"Invalid target leaves state untouched")
 m.sides[1].board=[{"uid":50,"name":"Test","attack":1,"hp":2}]
 m.play_card(0,3)
 expect(m.sides[1].board.is_empty(),"Zeus arrival clears defeated units")
 m=fixture()
 for i in range(5): m.sides[0].board.append({"uid":i+100,"hp":1})
 expect(not m.play_card(0,0),"Board capacity enforced")
 expect(m.play_card(0,1),"Spells playable with full board")
 m=fixture()
 m.sides[0].deck=[]
 m.draw_card(0)
 m.draw_card(0)
 expect(m.sides[0].hp==22,"Fatigue damage escalates")
 m.sides[0].hp=1
 m.draw_card(0)
 expect(m.winner==1,"Fatigue defeat resolves")
 m=fixture()
 m.sides[1].hp=3
 m.play_card(0,1)
 expect(m.winner==0,"Spell lethal resolves victory")
 expect(not m.end_turn(0),"No turns after victory")
 m=fixture()
 m.sides[0].hp=0
 m.sides[1].hp=0
 m.cleanup()
 expect(m.winner==2,"Simultaneous lethal resolves draw")
 m=fixture()
 m.concede(0)
 expect(m.winner==1,"Concede resolves defeat")
 # Rush may attack units immediately but cannot bypass summoning delay for face.
 m=fixture()
 m.sides[0].hand=["fenrir"]
 m.sides[1].board=[{"uid":99,"name":"Target","attack":1,"hp":2}]
 m.play_card(0,0)
 uid=m.sides[0].board[0].uid
 expect(not m.can_attack(0,uid,-1) and m.can_attack(0,uid,99),"Rush respects unit-only restriction")
 # Simulate both starter decks through full games, using the same AI on each side.
 var results := [0,0,0]
 for seed_index in range(40):
  m=MATCH.new()
  m.start("Greek" if seed_index%2==0 else "Norse",seed_index+1)
  var iterations := 0
  while m.winner==-1 and iterations<2000:
   iterations+=1
   var original_current: int=m.current
   if original_current==0:
    var tmp=m.sides[0]
    m.sides[0]=m.sides[1]
    m.sides[1]=tmp
    m.current=1
   var action: Dictionary=m.ai_action()
   expect(not action.is_empty(),"AI returns an action")
   if action.is_empty(): break
   var acted: bool=m.execute_ai(action)
   expect(acted,"AI actions are legal")
   if original_current==0:
    var tmp=m.sides[0]
    m.sides[0]=m.sides[1]
    m.sides[1]=tmp
    m.current=1 if action.type=="end" else 0
    if m.winner==0: m.winner=1
    elif m.winner==1: m.winner=0
   for side in m.sides:
    expect(side.power>=0 and side.power<=10,"Power invariant")
    expect(side.board.size()<=5 and side.hand.size()<=9,"Zone bounds")
   if m.turn>100: break
  expect(m.winner!=-1,"Every seeded game terminates")
  if m.winner>=0: results[m.winner]+=1
 print("RULES: %d checks, %d failures; 40 completed simulations, results %s" % [checks,failures,str(results)])
 quit(0 if failures==0 else 1)
