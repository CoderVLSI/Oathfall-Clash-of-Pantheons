extends SceneTree

func _initialize() -> void:
 call_deferred("capture")

func snap(path: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)

func capture() -> void:
 root.size=Vector2i(1600,900)
 var app=load("res://main.tscn").instantiate()
 app.testing=true
 root.add_child(app)
 await snap("res://qa/menu.png")
 app.show_factions()
 await snap("res://qa/factions.png")
 app.show_campaign("Japanese")
 await snap("res://qa/campaign.png")
 app.show_deck_builder()
 await snap("res://qa/builder.png")
 # Japanese (you) versus Egyptian (rival), as in the reference screenshots.
 app.start_match("Japanese",4)
 app.show_mulligan()
 await snap("res://qa/mulligan.png")
 app.close_modal()
 app.game.sides[0].power=1
 app.game.sides[0].max_power=1
 app.inspected_data=app.game.sides[0].hand[0] if false else load("res://scripts/card_database.gd").card("kitsune")
 app.selection=-1
 app.render_battle()
 await snap("res://qa/battle.png")
 app.game.sides[0].max_power=10
 app.game.sides[0].power=10
 app.game.sides[0].hand=["ashigaru","oni","tengu","amaterasu","kusanagi","sake"]
 app.game.play_card(0,0)
 app.game.play_card(0,0)
 app.game.sides[1].hand=["medjay","sphinx"]
 app.game.current=1
 app.game.sides[1].power=10
 app.game.play_card(1,0)
 app.game.play_card(1,0)
 app.game.current=0
 app.game.sides[0].hand=["ashigaru","oni","tengu","amaterasu","kusanagi","sake"]
 app.inspected_data=load("res://scripts/card_database.gd").card("oni")
 app.selection=1
 app.game.omen = "tempest"
 app.game.omen_turns = 2
 app.game.sides[0].board.append({"uid":901,"name":"God","category":"God","attack":3,"hp":4,"health":4,"ready":true,"fresh":false,"cost":4,"rarity":"Legendary","faction":"Japanese","text":"t","art":"amaterasu"})
 app.render_battle()
 await snap("res://qa/battle_board.png")
 app.show_pause()
 await snap("res://qa/pause.png")
 app.close_modal()
 app.show_rules()
 await snap("res://qa/rules.png")
 app.close_modal()
 app.selection=4
 app.game.sides[1].hp=3
 app.choose_enemy(-1)
 await snap("res://qa/victory.png")
 print("Screenshots saved.")
 quit()
