extends SceneTree

# Renders a row of cards per pantheon to qa/cards_<name>.png for frame calibration.
func _initialize() -> void:
 call_deferred("capture")

func capture() -> void:
 root.size = Vector2i(1600,900)
 var DB = load("res://scripts/card_database.gd")
 var CARD = load("res://ui/card_view.tscn")
 var args := OS.get_cmdline_user_args()
 var faction: String = args[0] if args.size() > 0 else "Greek"
 var bg := ColorRect.new()
 bg.color = Color("0d1520")
 bg.size = Vector2(1600,900)
 root.add_child(bg)
 var ids: Array = DB.card_ids(faction)
 for i in range(mini(ids.size(),12)):
  var view = CARD.instantiate()
  view.data = DB.card(ids[i])
  view.card_size = Vector2(250,375)
  view.mode = "inspect"
  view.position = Vector2(20 + (i % 6) * 262,30 + (i / 6) * 430)
  root.add_child(view)
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://qa/cards_%s.png" % faction.to_lower())
 quit()