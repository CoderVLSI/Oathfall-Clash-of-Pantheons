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
 app.start_match("Greek")
 app.game.sides[0].hand=["hoplite","cerberus","poseidon","zeus","bolt","aegis"]
 app.game.sides[0].power=10
 app.game.sides[0].max_power=10
 app.game.play_card(0,0)
 app.game.play_card(0,0)
 app.game.sides[1].hand=["valkyrie","fenrir"]
 app.game.current=1
 app.game.sides[1].power=10
 app.game.play_card(1,0)
 app.game.play_card(1,0)
 app.game.current=0
 app.game.sides[0].hand=["hoplite","cerberus","poseidon","zeus","bolt","aegis"]
 app.game.sides[0].power=10
 app.inspected_data=load("res://scripts/card_database.gd").card("cerberus")
 app.selection=1
 app.render_battle()
 await snap("res://qa/battle.png")
 app.game.sides[1].hp=3
 app.selection=4
 app.choose_enemy(-1)
 await snap("res://qa/victory.png")
 print("Screenshots saved.")
 quit()
