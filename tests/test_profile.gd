extends SceneTree

const PROFILE = preload("res://scripts/profile.gd")
const DB = preload("res://scripts/card_database.gd")
const MATCH = preload("res://scripts/match_state.gd")
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: "+message)

func _initialize() -> void:
 # Deck validation: every starter deck is legal; broken decks are rejected with a reason.
 for f in DB.FACTIONS: expect(DB.validate_deck(DB.deck(f))=="","%s starter deck is legal" % f)
 var deck: Array=DB.deck("Greek")
 expect(DB.validate_deck(deck.slice(0,23))!="","Short deck rejected")
 var bad: Array=deck.duplicate()
 bad[0]="zeus"
 bad[1]="zeus"
 expect(DB.validate_deck(bad).contains("Zeus"),"Mythic copy limit enforced")
 bad=deck.duplicate()
 bad[0]="missing_card"
 expect(DB.validate_deck(bad).contains("Unknown"),"Unknown card rejected")
 expect(DB.card_ids("Roman").size()==12 and DB.card_ids("Greek").size()==13 and DB.card_ids().size()==DB.CARDS.size(),"Card listing filters by pantheon")
 # Mixed-pantheon deck is legal and used by the first seat.
 var mixed: Array=DB.deck("Greek").slice(0,12)+DB.deck("Norse").slice(0,12)
 expect(DB.validate_deck(mixed)=="","Mixed deck is legal")
 var m=MATCH.new()
 m.start("Greek",5,"Roman",mixed)
 var seen := 0
 for id in m.sides[0].deck+m.sides[0].hand: if mixed.has(id): seen+=1
 expect(seen==24 and m.sides[1].faction=="Roman","Custom deck is used for the player and rival keeps its pantheon")
 # Levels and XP.
 var p=PROFILE.new()
 expect(p.level()==1,"New profile is level 1")
 p.xp=100
 expect(p.level()==2,"100 XP reaches level 2")
 p.xp=299
 expect(p.level()==2,"299 XP is still level 2")
 p.xp=300
 expect(p.level()==3,"300 XP reaches level 3")
 var prog=p.level_progress()
 expect(prog.into==0 and prog.needed==300,"Level progress reports into/needed")
 # Results and campaign.
 p=PROFILE.new()
 expect(p.stage_unlocked("Greek",1) and not p.stage_unlocked("Greek",2),"Only the first stage starts unlocked")
 var gained: int=p.record_result("Greek",false,1)
 expect(gained==30 and p.games==1 and p.wins==0,"Loss grants consolation XP")
 gained=p.record_result("Greek",true,2,1)
 expect(gained==100+50+150+50,"Hard stage win grants base plus first-clear XP")
 expect(p.stage_cleared("Greek")==1 and p.stage_unlocked("Greek",2),"Clearing a stage unlocks the next")
 gained=p.record_result("Greek",true,0,1)
 expect(gained==100,"Replaying a cleared stage gives no clear bonus")
 expect(p.stage_cleared("Greek")==1,"Replay does not regress progress")
 gained=p.record_result("Greek",true,0,3)
 expect(p.stage_cleared("Greek")==3,"Higher stage updates progress")
 for f in DB.FACTIONS:
  var info=p.stage_info(f,1)
  expect(info.rival!=f,"Campaign rival differs from player for %s" % f)
  var rivals=p.campaign_rivals(f)
  var unique := {}
  for r in rivals: unique[r]=true
  expect(rivals.size()==6 and unique.size()==6 and not unique.has(f),"%s campaign faces all six other pantheons" % f)
 expect(p.stage_info("Greek",6).bonus_hp==5 and p.stage_info("Greek",1).bonus_hp==0,"Boss stage grants rival bonus health")
 # Decks and achievements.
 expect(not p.save_deck(0,"Bad",DB.deck("Greek").slice(0,5)),"Invalid deck is not saved")
 expect(not p.save_deck(9,"Slot",DB.deck("Greek")),"Out-of-range slot rejected")
 expect(p.save_deck(1,"Gods",DB.deck("Greek")) and p.deck_in_slot(1).name=="Gods","Valid deck is saved")
 var done := 0
 for a in p.achievements(): if a.done: done+=1
 expect(done==2,"Achievements reflect wins, deckbuilder and progress")
 # Persistence round trip.
 var path := "user://test_profile.cfg"
 p.difficulty=2
 p.muted=true
 p.save_to(path)
 var q=PROFILE.new()
 q.load_from(path)
 expect(q.xp==p.xp and q.wins==p.wins and q.difficulty==2 and q.muted,"Profile round-trips")
 expect(q.stage_cleared("Greek")==3 and q.deck_in_slot(1).name=="Gods","Campaign and decks round-trip")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 print("PROFILE: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
