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
 # Ward absorbs exactly one damage instance, from combat or spells.
 m=fixture()
 m.sides[0].hand=["phalanx"]
 m.sides[1].hand=["bolt"]
 m.play_card(0,0)
 var warded: Dictionary=m.sides[0].board[0]
 expect(warded.ward and warded.guard,"Phalanx enters with Ward and Guard")
 m.current=1
 m.sides[1].power=10
 expect(m.play_card(1,0,warded.uid),"Spell can target warded unit")
 expect(warded.hp==3 and not warded.ward,"Ward absorbs first damage entirely")
 m.sides[1].hand=["bolt"]
 m.play_card(1,0,warded.uid)
 expect(m.sides[0].board.is_empty(),"Second hit kills the unit")
 # Ward also blocks combat damage but still lets the warded unit strike.
 m=fixture()
 m.sides[0].board=[{"uid":1,"name":"A","attack":4,"hp":4,"ready":true,"fresh":false}]
 m.sides[1].board=[{"uid":2,"name":"B","attack":2,"hp":3,"ward":true}]
 m.attack(0,1,2)
 expect(m.sides[1].board[0].hp==3 and not m.sides[1].board[0].ward,"Ward prevents combat damage once")
 expect(m.sides[0].board[0].hp==2,"Warded defender still retaliates")
 # Lifesteal heals the owner for damage dealt, to units or the Sanctum, and is capped.
 m=fixture()
 m.sides[0].hp=10
 m.sides[0].board=[{"uid":1,"name":"Reaver","attack":3,"hp":2,"ready":true,"fresh":false,"lifesteal":true}]
 m.sides[1].board=[{"uid":2,"name":"B","attack":1,"hp":5}]
 m.attack(0,1,2)
 expect(m.sides[0].hp==13,"Lifesteal heals on unit damage")
 m.sides[0].board[0].ready=true
 m.sides[1].board.clear()
 m.attack(0,1,-1)
 expect(m.sides[0].hp==16 and m.sides[1].hp==22,"Lifesteal heals on Sanctum damage")
 m.sides[0].hp=24
 m.sides[0].board[0].ready=true
 m.attack(0,1,-1)
 expect(m.sides[0].hp==25,"Lifesteal respects the health cap")
 # Lifesteal on a defender heals its owner and does nothing through Ward.
 m=fixture()
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":5,"ready":true,"fresh":false}]
 m.sides[1].board=[{"uid":2,"name":"Leech","attack":2,"hp":5,"lifesteal":true}]
 m.sides[1].hp=10
 m.attack(0,1,2)
 expect(m.sides[1].hp==12,"Defender lifesteal heals its owner")
 m=fixture()
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":5,"ready":true,"fresh":false,"ward":true}]
 m.sides[1].board=[{"uid":2,"name":"Leech","attack":2,"hp":5,"lifesteal":true}]
 m.sides[1].hp=10
 m.attack(0,1,2)
 expect(m.sides[1].hp==10,"No lifesteal when Ward absorbs the damage")
 # Deathrattles: draw, damage, chains, and simultaneous deaths.
 m=fixture()
 m.sides[0].hand=["hydra"]
 m.sides[0].deck=["hoplite","hoplite","hoplite"]
 m.play_card(0,0)
 m.sides[0].board[0].hp=0
 m.cleanup()
 expect(m.sides[0].board.is_empty() and m.sides[0].hand.size()==2 and m.sides[0].deck.size()==1,"Hydra deathrattle draws two cards")
 m=fixture()
 m.sides[0].board=[{"uid":1,"name":"Garm","attack":4,"hp":0,"deathrattle":"damage","deathrattle_amount":3}]
 m.cleanup()
 expect(m.sides[1].hp==22,"Damage deathrattle hits enemy Sanctum")
 m.sides[1].hp=3
 m.sides[0].board=[{"uid":1,"name":"Garm","attack":4,"hp":0,"deathrattle":"damage","deathrattle_amount":3}]
 m.cleanup()
 expect(m.winner==0,"Deathrattle can win the game")
 m=fixture()
 m.sides[0].board=[{"uid":1,"name":"G0","attack":1,"hp":0,"deathrattle":"damage","deathrattle_amount":2}]
 m.sides[1].board=[{"uid":2,"name":"G1","attack":1,"hp":0,"deathrattle":"heal","deathrattle_amount":4}]
 m.sides[1].hp=10
 m.cleanup()
 expect(m.sides[1].hp==12 and m.sides[0].hp==25,"Both sides' deathrattles resolve")
 # Arrival draw, arrival buff, and the buff/draw/sweep spells.
 m=fixture()
 m.sides[0].hand=["oracle","prophecy"]
 m.sides[0].deck=["hoplite","hoplite","hoplite","hoplite"]
 m.play_card(0,0)
 expect(m.sides[0].hand.size()==2 and m.sides[0].deck.size()==3,"Arrival draw draws a card")
 m.play_card(0,m.sides[0].hand.find("prophecy"))
 expect(m.sides[0].deck.size()==1,"Draw spell draws its amount")
 m=fixture()
 m.sides[0].hand=["athena","triumph"]
 m.sides[0].board=[{"uid":7,"name":"X","attack":2,"hp":2}]
 m.play_card(0,0)
 var athena: Dictionary=m.sides[0].board[1]
 expect(m.sides[0].board[0].attack==3 and m.sides[0].board[0].hp==3,"Athena buffs other allies")
 expect(athena.attack==3 and athena.hp==4,"Athena does not buff herself")
 m.play_card(0,0)
 expect(m.sides[0].board[0].attack==4 and athena.hp==5,"Buff spell affects every ally")
 m=fixture()
 m.sides[0].hand=["gale"]
 m.sides[1].board=[{"uid":1,"name":"A","attack":1,"hp":2},{"uid":2,"name":"B","attack":1,"hp":3,"ward":true},{"uid":3,"name":"C","attack":1,"hp":5}]
 m.play_card(0,0)
 expect(m.sides[1].board.size()==2 and m.sides[1].board[0].hp==3 and not m.sides[1].board[0].ward and m.sides[1].board[1].hp==3,"Sweep damages all enemies and respects Ward")
 # Presentation events mirror what happened, and draining empties the queue.
 m=fixture()
 m.fx.clear()
 m.sides[0].hand=["hoplite","bolt"]
 m.play_card(0,0)
 var events: Array=m.drain_fx()
 var kinds := []
 for e in events: kinds.append(e.type)
 expect(kinds.has("summon") and m.fx.is_empty(),"Summon emits an event and drain empties the queue")
 m.sides[1].board=[{"uid":77,"name":"Dummy","attack":1,"hp":2,"ward":true}]
 m.play_card(0,0,77)
 events=m.drain_fx()
 kinds=[]
 for e in events: kinds.append(e.type)
 expect(kinds.has("spell") and kinds.has("ward") and not kinds.has("death"),"Ward absorbs a spell and emits a ward event")
 m.sides[0].hand=["bolt"]
 m.play_card(0,0,77)
 events=m.drain_fx()
 var saw_damage := false
 var saw_death := false
 for e in events:
  if e.type=="damage" and e.uid==77 and e.amount==3: saw_damage=true
  if e.type=="death" and e.uid==77: saw_death=true
 expect(saw_damage and saw_death,"Lethal spell emits damage and death events")
 m.sides[0].hand=["aegis"]
 m.sides[0].hp=20
 m.play_card(0,0)
 events=m.drain_fx()
 var healed := 0
 for e in events: if e.type=="heal": healed+=e.amount
 expect(healed==5,"Heal emits the amount actually restored")
 m.sides[0].hp=25
 m.sides[0].hand=["aegis"]
 m.play_card(0,0)
 var overheal := false
 for e in m.drain_fx(): if e.type=="heal": overheal=true
 expect(not overheal,"No heal event at full health")
 # Pantheon Powers: one use per turn, Power cost, valid targets, and per-pantheon effects.
 for faction in DB.FACTIONS:
  var power: Dictionary=DB.hero_power(faction)
  expect(power.cost>=2 and power.cost<=3 and ["none","ally","enemy"].has(power.target),"%s power is well formed" % faction)
 m=power_fixture("Greek")
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3,"ready":true,"fresh":false}]
 expect(m.power_targets(0)==[1],"Greek power targets friendly units")
 expect(not m.use_power(0,99),"Power rejects an unknown target")
 expect(m.use_power(0,1) and m.sides[0].board[0].ward and m.sides[0].power==7,"Greek power grants Ward and spends 3 Power")
 expect(not m.can_use_power(0,1) and m.power_targets(0).is_empty(),"Power is once per turn")
 m.end_turn(0)
 m.end_turn(1)
 expect(m.sides[0].power_used==false and not m.can_use_power(0,1),"Power resets each turn; Ward cannot be stacked")
 m=power_fixture("Greek")
 m.sides[0].power=2
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3}]
 expect(not m.use_power(0,1),"Power needs enough Power")
 m=power_fixture("Greek")
 m.current=1
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3}]
 expect(not m.use_power(0,1),"Power cannot be used on the rival's turn")
 m=power_fixture("Norse")
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3,"ready":true,"fresh":false}]
 m.use_power(0,1)
 expect(m.sides[0].board[0].attack==4,"Norse power adds 2 Attack")
 m.end_turn(0)
 expect(m.sides[0].board[0].attack==2,"Norse bonus ends with the turn")
 m=power_fixture("Roman")
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3,"ready":false,"fresh":false},{"uid":2,"name":"B","attack":2,"hp":3,"ready":true,"fresh":false},{"uid":3,"name":"C","attack":2,"hp":3,"ready":false,"fresh":true}]
 expect(m.power_targets(0)==[1],"Roman power targets only units that already acted")
 m.use_power(0,1)
 expect(m.sides[0].board[0].ready,"Roman power readies a unit")
 m=power_fixture("Egyptian")
 m.sides[0].hp=20
 expect(m.power_targets(0)==[-1] and m.use_power(0),"Egyptian power needs no target")
 expect(m.sides[1].hp==24 and m.sides[0].hp==21,"Egyptian power drains the Sanctum")
 m=power_fixture("Japanese")
 m.sides[1].board=[{"uid":5,"name":"E","attack":1,"hp":1},{"uid":6,"name":"F","attack":1,"hp":3}]
 m.sides[0].board=[{"uid":1,"name":"A","attack":1,"hp":3}]
 expect(not m.can_use_power(0,1),"Japanese power cannot target allies")
 m.use_power(0,5)
 expect(m.sides[1].board.size()==1 and m.sides[1].board[0].uid==6,"Japanese power kills a 1-health unit")
 m=power_fixture("Chinese")
 m.sides[0].hp=20
 m.sides[0].deck=["hoplite","hoplite"]
 m.use_power(0)
 expect(m.sides[0].hand.size()==1 and m.sides[0].hp==21,"Chinese power draws and heals")
 m=power_fixture("Aztec")
 m.sides[0].board=[{"uid":1,"name":"A","attack":2,"hp":3}]
 m.use_power(0,1)
 expect(m.sides[0].board[0].attack==3 and m.sides[0].board[0].hp==4,"Aztec power grants +1/+1")
 # The AI spends spare Power on its hero ability, and the power event is emitted.
 m=power_fixture("Japanese")
 m.current=1
 m.sides[1].faction="Japanese"
 m.sides[1].power=5
 m.sides[1].hand=[]
 m.sides[1].board=[]
 m.sides[0].board=[{"uid":9,"name":"Tgt","attack":2,"hp":1}]
 m.fx.clear()
 var ai_power: Dictionary=m.ai_power_action()
 expect(ai_power.get("type","")=="power" and ai_power.target==9,"AI picks a killable target for Fox-fire")
 expect(m.execute_ai(ai_power) and m.sides[0].board.is_empty(),"AI executes its hero power")
 var saw_power := false
 for e in m.drain_fx(): if e.type=="power": saw_power=true
 expect(saw_power,"Using a power emits a power event")
 # Mulligan: swap chosen opening cards once, only before the first turn passes.
 m=MATCH.new()
 m.start("Greek",11,"Norse")
 var hand_before: Array=m.sides[0].hand.duplicate()
 var deck_size: int=m.sides[0].deck.size()
 expect(m.can_mulligan(0) and m.can_mulligan(1),"Both sides may mulligan at the start")
 expect(m.mulligan(0,[0,1,1,99,-3,"x"])==2,"Mulligan ignores duplicate and invalid indices")
 expect(m.sides[0].hand.size()==hand_before.size() and m.sides[0].deck.size()==deck_size,"Mulligan keeps hand and deck sizes")
 expect(m.sides[0].hand[0]==hand_before[2] or hand_before.size()<3,"Kept cards stay in the hand")
 expect(m.mulligan(0,[0])==-1 and not m.can_mulligan(0),"A side can only mulligan once")
 var all_cards: Array=m.sides[0].hand+m.sides[0].deck
 var before_all: Array=hand_before+m.sides[0].deck.duplicate()
 expect(all_cards.size()==DB.DECK_SIZE,"Mulligan never loses or duplicates cards")
 m=MATCH.new()
 m.start("Greek",12,"Norse")
 expect(m.mulligan(0,[])==0 and not m.can_mulligan(0),"Keeping the hand still uses the mulligan")
 m=MATCH.new()
 m.start("Roman",13,"Aztec")
 m.end_turn(0)
 expect(not m.can_mulligan(1) and m.mulligan(1,[0])==-1,"No mulligan once the first turn has passed")
 m=MATCH.new()
 m.start("Greek",14,"Norse")
 m.sides[1].hand=["zeus","jupiter","hoplite","bolt","thor"]
 m.sides[1].deck=["hoplite","hoplite","hoplite","hoplite","hoplite","hoplite"]
 var swapped: int=m.ai_mulligan()
 var costly := 0
 for id in m.sides[1].hand: if DB.CARDS[id].cost>=5: costly+=1
 expect(swapped==2 and costly==1 and m.sides[1].hand.size()==5,"AI swaps at most two expensive cards")
 expect(m.winner==-1 and m.turn==1,"Mulligan does not advance the match")
 # Every card definition is well formed and every deck is legal.
 for id in DB.CARDS:
  var c=DB.card(id)
  expect(c.cost>=0 and c.cost<=10 and c.has("text") and c.has("rarity"),"Card %s has core fields" % id)
  if c.category=="Spell": expect(["damage","heal","draw","buff","sweep"].has(c.effect),"Spell %s has a known effect" % id)
  else: expect(c.attack>0 and c.health>0,"Unit %s has stats" % id)
 for faction in DB.FACTIONS:
  var ids: Array=DB.deck(faction)
  var unit_count := 0
  for id in ids:
   if DB.CARDS[id].category!="Spell": unit_count+=1
  expect(unit_count>=14 and unit_count<=18,"%s deck has a healthy unit count" % faction)
  var distinct := {}
  for id in ids: distinct[id]=true
  expect(distinct.size()>=12 and distinct.size()<=13,"%s has 12-13 distinct cards" % faction)
  expect(ResourceLoader.exists("res://assets/cards/frames/frame_%s.png" % faction.to_lower()),"%s has a themed card frame" % faction)
  expect(ResourceLoader.exists("res://assets/backgrounds/bg_%s.jpg" % faction.to_lower()),"%s has a battle background" % faction)
  for id in distinct: expect(ResourceLoader.exists("res://assets/cards/art/%s.png" % DB.CARDS[id].art),"%s art exists for %s" % [faction,id])
  expect(ids.size()==24,"%s deck has 24 cards" % faction)
  for id in ids: expect(DB.CARDS[id].faction==faction,"%s deck contains only its own cards" % faction)
 # Simulate both starter decks through full games, using the same AI on each side.
 var results := [0,0,0]
 for seed_index in range(60):
  m=MATCH.new()
  m.start(DB.FACTIONS[seed_index%DB.FACTIONS.size()],seed_index+1)
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
 # Difficulty ordering: a harder AI should beat an easier one over many mirrored matches.
 var hard_wins := 0
 var easy_wins := 0
 for i in range(30):
  var f: String=DB.FACTIONS[i%DB.FACTIONS.size()]
  var w=duel(1000+i,f,[2,0])
  if w==0: hard_wins+=1
  elif w==1: easy_wins+=1
  w=duel(2000+i,f,[0,2])
  if w==1: hard_wins+=1
  elif w==0: easy_wins+=1
 print("AI levels: hard won %d, easy won %d of 60" % [hard_wins,easy_wins])
 expect(hard_wins>easy_wins*2 and hard_wins>=35,"Hard AI clearly beats Easy AI")
 var normal_vs_easy := 0
 for i in range(20):
  var f2: String=DB.FACTIONS[i%DB.FACTIONS.size()]
  if duel(3000+i,f2,[1,0])==0: normal_vs_easy+=1
  if duel(4000+i,f2,[0,1])==1: normal_vs_easy+=1
 expect(normal_vs_easy>=26,"Normal AI beats Easy AI most of the time")
 print("RULES: %d checks, %d failures; 60 completed simulations, results %s" % [checks,failures,str(results)])
 quit(0 if failures==0 else 1)

# Plays a full match with the given AI level for each seat; returns the winner (0, 1, or 2 for a draw).
func duel(seed_value: int, faction: String, levels: Array) -> int:
 var m = MATCH.new()
 m.start(faction,seed_value)
 var iterations := 0
 while m.winner==-1 and iterations<3000 and m.turn<120:
  iterations+=1
  var seat: int=m.current
  m.ai_level=levels[seat]
  if seat==0:
   var tmp=m.sides[0]
   m.sides[0]=m.sides[1]
   m.sides[1]=tmp
   m.current=1
  var action: Dictionary=m.ai_action()
  var acted: bool=m.execute_ai(action)
  expect(acted,"Level %d AI actions are legal" % levels[seat])
  if seat==0:
   var tmp=m.sides[0]
   m.sides[0]=m.sides[1]
   m.sides[1]=tmp
   m.current=1 if action.type=="end" else 0
   if m.winner==0: m.winner=1
   elif m.winner==1: m.winner=0
  if not acted: break
 return m.winner
func power_fixture(faction: String):
 var m = MATCH.new()
 m.start(faction,321,"Norse" if faction != "Norse" else "Greek")
 for s in m.sides:
  s.hand=[]
  s.board=[]
 m.sides[0].power=10
 m.sides[0].max_power=10
 return m
