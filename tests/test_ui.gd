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
   var symbols: Control=card.get_node("Symbols")
   var name_label: Label=card.get_node("CardName")
   verify(symbols.position.x+symbols.size.x<=dimensions.x,"Card symbols stay within frame: "+card_id)
   verify(card.symbols_fit,"Card symbols fit on the parchment: "+card_id)
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
 # Hero power flow in the battle UI.
 app.start_match("Greek")
 await process_frame
 app.game.sides[0].power=10
 app.game.sides[0].board=[{"uid":501,"name":"Ally","attack":2,"hp":3,"health":3,"ready":true,"fresh":false,"cost":1,"category":"Mortal","rarity":"Common","faction":"Greek","text":"t","art":"hoplite"}]
 app.render_battle()
 await process_frame
 app.hero_power_pressed()
 verify(app.power_mode,"Targeted hero power enters targeting mode")
 app.use_hero_power(501)
 await process_frame
 verify(not app.power_mode and app.game.sides[0].board[0].get("ward",false) and app.game.sides[0].power==7,"Hero power applies Ward through the UI")
 app.hero_power_pressed()
 verify(not app.power_mode,"Used hero power cannot be reactivated")
 app.start_match("Chinese")
 await process_frame
 var hand_before: int=app.game.sides[0].hand.size()
 app.game.sides[0].power=10
 app.hero_power_pressed()
 await process_frame
 verify(app.game.sides[0].hand.size()==hand_before+1 and not app.power_mode,"Targetless hero power fires immediately")
 # Opening-hand mulligan screen.
 app.start_match("Norse")
 await process_frame
 app.show_mulligan()
 await process_frame
 verify(is_instance_valid(app.modal) and app.game.can_mulligan(0),"Mulligan screen opens at the start of a match")
 var hand_size: int=app.game.sides[0].hand.size()
 var kept_card: String=app.game.sides[0].hand[hand_size-1]
 app.toggle_mulligan(0)
 await process_frame
 verify(app.mulligan_marks==[0],"Tapping a card marks it for replacement")
 app.toggle_mulligan(0)
 verify(app.mulligan_marks.is_empty(),"Tapping again unmarks it")
 app.toggle_mulligan(0)
 await process_frame
 app.confirm_mulligan(true)
 await process_frame
 verify(not is_instance_valid(app.modal) and app.game.sides[0].mulligan_done and app.game.sides[0].hand.size()==hand_size,"Confirming swaps cards and returns to the battle")
 verify(hand_size<2 or app.game.sides[0].hand[hand_size-2]==kept_card,"Unmarked cards are kept, replacements join at the end")
 verify(app.game.sides[1].mulligan_done,"The rival has already used its mulligan")
 app.show_mulligan()
 verify(not is_instance_valid(app.modal),"Mulligan cannot be repeated")
 # Oath and omen presentation.
 app.start_match("Greek")
 await process_frame
 app.game.sides[0].board=[{"uid":801,"name":"G","attack":2,"hp":3,"health":3,"ready":true,"fresh":false,"cost":1,"category":"God","rarity":"Common","faction":"Greek","text":"t","art":"zeus"}]
 app.game.omen="eclipse"
 app.game.omen_turns=2
 app.render_battle()
 await process_frame
 verify(app.screen=="battle" and app.game.oath_progress(0)==1,"Battle renders with an active omen and oath progress")
 app.game.omen=""
 app.game.pending_omen="tempest"
 app.render_battle()
 await process_frame
 verify(app.screen=="battle","Battle renders while an omen looms")
 app.game.pending_omen=""
 app.game.winner=0
 app.game.win_reason="oath"
 verify(app.result_caption().contains("OATH FULFILLED") and app.result_caption().contains("ASCENSION"),"Oath victory caption names the oath")
 app.game.winner=1
 verify(app.result_caption().contains("RIVAL FULFILLED"),"Oath defeat caption names the rival's oath")
 app.game.win_reason="sanctum"
 verify(app.result_caption().contains("YOUR SANCTUM"),"Sanctum defeat caption")
 app.game.winner=0
 verify(app.result_caption().contains("RIVAL'S SANCTUM"),"Sanctum victory caption")
 app.game.win_reason="concede"
 app.game.winner=1
 verify(app.result_caption().contains("CONCEDED"),"Concede caption")
 app.game.winner=-1
 app.game.win_reason=""
 app.generation += 1
 app.queue_free()
 await process_frame
 print("UI: %d checks passed" % checks)
 quit(0)
