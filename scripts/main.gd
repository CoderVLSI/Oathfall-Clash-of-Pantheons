extends Control

const STATE = preload("res://scripts/match_state.gd")
const DB = preload("res://scripts/card_database.gd")
const PROFILE = preload("res://scripts/profile.gd")
const CARD = preload("res://ui/card_view.tscn")
const DISPLAY = preload("res://assets/fonts/display.ttf")
const BODY = preload("res://assets/fonts/body.ttf")
const BOLD = preload("res://assets/fonts/body_bold.ttf")
const GOLD = Color("dec18a")
const CREAM = Color("eee7d6")
const TEAL = Color("72d6cc")
var content: Control
var modal: Control
var screen := "menu"
var game = null
var chosen_faction := "Greek"
var profile = PROFILE.new()
var match_stage := 0
var match_deck: Array = []
var match_rival := ""
var match_level := 1
var last_reward := 0
var faction_mode := "duel"
var selection := -1
var attacker := -1
var busy := false
var generation := 0
var inspected_data: Dictionary = {}
var inspection: Control
var notice := ""
var sound_player: AudioStreamPlayer
var sound_bank: Dictionary = {}
var testing := false
var builder_cards: Array = []
var builder_slot := 0
var builder_filter := ""
var builder_name := "My Deck"
var builder_message := ""
var builder_badges: Dictionary = {}
var builder_panel: Control
var fx_layer: Control
var music_player: AudioStreamPlayer
var power_mode := false
var mulligan_marks: Array = []
var unit_positions: Dictionary = {}
var unit_views: Dictionary = {}

func _ready() -> void:
 get_window().min_size = Vector2i(960,540)
 if not testing: load_profile()
 fx_layer = Control.new()
 fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(fx_layer)
 sound_player = AudioStreamPlayer.new()
 add_child(sound_player)
 for key in ["click","summon","attack","win","lose","heal","damage","draw","ward","death","turn","buff","omen","oath"]:
  if ResourceLoader.exists("res://assets/audio/%s.wav" % key): sound_bank[key] = load("res://assets/audio/%s.wav" % key)
 music_player = AudioStreamPlayer.new()
 add_child(music_player)
 if ResourceLoader.exists("res://assets/audio/music.wav"):
  var bed: AudioStreamWAV = load("res://assets/audio/music.wav")
  bed.loop_mode = AudioStreamWAV.LOOP_FORWARD
  bed.loop_end = bed.data.size() / 2
  music_player.stream = bed
  music_player.volume_db = -17
 apply_music()
 show_menu()

func sound(key: String) -> void:
 if profile.muted or not sound_bank.has(key): return
 sound_player.stream = sound_bank[key]
 sound_player.volume_db = -10
 sound_player.play()

func load_profile() -> void:
 profile.load_from("user://profile.cfg")

func save_profile() -> void:
 if testing: return
 profile.save_to("user://profile.cfg")

func clear_screen() -> void:
 if is_instance_valid(modal): modal.queue_free()
 modal = null
 if is_instance_valid(content):
  remove_child(content)
  content.queue_free()
 content = Control.new()
 content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(content)
 if is_instance_valid(fx_layer): move_child(fx_layer,-1)
 inspection = null

func image(parent: Node, path: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
 var node := TextureRect.new()
 if ResourceLoader.exists(path): node.texture = load(path)
 node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 node.position = rect.position
 node.size = rect.size
 node.modulate = tint
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func panel(parent: Node, rect: Rect2, fill: Color = Color("111c29e8"), border: Color = Color("66563c"), radius: int = 10) -> Panel:
 var node := Panel.new()
 node.position = rect.position
 node.size = rect.size
 var style := StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 node.add_theme_stylebox_override("panel",style)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func label(parent: Node, value: String, rect: Rect2, font_size: int = 20, color: Color = CREAM, font: Font = BODY) -> Label:
 var node := Label.new()
 node.position = rect.position
 node.size = rect.size
 node.text = value
 node.add_theme_font_override("font",font)
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func skin_box(fill: Color, border: Color, glow: Color, glow_size: int, border_width: int = 2) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(border_width)
 style.set_corner_radius_all(4)
 style.shadow_color = glow
 style.shadow_size = glow_size
 return style

func button(parent: Node, value: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
 var node := Button.new()
 node.text = value
 node.position = rect.position
 node.size = rect.size
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.add_theme_font_override("font",BOLD)
 node.add_theme_font_size_override("font_size",19)
 node.add_theme_color_override("font_color",Color("1d1608") if primary else Color("e6d3a3"))
 node.add_theme_color_override("font_hover_color",Color("120d04") if primary else Color("ffffff"))
 node.add_theme_color_override("font_pressed_color",Color("120d04") if primary else Color("ffffff"))
 node.add_theme_color_override("font_disabled_color",Color("6f7a85"))
 var gold_glow := Color(1.0,.82,.4,.38)
 var teal_glow := Color(.3,.9,.85,.28)
 if primary:
  node.add_theme_stylebox_override("normal",skin_box(Color("e2bf6c"),Color("fff0b8"),gold_glow,8))
  node.add_theme_stylebox_override("hover",skin_box(Color("f6da8e"),Color("ffffff"),Color(1.0,.86,.45,.6),14))
  node.add_theme_stylebox_override("pressed",skin_box(Color("b8933f"),Color("e8c872"),gold_glow,4))
  node.add_theme_stylebox_override("focus",skin_box(Color("e2bf6c"),Color("ffffff"),gold_glow,8))
 else:
  node.add_theme_stylebox_override("normal",skin_box(Color("0b1726f2"),Color("a08a57"),Color(0,0,0,.35),4))
  node.add_theme_stylebox_override("hover",skin_box(Color("14283d"),Color("f0d49b"),teal_glow,10))
  node.add_theme_stylebox_override("pressed",skin_box(Color("1c3349"),Color("c8ad72"),teal_glow,4))
  node.add_theme_stylebox_override("focus",skin_box(Color("0b1726f2"),Color("f0d49b"),Color(0,0,0,.35),4))
 node.add_theme_stylebox_override("disabled",skin_box(Color("232d38e6"),Color("454d56"),Color(0,0,0,0),0,1))
 node.pressed.connect(func(): sound("click"); action.call())
 parent.add_child(node)
 return node

# --- Ornate skin helpers -------------------------------------------------------------
func diamond(parent: Node, center: Vector2, size: float, color: Color = GOLD) -> Polygon2D:
 var node := Polygon2D.new()
 node.polygon = PackedVector2Array([center + Vector2(0,-size),center + Vector2(size,0),center + Vector2(0,size),center + Vector2(-size,0)])
 node.color = color
 parent.add_child(node)
 return node

func star_polygon(center: Vector2, outer: float, inner: float, points: int) -> PackedVector2Array:
 var pts := PackedVector2Array()
 for i in range(points * 2):
  var radius := outer if i % 2 == 0 else inner
  var angle := TAU * i / float(points * 2) - PI / 2.0
  pts.append(center + Vector2(cos(angle),sin(angle)) * radius)
 return pts

func poly(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
 var node := Polygon2D.new()
 node.polygon = points
 node.color = color
 parent.add_child(node)
 return node

# Dark navy bar with a gold border and diamond studs on the left and right edges.
func ornate_bar(parent: Node, rect: Rect2, studs: bool = true, fill: Color = Color("0a1626ee")) -> Panel:
 var node := panel(parent,rect,fill,Color("b99a57"),5)
 var style: StyleBoxFlat = node.get_theme_stylebox("panel")
 style.set_border_width_all(2)
 style.shadow_color = Color(1.0,.8,.4,.18)
 style.shadow_size = 7
 if studs:
  diamond(parent,rect.position + Vector2(0,rect.size.y / 2.0),8.0,Color("e6c878"))
  diamond(parent,rect.position + Vector2(rect.size.x,rect.size.y / 2.0),8.0,Color("e6c878"))
 return node

# Large side/tray panel: ornate texture frame when available, otherwise a flat gold-edged panel.
func frame(parent: Node, rect: Rect2, modal_frame: bool = false) -> Panel:
 var path := "res://assets/ui/%s.png" % ("modal_frame" if modal_frame else "panel_frame")
 if not ResourceLoader.exists(path): return ornate_bar(parent,rect,false,Color("0b1725f2"))
 var node := Panel.new()
 node.position = rect.position
 node.size = rect.size
 var style := StyleBoxTexture.new()
 style.texture = load(path)
 var margin := 60.0 if modal_frame else 24.0
 style.texture_margin_left = margin
 style.texture_margin_right = margin
 style.texture_margin_top = margin
 style.texture_margin_bottom = margin
 style.modulate_color = Color(1,1,1,.96)
 node.add_theme_stylebox_override("panel",style)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 if not modal_frame:
  # Reinforce the thin textured edge with a glowing gold outline.
  var outline := Panel.new()
  outline.position = rect.position + Vector2(2,2)
  outline.size = rect.size - Vector2(4,4)
  var edge := StyleBoxFlat.new()
  edge.bg_color = Color(0,0,0,0)
  edge.border_color = Color("c9a85ecc")
  edge.set_border_width_all(2)
  edge.set_corner_radius_all(3)
  outline.add_theme_stylebox_override("panel",edge)
  outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
  parent.add_child(outline)
 return node

func lane_slot(parent: Node, rect: Rect2) -> void:
 var node := panel(parent,rect,Color("070f1a66"),Color("c9ad6aaa"),3)
 var style: StyleBoxFlat = node.get_theme_stylebox("panel")
 style.set_border_width_all(1)
 for corner in [Vector2(5,5),Vector2(rect.size.x - 5,5),Vector2(5,rect.size.y - 5),Vector2(rect.size.x - 5,rect.size.y - 5)]:
  diamond(parent,rect.position + corner,3.0,Color("d9bd74"))

func gear_polygon(center: Vector2, radius: float) -> PackedVector2Array:
 var pts := PackedVector2Array()
 var teeth := 8
 for i in range(teeth * 4):
  var angle := TAU * i / float(teeth * 4)
  var phase := i % 4
  var r := radius if phase < 2 else radius * .78
  pts.append(center + Vector2(cos(angle),sin(angle)) * r)
 return pts

func hamburger(parent: Node, pos: Vector2, color: Color = Color("e6d3a3")) -> void:
 for i in range(3):
  var bar := ColorRect.new()
  bar.color = color
  bar.position = pos + Vector2(0,i * 6)
  bar.size = Vector2(18,2)
  bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
  parent.add_child(bar)

# Painted header: emblem, title, round plaque, turn indicator, menu and settings buttons.
func draw_header(round_text: String = "", turn_text: String = "", turn_color: Color = TEAL, in_battle: bool = false) -> void:
 var band := panel(content,Rect2(0,0,1600,76),Color("050c16f7"),Color("6e5c34"),0)
 band.get_theme_stylebox("panel").set_border_width_all(0)
 var line := ColorRect.new()
 line.color = Color("c9a85e")
 line.position = Vector2(0,74)
 line.size = Vector2(1600,2)
 content.add_child(line)
 var glow := ColorRect.new()
 glow.color = Color(.9,.7,.3,.12)
 glow.position = Vector2(0,76)
 glow.size = Vector2(1600,3)
 content.add_child(glow)
 var emblem_center := Vector2(46,38)
 poly(content,star_polygon(emblem_center,34,24,16),Color("d9b865"))
 poly(content,star_polygon(emblem_center,27,20,16),Color("2a1c08"))
 var ring := PackedVector2Array()
 for i in range(32): ring.append(emblem_center + Vector2(cos(TAU * i / 32.0),sin(TAU * i / 32.0)) * 18.0)
 poly(content,ring,Color("0c1626"))
 poly(content,star_polygon(emblem_center,16,7,8),Color("f2d489"))
 var title := label(content,"OATHFALL",Rect2(94,2,330,52),46,Color("f6e4b4"),DISPLAY)
 title.add_theme_color_override("font_outline_color",Color("2a1c08"))
 title.add_theme_constant_override("outline_size",6)
 label(content,"CLASH OF PANTHEONS",Rect2(100,50,300,22),13,Color("c9d3da"),BOLD)
 if round_text != "":
  var plaque := panel(content,Rect2(690,14,220,46),Color("07101bf0"),Color("d2b470"),4)
  plaque.get_theme_stylebox("panel").set_border_width_all(2)
  diamond(content,Vector2(690,37),10,Color("e6c878"))
  diamond(content,Vector2(910,37),10,Color("e6c878"))
  sym_icon(content,"hourglass",Rect2(724,16,42,42),Color.WHITE,"Round")
  var round_label := label(content,round_text,Rect2(774,17,110,40),28,Color("f1deb0"),DISPLAY)
  round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 if turn_text != "":
  var turn := label(content,turn_text,Rect2(980,14,260,46),30,turn_color,DISPLAY)
  turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  turn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  turn.add_theme_color_override("font_outline_color",Color(turn_color.r,turn_color.g,turn_color.b,.45))
  turn.add_theme_constant_override("outline_size",8)
 if in_battle:
  var menu := button(content,"",Rect2(1466,16,64,44),show_pause)
  menu.tooltip_text = "Match menu"
  menu.add_theme_font_size_override("font_size",18)
  hamburger(content,Vector2(1489,31))
  var gear := button(content,"",Rect2(1544,16,44,44),show_settings)
  gear.tooltip_text = "Settings"
  gear.flat = true
  var gear_center := Vector2(1566,38)
  poly(content,gear_polygon(gear_center,17),Color("c9ced4"))
  var hub := PackedVector2Array()
  for i in range(20): hub.append(gear_center + Vector2(cos(TAU * i / 20.0),sin(TAU * i / 20.0)) * 6.5)
  poly(content,hub,Color("0d1824"))

func sym_icon(parent: Node, symbol_name: String, rect: Rect2, tint: Color = Color.WHITE, tip: String = "") -> TextureRect:
 var node := TextureRect.new()
 node.texture = Symbols.tex(symbol_name)
 node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.position = rect.position
 node.size = rect.size
 node.modulate = tint
 if tip != "":
  node.tooltip_text = tip
  node.mouse_filter = Control.MOUSE_FILTER_STOP
 else:
  node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node
func icon(parent: Node, cell: int, rect: Rect2) -> void:
 var atlas := AtlasTexture.new()
 var texture: Texture2D = load("res://assets/ui/icons.png")
 atlas.atlas = texture
 atlas.region = Rect2((cell%3)*texture.get_width()/3.0,(cell/3)*texture.get_height()/2.0,texture.get_width()/3.0,texture.get_height()/2.0)
 var node := TextureRect.new()
 node.texture = atlas
 node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.position = rect.position
 node.size = rect.size
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)

func show_menu() -> void:
 generation += 1
 busy = false
 screen = "menu"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900))
 panel(content,Rect2(0,0,650,900),Color("07101bdc"),Color.TRANSPARENT,0)
 label(content,"A MYTHOLOGICAL CARD BATTLE",Rect2(86,95,540,30),15,TEAL,BOLD)
 label(content,"OATHFALL",Rect2(80,135,700,112),83,GOLD,DISPLAY)
 label(content,"CLASH OF PANTHEONS",Rect2(87,252,600,42),28,CREAM,DISPLAY)
 var intro := label(content,"Gods descend. Beasts awaken.\nYour oath decides the fate of the realms.",Rect2(88,312,500,75),23,Color("c0c6ca"))
 intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button(content,"ENTER THE ARENA",Rect2(88,408,350,60),func(): show_factions("duel"),true)
 button(content,"CAMPAIGN",Rect2(88,478,350,52),func(): show_factions("campaign"))
 button(content,"DECK BUILDER",Rect2(88,540,350,52),show_deck_builder)
 button(content,"CARD COLLECTION",Rect2(88,602,350,52),show_collection)
 button(content,"HOW TO PLAY",Rect2(88,664,350,52),show_rules)
 button(content,"SETTINGS",Rect2(88,726,220,48),show_settings)
 button(content,"QUIT",Rect2(322,726,116,48),func(): get_tree().quit())
 var lp: Dictionary = profile.level_progress()
 label(content,"LEVEL %d" % lp.level,Rect2(88,792,200,28),17,GOLD,BOLD)
 panel(content,Rect2(88,824,350,10),Color("1b2733"),Color("4c4430"),4)
 panel(content,Rect2(88,824,350.0*clampf(float(lp.into)/maxf(1.0,float(lp.needed)),0.02,1.0),10),Color("72d6cc"),Color.TRANSPARENT,4)
 label(content,"%d VICTORIES  /  %d MATCHES  ·  %s AI" % [profile.wins,profile.games,profile.DIFFICULTY_NAMES[profile.difficulty]],Rect2(88,842,520,24),14,Color("8997a2"))
 button(content,"PROFILE",Rect2(1380,35,170,44),show_profile)
 label(content,"SEVEN  PANTHEONS",Rect2(1190,767,340,35),24,GOLD,DISPLAY)
 label(content,"FIRST AGE  ·  OFFLINE DUELS",Rect2(1190,810,360,24),14,CREAM)
 label(content,"85 unique cards · Seven 24-card decks · Custom decks",Rect2(1060,849,490,24),14,Color("8997a2")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func show_settings() -> void:
 var body := open_modal("SETTINGS",630,430)
 button(body,"SOUND: OFF" if profile.muted else "SOUND: ON",Rect2(65,115,500,56),func(): profile.muted = not profile.muted; apply_music(); save_profile(); show_settings())
 button(body,"AI DIFFICULTY: %s" % profile.DIFFICULTY_NAMES[profile.difficulty],Rect2(65,190,500,56),func(): profile.difficulty = (profile.difficulty+1)%3; save_profile(); show_settings())
 var note := label(body,"Difficulty applies to quick duels. Campaign stages set their own difficulty.\nEasy plays carelessly, Normal is the classic rival, Hard weighs trades, Ward and lethal.",Rect2(65,270,500,110),17,Color("94a6b4"))
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_profile() -> void:
 var body := open_modal("PLAYER PROFILE",1060,700)
 var lp: Dictionary = profile.level_progress()
 label(body,"LEVEL %d" % lp.level,Rect2(38,95,200,36),28,TEAL,BOLD)
 label(body,"%d / %d XP to next level" % [lp.into,lp.needed],Rect2(38,135,400,28),17,CREAM)
 panel(body,Rect2(38,170,420,12),Color("1b2733"),Color("4c4430"),4)
 panel(body,Rect2(38,170,420.0*clampf(float(lp.into)/maxf(1.0,float(lp.needed)),0.02,1.0),12),Color("72d6cc"),Color.TRANSPARENT,4)
 label(body,"%d victories  ·  %d matches" % [profile.wins,profile.games],Rect2(38,200,420,28),19,CREAM)
 label(body,"PANTHEON RECORD",Rect2(38,250,420,28),15,GOLD,BOLD)
 for i in range(DB.FACTIONS.size()):
  var f: String = DB.FACTIONS[i]
  label(body,"%s" % f.to_upper(),Rect2(38,290+i*46,160,28),17,CREAM)
  label(body,"%d wins" % int(profile.faction_wins.get(f,0)),Rect2(200,290+i*46,110,28),17,TEAL,BOLD)
  label(body,"Campaign %d / %d" % [profile.stage_cleared(f),profile.STAGES],Rect2(310,290+i*46,170,28),17,Color("c0c6ca"))
 label(body,"ACHIEVEMENTS",Rect2(540,95,420,28),15,GOLD,BOLD)
 var achievements: Array = profile.achievements()
 for i in range(achievements.size()):
  var a: Dictionary = achievements[i]
  panel(body,Rect2(540,135+i*88,480,76),Color("142536f0") if a.done else Color("0d1824f0"),GOLD if a.done else Color("4c4430"),8)
  label(body,("✔  " if a.done else "○  ") + a.name,Rect2(558,143+i*88,440,30),20,GOLD if a.done else Color("8997a2"),BOLD)
  label(body,a.text,Rect2(558,175+i*88,440,28),16,CREAM if a.done else Color("6f7d89"))

const FACTION_INFO = {
 "Greek": {"art":"zeus","title":"OLYMPIAN COVENANT","text":"GREEK · Defense & divine power\nHold the line with Cerberus, restore your Sanctum, then summon Poseidon and Zeus."},
 "Norse": {"art":"thor","title":"OATH OF THE NORTH","text":"NORSE · Pressure & fierce beasts\nLead raiders into battle. Unchain Fenrir, then let Thor finish the conflict."},
 "Roman": {"art":"jupiter","title":"LEGION OF THE EAGLE","text":"ROMAN · Discipline & momentum\nGladiators strike first, Mars rallies the legion, and Jupiter hurls thunderbolts."},
 "Egyptian": {"art":"ra","title":"COVENANT OF THE NILE","text":"EGYPTIAN · Curses & renewal\nSphinx guards the gate, mummies curse, Sekhmet feeds on battle, and Ra scorches the field."},
 "Japanese": {"art":"susanoo","title":"WAY OF THE KAMI","text":"JAPANESE · Spirits & swift strikes\nTricksters draw cards, tengu strike fast, Amaterasu empowers, Susanoo rules the storm."},
 "Aztec": {"art":"quetzalcoatl","title":"OATH OF THE FIFTH SUN","text":"AZTEC · Sun power & spirits\nShields guard the faithful, Quetzal spirits return, Tezcatlipoca drains foes, and Quetzalcoatl descends."},
 "Chinese": {"art":"azuredragon","title":"OATH OF THE JADE COURT","text":"CHINESE · Guardians & rebirth\nStone lions guard, the Vermilion Bird returns, Nezha empowers, and the Azure Dragon descends."}
}

func show_factions(mode: String = "duel") -> void:
 faction_mode = mode
 screen = "factions"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900),Color(.5,.5,.55))
 label(content,"CHOOSE YOUR OATH" if mode == "duel" else "CAMPAIGN · CHOOSE YOUR OATH",Rect2(295,30,1010,60),44,GOLD,DISPLAY).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label(content,"Seven pantheons. One battlefield. All cards are unlocked." if mode == "duel" else "Face every rival pantheon in a five-stage ladder.",Rect2(395,92,810,36),20).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 for p in range(DB.FACTIONS.size()):
  var faction: String = DB.FACTIONS[p]
  var info: Dictionary = FACTION_INFO[faction]
  var per_row := 4 if p < 4 else 3
  var column := p if p < 4 else p - 4
  var x := (1600 - per_row*389 + 17) / 2 + column*389
  var y := 150 if p < 4 else 520
  frame(content,Rect2(x,y,372,350))
  image(content,"res://assets/cards/art/%s.png" % info.art,Rect2(x+10,y+12,160,240))
  label(content,info.title,Rect2(x+180,y+14,185,90),20,GOLD,DISPLAY).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var desc := label(content,str(info.text).split("\n")[0],Rect2(x+14,y+258,345,24),15,CREAM)
  desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var power_info: Dictionary = DB.hero_power(faction)
  label(content,"HERO POWER · %d" % power_info.cost,Rect2(x+180,y+178,185,20),12,TEAL,BOLD)
  label(content,power_info.name,Rect2(x+180,y+196,185,24),16,GOLD,BOLD)
  var oath_info: Dictionary = DB.oath(faction)
  label(content,"OATH · " + oath_info.name,Rect2(x+14,y+282,345,22),14,Color("f0d49b"),BOLD)
  var oath_text := label(content,oath_info.text,Rect2(x+14,y+304,345,40),12,Color("b7c3cc"))
  oath_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var power_text := label(content,power_info.text,Rect2(x+180,y+220,185,40),13,Color("b7c3cc"))
  power_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var label_text := "PLAY " + faction.to_upper() if mode == "duel" else "CAMPAIGN  %d / %d" % [profile.stage_cleared(faction),profile.STAGES]
  button(content,label_text,Rect2(x+180,y+120,182,48),(func(): start_match(faction)) if mode == "duel" else (func(): show_campaign(faction)),true)
 button(content,"BACK",Rect2(60,40,150,48),show_menu)

func open_modal(title_text: String, width: int = 1000, height: int = 740) -> Control:
 if is_instance_valid(modal): modal.queue_free()
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0,0,0,.8)
 shade.size = Vector2(1600,900)
 modal.add_child(shade)
 var origin := Vector2((1600-width)/2.0,(900-height)/2.0)
 var body := Control.new()
 body.position = origin
 body.size = Vector2(width,height)
 modal.add_child(body)
 frame(body,Rect2(0,0,width,height),true)
 label(body,title_text,Rect2(35,20,width-140,55),32,GOLD,DISPLAY)
 button(body,"CLOSE",Rect2(width-135,25,105,42),close_modal)
 return body

func close_modal() -> void:
 if is_instance_valid(modal): modal.queue_free()
 modal = null

func show_rules() -> void:
 var body := open_modal("THE RULES OF OATHFALL",1060,760)
 var text := "WIN THE DUEL\nReduce the opposing Sanctum from 25 health to zero, or fulfil your pantheon's Oath. Both starter decks contain 24 cards.\n\nYOUR TURN\nGain one maximum Power (up to 10), refill it, ready your units, and draw one card.\nTap a card in your hand, then SUMMON / CAST in the left panel. Damage spells need a target.\n\nCOMBAT\nTap a ready friendly unit, then an enemy unit or the enemy Sanctum. Both units deal damage\nsimultaneously. Every unit attacks once per turn. New units rest until your next turn.\n\nKEYWORDS\nGUARD — Defeat enemy Guards before attacking other units or the Sanctum.\nRUSH — A newly summoned unit may attack units immediately, but not the Sanctum.\nARRIVAL — An effect happens once when the unit enters the battlefield.\nHERO POWER — Each pantheon has an ability usable once per turn for its Power cost. Press the HERO POWER button, then pick a target if asked.\nOATH — A second way to win. Each pantheon swears its own Oath (shown on the right for both sides). Complete yours and you win at once. Board Oaths are checked at the start of your turn, so the rival can break them.\nOMENS — Every third round an omen shapes both players. It is announced one round ahead and lasts one round.\nWARD — The first damage the unit would take is prevented.\nLIFESTEAL — Damage the unit deals restores your Sanctum.\nDEATHRATTLE — An effect happens when the unit dies.\nDamage spells ignore Guard. Healing never exceeds 25 health. Your board holds 5 units.\n\nOPENING HAND\nBefore your first turn you may swap any of your opening cards once. Swapped cards are replaced from your deck first, then shuffled back in.\n\nRUNNING OUT OF CARDS\nAn empty deck deals increasing fatigue damage each draw. Full hands (9 cards) burn new draws.\n\nCONTROLS\nClick or tap cards to inspect and select them. Use the left panel to confirm a play.\nCancel a selection with Escape or CANCEL. End Turn gives control to the AI.\nThe match menu pauses AI actions. Concede ends the match; rematch starts a fresh duel."
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(38,88)
 scroll.size = Vector2(980,640)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 body.add_child(scroll)
 var node := Label.new()
 node.text = text
 node.custom_minimum_size = Vector2(950,0)
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.add_theme_font_override("font",BODY)
 node.add_theme_font_size_override("font_size",17)
 node.add_theme_color_override("font_color",CREAM)
 scroll.add_child(node)

func show_collection() -> void:
 var body := open_modal("THE FIRST AGE · COLLECTION",1430,810)
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(25,90)
 scroll.size = Vector2(1380,690)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 body.add_child(scroll)
 var grid := GridContainer.new()
 grid.columns = 6
 grid.add_theme_constant_override("h_separation",20)
 grid.add_theme_constant_override("v_separation",20)
 scroll.add_child(grid)
 for id in DB.CARDS:
  var view = CARD.instantiate()
  view.data = DB.card(id)
  view.card_size = Vector2(205,307.5)
  view.mode = "inspect"
  view.tooltip_text = "%s · %s\n%s" % [view.data.faction,view.data.rarity,view.data.text]
  grid.add_child(view)

# stage > 0 starts a campaign duel against that stage's rival; deck_cards overrides the player's starter deck.
func start_match(faction: String, stage: int = 0, deck_cards: Array = []) -> void:
 generation += 1
 close_modal()
 chosen_faction = faction
 match_stage = stage
 match_deck = deck_cards
 match_rival = ""
 match_level = profile.difficulty
 var bonus_hp := 0
 if stage > 0:
  var info: Dictionary = profile.stage_info(faction,stage)
  match_rival = info.rival
  match_level = info.level
  bonus_hp = info.bonus_hp
 game = STATE.new()
 game.ai_level = match_level
 unit_positions.clear()
 unit_views.clear()
 power_mode = false
 game.start(faction,0,match_rival,deck_cards)
 if bonus_hp > 0: game.sides[1].hp += bonus_hp
 game.ai_mulligan()
 match_rival = game.sides[1].faction
 selection = -1
 attacker = -1
 busy = false
 screen = "battle"
 inspected_data = DB.card(game.sides[0].hand[0])
 notice = "Your oath begins. Select a card from your hand."
 render_battle()
 if not testing: show_mulligan()

func show_campaign(faction: String) -> void:
 screen = "campaign"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900),Color(.45,.48,.55))
 label(content,"%s CAMPAIGN" % faction.to_upper(),Rect2(295,30,1010,60),44,GOLD,DISPLAY).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label(content,"Clear each trial to unlock the next. Rivals grow stronger; the final trial grants the rival +5 Sanctum health.",Rect2(195,92,1210,36),19).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 for stage in range(1,profile.STAGES+1):
  var info: Dictionary = profile.stage_info(faction,stage)
  var y := 140+(stage-1)*116
  var unlocked: bool = profile.stage_unlocked(faction,stage)
  var cleared: bool = profile.stage_cleared(faction) >= stage
  ornate_bar(content,Rect2(250,y,1100,104),cleared,Color("0f1c2cf2") if unlocked else Color("0a121ce6"))
  image(content,"res://assets/cards/art/%s.png" % FACTION_INFO[info.rival].art,Rect2(262,y+6,66,92))
  label(content,"STAGE %d · %s" % [stage,info.title.to_upper()],Rect2(350,y+12,640,32),22,GOLD if unlocked else Color("6f7d89"),DISPLAY)
  label(content,"vs %s · %s AI%s" % [FACTION_INFO[info.rival].title,profile.DIFFICULTY_NAMES[info.level],"  ·  +5 rival Sanctum health" if info.bonus_hp > 0 else ""],Rect2(350,y+52,700,30),18,CREAM if unlocked else Color("6f7d89"))
  label(content,"CLEARED" if cleared else ("READY" if unlocked else "LOCKED"),Rect2(350,y+78,200,24),14,TEAL if unlocked else Color("6f7d89"),BOLD)
  var fight := button(content,"FIGHT" if not cleared else "REPLAY",Rect2(1120,y+27,200,50),func(): start_match(faction,stage),true)
  fight.disabled = not unlocked
 button(content,"BACK",Rect2(60,40,150,48),func(): show_factions("campaign"))

func add_card(parent: Node, data: Dictionary, pos: Vector2, dimensions: Vector2, mode: String, idx: int = -1, valid: bool = false):
 var view = CARD.instantiate()
 view.data = data
 view.position = pos
 view.card_size = dimensions
 view.mode = mode
 view.index = idx
 view.playable = valid
 view.selected = (mode == "hand" and selection == idx) or (mode == "board" and data.get("uid",-2) == attacker)
 view.targetable = (mode == "enemy" and target_valid(data.get("uid",-1))) or (mode == "board" and power_mode and game.hero_power_of(0).target == "ally" and game.can_use_power(0,data.get("uid",-1)))
 view.chosen.connect(on_card_chosen)
 view.inspected.connect(func(card): inspect(card.data))
 parent.add_child(view)
 return view

func target_valid(uid: int) -> bool:
 if busy or game == null or game.current != 0: return false
 if power_mode: return uid >= 0 and game.hero_power_of(0).target == "enemy" and game.can_use_power(0,uid)
 if selection >= 0 and selection < game.sides[0].hand.size():
  return DB.card(game.sides[0].hand[selection]).get("effect","") == "damage"
 return attacker >= 0 and game.can_attack(0,attacker,uid)

func battle_background() -> void:
 var left_path := "res://assets/backgrounds/bg_%s.jpg" % game.sides[0].faction.to_lower()
 var right_path := "res://assets/backgrounds/bg_%s.jpg" % game.sides[1].faction.to_lower()
 if not (ResourceLoader.exists(left_path) and ResourceLoader.exists(right_path)):
  image(content,"res://assets/backgrounds/battlefield.png",Rect2(0,0,1600,900))
  return
 # Your pantheon's world on the left, the rival's on the right, blended across the middle.
 image(content,left_path,Rect2(0,0,1600,900))
 var right := image(content,right_path,Rect2(0,0,1600,900))
 var shader := Shader.new()
 shader.code = "shader_type canvas_item;\nvoid fragment() {\n vec4 c = texture(TEXTURE, UV);\n c.a *= smoothstep(0.30, 0.70, UV.x);\n COLOR = c;\n}\n"
 var material := ShaderMaterial.new()
 material.shader = shader
 right.material = material
 var shade := ColorRect.new()
 shade.color = Color(.02,.04,.08,.22)
 shade.size = Vector2(1600,900)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(shade)

func render_battle() -> void:
 if game == null: return
 if game.winner != -1:
  show_result()
  return
 clear_screen()
 screen = "battle"
 battle_background()
 draw_header("%d" % ceili(game.turn/2.0),"YOUR TURN" if game.current == 0 else "RIVAL'S TURN",TEAL if game.current == 0 else Color("edaf8d"),true)
 var player: Dictionary = game.sides[0]
 var enemy: Dictionary = game.sides[1]
 ornate_bar(content,Rect2(250,84,1080,62))
 sym_icon(content,"emblem_" + enemy.faction.to_lower(),Rect2(264,88,54,54),Color.WHITE,"%s pantheon" % enemy.faction)
 icon(content,2,Rect2(326,92,44,44))
 var enemy_button := button(content,"%d / 25" % enemy.hp,Rect2(378,88,180,43),func(): choose_enemy(-1))
 enemy_button.tooltip_text = "%s Sanctum: tap to attack it." % enemy.faction
 enemy_button.add_theme_font_size_override("font_size",24)
 if target_valid(-1): enemy_button.add_theme_color_override("font_color",TEAL)
 icon(content,0,Rect2(685,89,40,40))
 label(content,"%d / %d" % [enemy.power,enemy.max_power],Rect2(731,97,120,29),19,TEAL,BOLD)
 var hidden_count: int = enemy.hand.size()
 for i in range(mini(hidden_count,7)):
  image(content,"res://assets/cards/card_back.png",Rect2(884+i*34,85,32,48))
 sym_icon(content,"hand",Rect2(1126,90,46,46),Color.WHITE,"Rival's hand")
 label(content,str(hidden_count),Rect2(1178,96,70,36),26,Color("c3ced8"),BOLD)
 for side in range(2):
  var units: Array = game.sides[side].board
  var row_y := 454 if side==0 else 170
  for slot in range(5):
   lane_slot(content,Rect2(389+slot*173,row_y,150,211))
  var start_x := 790.0 - (units.size()*165.0-15.0)/2.0
  for i in range(units.size()):
   var unit_view = add_card(content,units[i],Vector2(start_x+i*165,row_y-7),Vector2(150,225),"board" if side==0 else "enemy",-1,side==0 and units[i].ready and game.current==0 and not busy)
   unit_positions[units[i].uid] = Vector2(start_x+i*165+75,row_y+105)
   unit_views[units[i].uid] = unit_view
 if player.board.is_empty(): label(content,"Summon your first ally from your hand.",Rect2(389,540,860,50),21,Color("b4c0cc")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 if enemy.board.is_empty(): label(content,"The rival's field is empty.",Rect2(389,258,860,50),21,Color("9fb0c0")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 ornate_bar(content,Rect2(252,684,1078,214),true,Color("08121fe0"))
 var hand_size: int = player.hand.size()
 var step := minf(147.0,1030.0/maxi(hand_size,1))
 var hand_x := 790.0-(step*maxi(hand_size-1,0)+140)/2.0
 for i in range(hand_size):
  add_card(content,DB.card(player.hand[i]),Vector2(hand_x+i*step,686),Vector2(140,210),"hand",i,game.can_play(0,i) and not busy)
 render_inspector()
 frame(content,Rect2(1346,84,233,804))
 icon(content,0,Rect2(1369,91,42,42))
 label(content,"%d / %d" % [player.power,player.max_power],Rect2(1417,93,140,39),32,TEAL,BOLD)
 icon(content,2,Rect2(1369,174,40,40))
 label(content,"%d / 25" % player.hp,Rect2(1417,174,140,38),32,CREAM,BOLD)
 icon(content,5,Rect2(1368,254,38,38))
 label(content,str(player.deck.size()),Rect2(1412,256,56,32),24,CREAM,BOLD)
 sym_icon(content,"hand",Rect2(1476,252,38,38),Color.WHITE,"Cards in your hand")
 label(content,str(player.hand.size()),Rect2(1518,256,50,32),24,CREAM,BOLD)
 var end := button(content,"END TURN" if not busy else "RIVAL THINKING…",Rect2(1366,322,193,60),end_player_turn,true)
 end.disabled = busy or game.current!=0
 var cancel_button := button(content,"×",Rect2(1366,394,193,40),cancel_selection)
 cancel_button.add_theme_font_size_override("font_size",32)
 cancel_button.tooltip_text = "Cancel selection"
 cancel_button.disabled = busy
 var hero: Dictionary = game.hero_power_of(0)
 var hero_ready: bool = game.current == 0 and not busy and ((game.can_use_power(0)) if hero.target == "none" else (not game.power_targets(0).is_empty()))
 var hero_button := button(content,"",Rect2(1366,444,193,56),hero_power_pressed)
 sym_icon(hero_button,"emblem_" + game.sides[0].faction.to_lower(),Rect2(12,6,44,44))
 icon(hero_button,0,Rect2(112,12,32,32))
 label(hero_button,str(game.power_cost(0)),Rect2(150,8,34,40),28,TEAL,BOLD)
 hero_button.disabled = not hero_ready and not power_mode
 hero_button.tooltip_text = "%s (%d Power)\n%s" % [hero.name,game.power_cost(0),hero.text]
 if hero_button.disabled and not power_mode: hero_button.modulate = Color(1,1,1,.55)
 hero_button.add_theme_font_size_override("font_size",15)
 if power_mode: hero_button.add_theme_color_override("font_color",TEAL)
 for i in range(mini(game.history.size(),1)):
  var entry := label(content,game.history[i],Rect2(1368,512,191,60),13,Color("bac4cc"))
  entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 ornate_bar(content,Rect2(273,391,1035,32),true,Color("070f1af0"))
 var hint := label(content,notice,Rect2(289,393,1000,27),16,TEAL if attacker>=0 or selection>=0 else CREAM)
 hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 draw_oath_box(0,668.0)
 draw_oath_box(1,772.0)
 draw_omen_plaque()
 play_fx()

func render_inspector() -> void:
 if is_instance_valid(inspection):
  content.remove_child(inspection)
  inspection.queue_free()
 inspection = Control.new()
 content.add_child(inspection)
 frame(inspection,Rect2(17,84,215,804))
 if inspected_data.is_empty(): return
 add_card(inspection,inspected_data,Vector2(33,141),Vector2(183,274.5),"inspect")
 sym_icon(inspection,"emblem_" + str(inspected_data.faction).to_lower(),Rect2(34,430,36,36),Color.WHITE,str(inspected_data.faction))
 sym_icon(inspection,str(inspected_data.category).to_lower(),Rect2(80,430,36,36),Color.WHITE,str(inspected_data.category))
 sym_icon(inspection,str(inspected_data.rarity).to_lower(),Rect2(126,430,36,36),Color.WHITE,str(inspected_data.rarity))
 var desc := label(inspection,inspected_data.text,Rect2(35,482,178,136),18)
 desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 if selection>=0 and selection<game.sides[0].hand.size():
  var c := DB.card(game.sides[0].hand[selection])
  if c.get("effect","") == "damage":
   var tip := label(inspection,"Tap an enemy unit or the rival Sanctum to cast.",Rect2(35,647,178,110),17,TEAL)
   tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  else:
   var play := button(inspection,"CAST" if c.category=="Spell" else "SUMMON",Rect2(35,650,179,53),play_selected,true)
   play.disabled = not game.can_play(0,selection) or busy

func inspect(data: Dictionary) -> void:
 if screen != "battle" or game == null: return
 if selection >= 0 or attacker >= 0: return
 inspected_data = data.duplicate(true)
 if not content.is_queued_for_deletion(): render_inspector()

func on_card_chosen(view) -> void:
 if busy or game.current!=0 or game.winner!=-1 or is_instance_valid(modal): return
 inspected_data = view.data.duplicate(true)
 if power_mode:
  if (view.mode == "board" and game.hero_power_of(0).target == "ally") or (view.mode == "enemy" and game.hero_power_of(0).target == "enemy"): use_hero_power(view.data.uid)
  else: notice = "Choose a valid target for %s, or press CANCEL." % game.hero_power_of(0).name; render_battle()
  return
 if view.mode == "hand":
  selection = view.index
  attacker = -1
  var c := DB.card(game.sides[0].hand[selection])
  if not game.can_play(0,selection):
   notice = "Your field is full." if c.category!="Spell" and game.sides[0].board.size()>=5 else "Not enough Power. This card costs %d." % c.cost
  else: notice = "Choose an enemy target." if c.get("effect","")=="damage" else "Confirm %s with the %s button." % [c.name,"CAST" if c.category=="Spell" else "SUMMON"]
  render_battle()
 elif view.mode == "board":
  selection = -1
  if not view.data.ready:
   attacker = -1
   notice = "This unit is resting or has already attacked."
  else:
   attacker = view.data.uid
   notice = "Choose an enemy unit or the rival Sanctum. Guards must be defeated first."
  render_battle()
 elif view.mode == "enemy": choose_enemy(view.data.uid)

func play_selected() -> void:
 if busy or selection<0: return
 if game.play_card(0,selection):
  selection = -1
  sound("summon")
  notice = game.history[0]
  render_battle()

func choose_enemy(uid: int) -> void:
 if busy or game.current != 0 or is_instance_valid(modal): return
 var acted := false
 if selection>=0 and selection<game.sides[0].hand.size():
  var c := DB.card(game.sides[0].hand[selection])
  if c.get("effect","")=="damage": acted = game.play_card(0,selection,uid)
 elif attacker>=0: acted = game.attack(0,attacker,uid)
 if acted:
  selection = -1
  attacker = -1
  notice = game.history[0]
  sound("attack")
 else: notice = "Select a ready ally or damage spell. Enemy Guards protect other targets."
 render_battle()

func use_hero_power(uid: int = -1) -> void:
 if busy or game.current != 0 or is_instance_valid(modal): return
 if game.use_power(0,uid):
  power_mode = false
  selection = -1
  attacker = -1
  sound("buff")
  notice = game.history[0]
 else: notice = "That is not a valid target for %s." % game.hero_power_of(0).name
 render_battle()

func hero_power_pressed() -> void:
 if busy or game.current != 0 or is_instance_valid(modal): return
 var power: Dictionary = game.hero_power_of(0)
 if power.target == "none":
  use_hero_power(-1)
  return
 if game.power_targets(0).is_empty():
  notice = "%s has no valid target right now." % power.name
 else:
  power_mode = not power_mode
  selection = -1
  attacker = -1
  notice = ("%s: choose %s." % [power.name,"a friendly unit" if power.target == "ally" else "an enemy unit"]) if power_mode else "Selection cleared."
 render_battle()

func cancel_selection() -> void:
 power_mode = false
 selection = -1
 attacker = -1
 notice = "Selection cleared."
 render_battle()

func end_player_turn() -> void:
 if busy or game.current!=0 or is_instance_valid(modal): return
 power_mode = false
 selection = -1
 attacker = -1
 busy = true
 game.end_turn(0)
 notice = "The rival is considering its next move…"
 render_battle()
 run_ai(generation)

func run_ai(token: int) -> void:
 await get_tree().create_timer(.65).timeout
 var safety := 0
 while token==generation and game!=null and game.current==1 and game.winner==-1 and safety<40:
  if is_instance_valid(modal):
   await get_tree().create_timer(.2).timeout
   continue
  var action: Dictionary = game.ai_action()
  if action.is_empty() or not game.execute_ai(action):
   game.end_turn(1)
   break
  safety += 1
  if action.type != "end": sound("attack" if action.type=="attack" else "summon")
  notice = game.history[0]
  render_battle()
  await get_tree().create_timer(.7).timeout
 if token != generation: return
 if game.winner==-1 and game.current==1: game.end_turn(1)
 busy = false
 notice = "Your turn. Select a card to play or a ready ally to attack."
 render_battle()

func show_pause() -> void:
 var body := open_modal("MATCH PAUSED",630,500)
 button(body,"RESUME DUEL",Rect2(65,115,500,58),close_modal,true)
 button(body,"HOW TO PLAY",Rect2(65,190,500,52),show_rules)
 button(body,"SOUND: OFF" if profile.muted else "SOUND: ON",Rect2(65,260,500,52),func(): profile.muted=not profile.muted; apply_music(); save_profile(); show_pause())
 button(body,"CONCEDE MATCH",Rect2(65,330,500,52),func(): close_modal(); game.concede(0); render_battle())
 label(body,"AI actions wait while this menu is open.",Rect2(92,425,490,30),17,Color("94a6b4"))

func show_result() -> void:
 generation += 1
 busy = false
 var first_view: bool = screen != "result"
 if first_view:
  last_reward = profile.record_result(chosen_faction,game.winner==0,match_level,match_stage if game.winner==0 else 0)
  save_profile()
  sound("win" if game.winner==0 else "lose")
 screen = "result"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900),Color(.38,.42,.48))
 frame(content,Rect2(400,135,800,640),true)
 var caption := label(content,result_caption(),Rect2(430,185,740,40),18,TEAL,BOLD)
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var title := "VICTORY" if game.winner==0 else ("DRAW" if game.winner==2 else "DEFEAT")
 var headline := label(content,title,Rect2(430,243,740,100),69,GOLD,DISPLAY)
 headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var versus := "vs %s" % match_rival.to_upper() if match_rival != "" else ""
 var summary := label(content,"%s %s · %d ROUNDS\nYour Sanctum: %d  /  Rival Sanctum: %d" % [chosen_faction.to_upper(),versus,ceili(game.turn/2.0),maxi(0,game.sides[0].hp),maxi(0,game.sides[1].hp)],Rect2(470,366,660,90),23,CREAM)
 summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var lp: Dictionary = profile.level_progress()
 var reward := label(content,"+%d XP  ·  LEVEL %d  (%d / %d)" % [last_reward,lp.level,lp.into,lp.needed],Rect2(470,466,660,34),21,TEAL,BOLD)
 reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var y := 520
 if match_stage > 0 and game.winner == 0 and match_stage < profile.STAGES:
  button(content,"NEXT STAGE",Rect2(550,y,500,58),func(): start_match(chosen_faction,match_stage+1,match_deck),true)
  y += 70
 elif match_stage > 0 and game.winner == 0:
  var done := label(content,"CAMPAIGN COMPLETE",Rect2(470,y+8,660,40),28,GOLD,DISPLAY)
  done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  y += 70
 button(content,"REMATCH" if match_stage == 0 else "RETRY STAGE",Rect2(550,y,500,54),func(): start_match(chosen_faction,match_stage,match_deck),match_stage == 0 or game.winner != 0)
 button(content,"MAIN MENU",Rect2(550,y+66,500,54),show_menu)

func builder_leader() -> String:
 var counts := {}
 for id in builder_cards: counts[DB.CARDS[id].faction] = int(counts.get(DB.CARDS[id].faction,0)) + 1
 var best := "Greek"
 var best_count := -1
 for faction in DB.FACTIONS:
  if int(counts.get(faction,0)) > best_count:
   best_count = int(counts.get(faction,0))
   best = faction
 return best

func builder_add(id: String) -> void:
 if builder_cards.size() >= DB.DECK_SIZE: builder_message = "The deck is full (%d cards). Remove one first." % DB.DECK_SIZE
 elif builder_cards.count(id) >= DB.copy_limit(id): builder_message = "%s allows at most %d copies." % [DB.CARDS[id].name,DB.copy_limit(id)]
 else:
  builder_cards.append(id)
  builder_message = ""
 sound("click")
 builder_refresh()

func builder_remove(id: String) -> void:
 var at := builder_cards.find(id)
 if at >= 0: builder_cards.remove_at(at)
 builder_message = ""
 builder_refresh()

func builder_refresh() -> void:
 for id in builder_badges:
  var copies := builder_cards.count(id)
  builder_badges[id].text = "×%d" % copies
  builder_badges[id].get_parent().visible = copies > 0
 render_builder_panel()

func builder_load_slot(slot: int) -> void:
 builder_slot = slot
 var saved: Dictionary = profile.deck_in_slot(slot)
 if not saved.is_empty():
  builder_cards = saved.cards.duplicate()
  builder_message = "Loaded %s." % saved.name
 else: builder_message = "Slot %d is empty. Build a deck and press SAVE." % (slot + 1)
 builder_refresh()

func show_deck_builder() -> void:
 screen = "builder"
 clear_screen()
 image(content,"res://assets/backgrounds/battlefield.png",Rect2(0,0,1600,900),Color(.6,.6,.65))
 if builder_cards.is_empty():
  var saved: Dictionary = profile.deck_in_slot(builder_slot)
  builder_cards = saved.cards.duplicate() if not saved.is_empty() else DB.deck("Greek")
 panel(content,Rect2(0,0,1600,80),Color("07111bf5"),Color("51442e"),0)
 button(content,"BACK",Rect2(24,16,120,48),show_menu)
 label(content,"DECK BUILDER",Rect2(165,14,330,50),32,GOLD,DISPLAY)
 var tabs: Array = [""] + DB.FACTIONS
 for i in range(tabs.size()):
  var tab: String = tabs[i]
  var tab_button := button(content,"ALL" if tab == "" else tab.to_upper(),Rect2(420+i*128,18,120,44),func(): builder_filter = tab; show_deck_builder())
  tab_button.disabled = builder_filter == tab
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(24,96)
 scroll.size = Vector2(1000,788)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 content.add_child(scroll)
 var grid := GridContainer.new()
 grid.columns = 6
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",16)
 scroll.add_child(grid)
 builder_badges.clear()
 for id in DB.card_ids(builder_filter):
  var view = CARD.instantiate()
  view.data = DB.card(id)
  view.card_size = Vector2(150,225)
  view.mode = "inspect"
  view.tooltip_text = "%s · %s · max %d copies\n%s" % [view.data.name,view.data.rarity,DB.copy_limit(id),view.data.text]
  view.chosen.connect(func(_v): builder_add(id))
  grid.add_child(view)
  var badge := Panel.new()
  badge.position = Vector2(106,4)
  badge.size = Vector2(40,24)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("0b1520f0")
  style.border_color = TEAL
  style.set_border_width_all(1)
  style.set_corner_radius_all(6)
  badge.add_theme_stylebox_override("panel",style)
  badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
  view.add_child(badge)
  var count_label := label(badge,"",Rect2(0,0,40,24),15,TEAL,BOLD)
  count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  builder_badges[id] = count_label
 builder_panel = Control.new()
 content.add_child(builder_panel)
 builder_refresh()

func render_builder_panel() -> void:
 if not is_instance_valid(builder_panel): return
 for child in builder_panel.get_children(): child.queue_free()
 var p := builder_panel
 frame(p,Rect2(1044,96,536,788))
 label(p,"YOUR DECK",Rect2(1064,106,300,30),16,GOLD,BOLD)
 var problem: String = DB.validate_deck(builder_cards)
 label(p,"%d / %d" % [builder_cards.size(),DB.DECK_SIZE],Rect2(1400,104,160,34),24,TEAL if problem == "" else Color("edaf8d"),BOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 var status := label(p,builder_message if builder_message != "" else ("Deck is ready to play." if problem == "" else problem),Rect2(1064,140,500,48),15,Color("c0c6ca") if builder_message == "" and problem == "" else Color("edaf8d"))
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var list := ScrollContainer.new()
 list.position = Vector2(1058,194)
 list.size = Vector2(510,412)
 list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 p.add_child(list)
 var rows := VBoxContainer.new()
 rows.custom_minimum_size = Vector2(496,0)
 rows.add_theme_constant_override("separation",4)
 list.add_child(rows)
 var distinct: Array = []
 for id in builder_cards:
  if not distinct.has(id): distinct.append(id)
 distinct.sort_custom(func(a,b): return DB.CARDS[a].cost < DB.CARDS[b].cost or (DB.CARDS[a].cost == DB.CARDS[b].cost and DB.CARDS[a].name < DB.CARDS[b].name))
 for id in distinct:
  var row := Button.new()
  var c: Dictionary = DB.CARDS[id]
  row.text = "%d   %s   ×%d   · %s" % [c.cost,c.name,builder_cards.count(id),c.faction]
  row.alignment = HORIZONTAL_ALIGNMENT_LEFT
  row.custom_minimum_size = Vector2(496,34)
  row.add_theme_font_override("font",BODY)
  row.add_theme_font_size_override("font_size",16)
  row.add_theme_color_override("font_color",CREAM)
  row.tooltip_text = "Click to remove one copy."
  var style := StyleBoxFlat.new()
  style.bg_color = Color("142536f0")
  style.border_color = Color("5a4e36")
  style.set_border_width_all(1)
  style.set_corner_radius_all(4)
  row.add_theme_stylebox_override("normal",style)
  row.add_theme_stylebox_override("hover",style)
  row.add_theme_stylebox_override("pressed",style)
  row.pressed.connect(func(): builder_remove(id))
  rows.add_child(row)
 for slot in range(profile.DECK_SLOTS):
  var saved: Dictionary = profile.deck_in_slot(slot)
  var slot_button := button(p,"SLOT %d" % (slot + 1) + ("" if saved.is_empty() else " ✔"),Rect2(1064+slot*170,620,160,44),func(): builder_load_slot(slot))
  slot_button.disabled = slot == builder_slot
 button(p,"SAVE TO SLOT %d" % (builder_slot + 1),Rect2(1064,676,240,44),builder_save)
 button(p,"CLEAR DECK",Rect2(1324,676,240,44),func(): builder_cards = []; builder_message = ""; builder_refresh())
 label(p,"FILL FROM STARTER DECK",Rect2(1064,728,400,22),13,Color("8997a2"),BOLD)
 for i in range(DB.FACTIONS.size()):
  var faction: String = DB.FACTIONS[i]
  button(p,faction.substr(0,3).to_upper(),Rect2(1064+i*71,752,66,36),func(): builder_cards = DB.deck(faction); builder_message = "Loaded the %s starter deck." % faction; builder_refresh())
 var play := button(p,"PLAY WITH THIS DECK",Rect2(1064,800,500,56),builder_play,true)
 play.disabled = problem != ""

func builder_save() -> void:
 if profile.save_deck(builder_slot,"%s deck" % builder_leader(),builder_cards):
  save_profile()
  builder_message = "Saved to slot %d." % (builder_slot + 1)
 else: builder_message = "Only a complete, legal deck can be saved."
 builder_refresh()

func builder_play() -> void:
 if DB.validate_deck(builder_cards) != "": return
 start_match(builder_leader(),0,builder_cards.duplicate())

const SANCTUM_POS = [Vector2(1465,215),Vector2(494,110)]

func fx_position(event: Dictionary) -> Vector2:
 if event.uid >= 0 and unit_positions.has(event.uid): return unit_positions[event.uid]
 return SANCTUM_POS[clampi(event.side,0,1)] if event.side >= 0 else Vector2(800,400)

# Consumes the engine's queued events and plays matching effects on the overlay layer.
func play_fx() -> void:
 if game == null or not is_instance_valid(fx_layer): return
 var events: Array = game.drain_fx()
 var shaken := false
 var delay := 0.0
 for event in events:
  match event.type:
   "damage":
    var pos: Vector2 = fx_position(event)
    if event.uid < 0 and event.side >= 0: pos = SANCTUM_POS[event.side]
    float_text("-%d" % event.amount,pos,Color("ff7a6b"),28 + mini(event.amount*3,30))
    sparks(pos,Color("ff8d5c"),14 + event.amount*3)
    sound("damage")
    if not shaken and (event.amount >= 4 or event.uid < 0):
     shaken = true
     shake_screen(4.0 + minf(event.amount,8))
   "heal":
    var pos: Vector2 = SANCTUM_POS[clampi(event.side,0,1)]
    float_text("+%d" % event.amount,pos,Color("7be3a2"),44)
    sparks(pos,Color("7be3a2"),20)
    sound("heal")
   "death":
    var pos: Vector2 = fx_position(event)
    sparks(pos,Color("c9ccd6"),30)
    sound("death")
    unit_positions.erase(event.uid)
    unit_views.erase(event.uid)
   "ward":
    var pos: Vector2 = fx_position(event)
    float_text("WARD",pos,TEAL,30)
    ring(pos,TEAL)
    sound("ward")
   "buff":
    var pos: Vector2 = fx_position(event)
    float_text("▲",pos + Vector2(0,-30),Color("f4cc79"),34)
    sparks(pos,Color("f4cc79"),10)
    sound("buff")
   "summon":
    if unit_views.has(event.uid) and is_instance_valid(unit_views[event.uid]):
     var view: Control = unit_views[event.uid]
     view.scale = Vector2(.55,.55)
     view.modulate.a = 0.0
     var tween := create_tween().set_parallel(true)
     tween.tween_property(view,"scale",Vector2.ONE,.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
     tween.tween_property(view,"modulate:a",1.0,.2)
     ring(fx_position(event),GOLD)
   "attack":
    var target := int(event.extra)
    var from_pos: Vector2 = fx_position(event)
    var to_pos: Vector2 = SANCTUM_POS[1 - event.side] if target == -1 else (unit_positions[target] if unit_positions.has(target) else from_pos)
    slash(from_pos,to_pos)
    if unit_views.has(event.uid) and is_instance_valid(unit_views[event.uid]):
     var view: Control = unit_views[event.uid]
     var home: Vector2 = view.position
     var tween := create_tween()
     tween.tween_property(view,"position",home + (to_pos - from_pos).normalized() * 36.0,.09)
     tween.tween_property(view,"position",home,.16)
    sound("attack")
   "spell":
    flash_screen(Color("fce4a3") if event.extra != "heal" else Color("7be3a2"))
    sound("summon")
   "omen":
    turn_banner("OMEN · %s" % DB.OMENS[event.extra].name.to_upper(),Color("f4cc79"),delay)
    delay += 1.3
    sound("omen" if sound_bank.has("omen") else "turn")
   "omen_warning":
    turn_banner("OMEN LOOMS · %s" % DB.OMENS[event.extra].name.to_upper(),Color("a9bccb"),delay)
    delay += 1.3
   "oath":
    turn_banner("OATH FULFILLED",Color("f4cc79"),delay)
    flash_screen(Color("f4cc79"))
    sound("oath" if sound_bank.has("oath") else "win")
   "turn":
    if game.turn > 1:
     turn_banner("YOUR TURN" if event.side == 0 else "RIVAL'S TURN",TEAL if event.side == 0 else Color("edaf8d"),delay)
     delay += 1.3
   "power":
    var power_pos: Vector2 = fx_position(event)
    float_text(game.hero_power_of(event.side).name,power_pos + Vector2(0,-40),Color("f4cc79"),24)
    ring(power_pos,Color("f4cc79"))
    flash_screen(Color("f4cc79"))
    sound("buff")
   "draw":
    if event.side == 0: sound("draw")
 return

func float_text(value: String, pos: Vector2, color: Color, size: int = 36) -> void:
 var node := label(fx_layer,value,Rect2(pos.x-70,pos.y-30,140,60),size,color,BOLD)
 node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 node.add_theme_color_override("font_outline_color",Color(0,0,0,.9))
 node.add_theme_constant_override("outline_size",6)
 node.pivot_offset = Vector2(70,30)
 node.scale = Vector2(.4,.4)
 var tween := create_tween().set_parallel(true)
 tween.tween_property(node,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_property(node,"position:y",node.position.y - 80.0,1.0).set_ease(Tween.EASE_OUT)
 tween.tween_property(node,"modulate:a",0.0,.45).set_delay(.55)
 tween.chain().tween_callback(node.queue_free)

func sparks(pos: Vector2, color: Color, amount: int = 16) -> void:
 var burst := CPUParticles2D.new()
 burst.position = pos
 burst.one_shot = true
 burst.emitting = true
 burst.amount = maxi(amount,4)
 burst.lifetime = .65
 burst.explosiveness = 1.0
 burst.direction = Vector2(0,-1)
 burst.spread = 180.0
 burst.initial_velocity_min = 90.0
 burst.initial_velocity_max = 260.0
 burst.gravity = Vector2(0,380)
 burst.scale_amount_min = 2.5
 burst.scale_amount_max = 6.0
 burst.color = color
 fx_layer.add_child(burst)
 get_tree().create_timer(1.0).timeout.connect(burst.queue_free)

func ring(pos: Vector2, color: Color) -> void:
 var node := Panel.new()
 node.position = pos - Vector2(20,20)
 node.size = Vector2(40,40)
 node.pivot_offset = Vector2(20,20)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(color.r,color.g,color.b,.0)
 style.border_color = color
 style.set_border_width_all(4)
 style.set_corner_radius_all(20)
 node.add_theme_stylebox_override("panel",style)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 fx_layer.add_child(node)
 var tween := create_tween().set_parallel(true)
 tween.tween_property(node,"scale",Vector2(4.5,4.5),.45).set_ease(Tween.EASE_OUT)
 tween.tween_property(node,"modulate:a",0.0,.45)
 tween.chain().tween_callback(node.queue_free)

func slash(from_pos: Vector2, to_pos: Vector2) -> void:
 var line := Line2D.new()
 line.points = PackedVector2Array([from_pos,from_pos.lerp(to_pos,.5),to_pos])
 line.width = 10.0
 line.default_color = Color("fce4a3")
 line.begin_cap_mode = Line2D.LINE_CAP_ROUND
 line.end_cap_mode = Line2D.LINE_CAP_ROUND
 fx_layer.add_child(line)
 var tween := create_tween().set_parallel(true)
 tween.tween_property(line,"width",1.0,.28)
 tween.tween_property(line,"modulate:a",0.0,.28)
 tween.chain().tween_callback(line.queue_free)

func flash_screen(color: Color) -> void:
 var node := ColorRect.new()
 node.color = Color(color.r,color.g,color.b,.0)
 node.size = Vector2(1600,900)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 fx_layer.add_child(node)
 var tween := create_tween()
 tween.tween_property(node,"color:a",.22,.08)
 tween.tween_property(node,"color:a",0.0,.3)
 tween.tween_callback(node.queue_free)

func shake_screen(strength: float) -> void:
 if not is_instance_valid(content): return
 var target := content
 var tween := create_tween()
 for i in range(6):
  var falloff := 1.0 - i / 6.0
  tween.tween_property(target,"position",Vector2(randf_range(-1,1),randf_range(-1,1)) * strength * falloff,.03)
 tween.tween_property(target,"position",Vector2.ZERO,.03)

func turn_banner(text: String, color: Color, delay: float = 0.0) -> void:
 var band := ColorRect.new()
 band.color = Color(.03,.07,.11,.82)
 band.position = Vector2(-1600,390)
 band.size = Vector2(1600,110)
 band.mouse_filter = Control.MOUSE_FILTER_IGNORE
 fx_layer.add_child(band)
 var title := label(band,text,Rect2(0,18,1600,74),58,color,DISPLAY)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var tween := create_tween()
 tween.tween_interval(delay)
 tween.tween_property(band,"position:x",0.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tween.tween_interval(.55)
 tween.tween_property(band,"position:x",1600.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
 tween.tween_callback(band.queue_free)

func show_mulligan() -> void:
 if game == null or not game.can_mulligan(0): return
 mulligan_marks = []
 render_mulligan()

func toggle_mulligan(index: int) -> void:
 if mulligan_marks.has(index): mulligan_marks.erase(index)
 else: mulligan_marks.append(index)
 sound("click")
 render_mulligan()

func render_mulligan() -> void:
 var body := open_modal("OPENING HAND · SWAP CARDS",1060,560)
 var hint := label(body,"Tap the cards you want to replace, then confirm. You may swap once per match.",Rect2(38,84,980,32),19,Color("c0c6ca"))
 hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var hand: Array = game.sides[0].hand
 var step := minf(190.0,880.0 / maxi(hand.size(),1))
 var x0 := (1060.0 - (step * maxi(hand.size() - 1,0) + 150.0)) / 2.0
 for i in range(hand.size()):
  var view = CARD.instantiate()
  view.data = DB.card(hand[i])
  view.card_size = Vector2(150,225)
  view.mode = "inspect"
  view.position = Vector2(x0 + i * step,135)
  view.tooltip_text = "%s · cost %d\n%s" % [view.data.name,view.data.cost,view.data.text]
  view.chosen.connect(func(_v): toggle_mulligan(i))
  var marked := mulligan_marks.has(i)
  if marked: view.modulate = Color(1.0,.55,.55,.7)
  body.add_child(view)
  if marked:
   var tag := label(body,"REPLACE",Rect2(x0 + i * step,225,150,40),22,Color("ff9a8a"),BOLD)
   tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   tag.add_theme_color_override("font_outline_color",Color(0,0,0,.9))
   tag.add_theme_constant_override("outline_size",6)
 button(body,"KEEP THIS HAND",Rect2(190,440,320,62),func(): confirm_mulligan(false),mulligan_marks.is_empty())
 var swap := button(body,"SWAP %d CARD%s" % [mulligan_marks.size(),"" if mulligan_marks.size() == 1 else "S"],Rect2(550,440,320,62),func(): confirm_mulligan(true),not mulligan_marks.is_empty())
 swap.disabled = mulligan_marks.is_empty()

func confirm_mulligan(swap: bool) -> void:
 if game == null: return
 game.mulligan(0,mulligan_marks if swap else [])
 mulligan_marks = []
 close_modal()
 if not game.sides[0].hand.is_empty(): inspected_data = DB.card(game.sides[0].hand[0])
 notice = game.history[0] if swap and game.history.size() > 0 else "Your oath begins. Select a card from your hand."
 render_battle()

func result_caption() -> String:
 var oath_name: String = DB.oath(game.sides[game.winner].faction).name if game.winner >= 0 and game.winner < 2 else ""
 match game.win_reason:
  "oath":
   return ("OATH FULFILLED · %s" % oath_name).to_upper() if game.winner == 0 else ("THE RIVAL FULFILLED THEIR OATH · %s" % oath_name).to_upper()
  "concede":
   return "YOU CONCEDED THE DUEL" if game.winner != 0 else "THE RIVAL CONCEDED"
  "sanctum":
   if game.winner == 2: return "BOTH SANCTUMS FALL"
   return "THE RIVAL'S SANCTUM FALLS" if game.winner == 0 else "YOUR SANCTUM FALLS"
 return "THE OATH IS FULFILLED" if game.winner == 0 else "THE REALMS REMEMBER"

# Progress tracker for a side's Oath, the second path to victory.
func draw_oath_box(side: int, y: float) -> void:
 var oath: Dictionary = DB.oath(game.sides[side].faction)
 var progress: int = game.oath_progress(side)
 var goal: int = oath.goal
 var mine := side == 0
 ornate_bar(content,Rect2(1362,y,201,92),false,Color("0a1626f2"))
 sym_icon(content,"oath",Rect2(1372,y+8,34,34))
 var oath_name := label(content,oath.name,Rect2(1410,y+4,112,40),13,GOLD,BOLD)
 oath_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 oath_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 sym_icon(content,"emblem_" + game.sides[side].faction.to_lower(),Rect2(1524,y+8,32,32))
 panel(content,Rect2(1374,y+56,126,12),Color("1b2733"),Color("4c4430"),4)
 var ratio := clampf(float(progress) / float(goal),0.0,1.0)
 if ratio > 0.0: panel(content,Rect2(1374,y+56,maxf(126.0 * ratio,6.0),12),Color("72d6cc") if mine else Color("e59b7c"),Color.TRANSPARENT,4)
 label(content,"%d / %d" % [mini(progress,goal),goal],Rect2(1506,y+50,52,24),16,CREAM,BOLD)
 var tip := Control.new()
 tip.position = Vector2(1362,y)
 tip.size = Vector2(201,92)
 tip.tooltip_text = "%s%s\n%s" % ["Your oath: " if mine else "Rival's oath: ",oath.name,oath.text if mine else str(oath.text).replace("your","their")]
 content.add_child(tip)
func draw_omen_plaque() -> void:
 var omen_id: String = game.omen if game.omen != "" else game.pending_omen
 if omen_id == "": return
 var looming: bool = game.omen == ""
 var info: Dictionary = DB.OMENS[omen_id]
 var color := Color("a9bccb") if looming else Color("f4cc79")
 var plaque := ornate_bar(content,Rect2(620,148,360,24),true,Color("0a1626f2"))
 var x := 660.0
 if looming:
  sym_icon(content,"hourglass",Rect2(x,149,22,22),color)
  x += 30.0
 sym_icon(content,"omen",Rect2(x,148,26,26),color)
 var name_label := label(content,str(info.name).to_upper(),Rect2(x + 32.0,148,220,24),14,color,BOLD)
 name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 var tip := Control.new()
 tip.position = plaque.position
 tip.size = plaque.size
 tip.tooltip_text = "%s%s: %s" % ["Next round: " if looming else "Omen: ",info.name,info.text]
 content.add_child(tip)
func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if is_instance_valid(modal): close_modal()
  elif screen=="battle":
   if selection>=0 or attacker>=0: cancel_selection()
   else: show_pause()
  elif screen=="factions" or screen=="builder": show_menu()
  elif screen=="campaign": show_factions("campaign")

func apply_music() -> void:
 if not is_instance_valid(music_player) or music_player.stream == null: return
 if profile.muted or testing: music_player.stop()
 elif not music_player.playing: music_player.play()
