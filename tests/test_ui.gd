extends SceneTree

const MAIN = preload("res://main.tscn")
var checks := 0
const DB_ID = preload("res://scripts/card_database.gd")

func verify(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  printerr("UI FAILURE: "+message)
  quit(1)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var app = MAIN.instantiate()
 app.testing = true
 root.add_child(app)
 await process_frame
 for card_id in load("res://scripts/card_database.gd").CARDS:
  for dimensions in [Vector2(140,210),Vector2(183,274.5)]:
   var card=load("res://ui/card_view.tscn").instantiate()
   card.data=load("res://scripts/card_database.gd").card(card_id)
   card.card_size=dimensions
   card.mode="inspect"
   root.add_child(card)
   await process_frame
   var rules: Label=card.get_node("RulesText")
   var name_label: Label=card.get_node("CardName")
   verify(rules.position.x+rules.size.x<=dimensions.x,"Card rules stay within frame: "+card_id)
   verify(rules.get_visible_line_count()>=rules.get_line_count(),"Card rules are fully visible: "+card_id)
   verify(name_label.get_line_count()==1,"Card title stays on one line: "+card_id)
   if card.data.category!="Spell":
    verify(card.get_node("AttackValue").get_visible_line_count()==1,"Attack numeral is visible: "+card_id)
    verify(card.get_node("HealthValue").get_visible_line_count()==1,"Health numeral is visible: "+card_id)
   card.queue_free()
   await process_frame
 verify(app.screen=="menu","Main menu loads")
 app.show_factions()
 await process_frame
 verify(app.screen=="factions","Faction selection loads")
 app.start_match("Greek")
 await process_frame
 verify(app.screen=="battle" and app.game.sides[0].faction=="Greek","Greek match starts")
 app.game.sides[0].hand=["hoplite","bolt"]
 app.game.sides[0].power=10
 app.selection=0
 app.play_selected()
 await process_frame
 verify(app.game.sides[0].board.size()==1,"UI summons unit")
 verify(app.selection==-1,"Selection cleared after play")
 app.game.sides[1].hp=3
 app.selection=0
 app.choose_enemy(-1)
 await process_frame
 verify(app.screen=="result" and app.game.winner==0,"UI resolves victory")
 app.start_match("Norse")
 await process_frame
 verify(app.game.sides[0].faction=="Norse","Norse rematch starts")
 app.show_pause()
 verify(is_instance_valid(app.modal),"Pause opens")
 app.close_modal()
 await process_frame
 app.game.concede(0)
 app.render_battle()
 await process_frame
 verify(app.screen=="result" and app.game.winner==1,"UI resolves defeat")
 app.show_menu()
 app.show_collection()
 await process_frame
 verify(is_instance_valid(app.modal),"Collection opens")
 app.close_modal()
 app.show_rules()
 await process_frame
 verify(is_instance_valid(app.modal),"Rules open")
 app.close_modal()
 app.start_match("Greek")
 app.end_player_turn()
 await create_timer(12).timeout
 verify(app.game.current==0 and not app.busy,"AI completes turn and returns control")
 # Settings, profile, campaign, and deck builder flows.
 app.show_menu()
 app.show_settings()
 await process_frame
 verify(is_instance_valid(app.modal),"Settings open")
 var before: int=app.profile.difficulty
 app.profile.difficulty=(before+1)%3
 app.close_modal()
 app.show_profile()
 await process_frame
 verify(is_instance_valid(app.modal),"Profile opens")
 app.close_modal()
 app.show_factions("campaign")
 await process_frame
 verify(app.screen=="factions" and app.faction_mode=="campaign","Campaign pantheon select loads")
 app.show_campaign("Roman")
 await process_frame
 verify(app.screen=="campaign","Campaign ladder loads")
 app.start_match("Roman",1)
 await process_frame
 verify(app.game.sides[0].faction=="Roman" and app.game.sides[1].faction!="Roman" and app.match_stage==1,"Campaign stage starts with a different rival")
 verify(app.game.ai_level==0,"Stage 1 uses the Easy AI")
 app.game.sides[1].hp=0
 app.game.check_winner()
 app.render_battle()
 await process_frame
 verify(app.screen=="result" and app.profile.stage_cleared("Roman")==1 and app.last_reward>=300,"Campaign victory records progress and XP")
 app.start_match("Roman",6)
 verify(app.game.sides[1].hp==30,"Boss stage grants rival bonus health")
 app.show_deck_builder()
 await process_frame
 verify(app.screen=="builder" and app.builder_cards.size()==24,"Deck builder opens with a full deck")
 app.builder_remove("hoplite")
 verify(app.builder_cards.size()==23 and DB_ID.validate_deck(app.builder_cards)!="","Removing a card makes the deck incomplete")
 app.builder_add("zeus")
 app.builder_add("zeus")
 verify(app.builder_cards.count("zeus")==1,"Copy limit blocks a second Mythic")
 app.builder_cards=DB_ID.deck("Norse")
 app.builder_filter="Roman"
 app.show_deck_builder()
 await process_frame
 verify(app.builder_badges.size()==12,"Pantheon filter shows twelve cards")
 app.builder_filter=""
 app.builder_cards=DB_ID.deck("Japanese")
 app.builder_save()
 verify(app.profile.deck_in_slot(0).cards.size()==24,"Builder saves a legal deck")
 app.builder_play()
 await process_frame
 verify(app.screen=="battle" and app.game.sides[0].faction=="Japanese" and app.match_deck.size()==24,"Custom deck match starts")
 app.generation += 1
 app.queue_free()
 await process_frame
 print("UI: %d checks passed" % checks)
 quit(0)
