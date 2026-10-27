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
 for key in ["click","summon","attack","win","lose","heal","damage","draw","ward","death","turn","buff"]:
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

func button(parent: Node, value: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
 var node := Button.new()
 node.text = value
 node.position = rect.position
 node.size = rect.size
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.add_theme_font_override("font",BOLD)
 node.add_theme_font_size_override("font_size",19)
 node.add_theme_color_override("font_color",Color("17212a") if primary else GOLD)
 node.add_theme_color_override("font_hover_color",Color("101c24") if primary else CREAM)
 for state_name in ["normal","hover","pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = Color("d6b77c") if primary else Color("101d2aee")
  if state_name == "hover": style.bg_color = Color("f0d49b") if primary else Color("25394b")
  if state_name == "pressed": style.bg_color = Color("ab8b58") if primary else Color("3b4a51")
  if state_name == "disabled": style.bg_color = Color("27323b")
  style.border_color = Color("e0c995") if primary else Color("786849")
  style.set_border_width_all(1 if state_name != "focus" else 2)
  style.set_corner_radius_all(5)
  node.add_theme_stylebox_override(state_name,style)
 node.pressed.connect(func(): sound("click"); action.call())
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
  panel(content,Rect2(x,y,372,350))
  image(content,"res://assets/cards/art/%s.png" % info.art,Rect2(x+10,y+12,160,240))
  label(content,info.title,Rect2(x+180,y+14,185,90),20,GOLD,DISPLAY).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var desc := label(content,info.text,Rect2(x+14,y+262,345,70),15,CREAM)
  desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
 panel(body,Rect2(0,0,width,height),Color("101d2bf8"),GOLD)
 label(body,title_text,Rect2(35,20,width-140,55),32,GOLD,DISPLAY)
 button(body,"CLOSE",Rect2(width-135,25,105,42),close_modal)
 return body

func close_modal() -> void:
 if is_instance_valid(modal): modal.queue_free()
 modal = null

func show_rules() -> void:
 var body := open_modal("THE RULES OF OATHFALL",1060,760)
 var text := "WIN THE DUEL\nReduce the opposing Sanctum from 25 health to zero. Both starter decks contain 24 cards.\n\nYOUR TURN\nGain one maximum Power (up to 10), refill it, ready your units, and draw one card.\nTap a card in your hand, then SUMMON / CAST in the left panel. Damage spells need a target.\n\nCOMBAT\nTap a ready friendly unit, then an enemy unit or the enemy Sanctum. Both units deal damage\nsimultaneously. Every unit attacks once per turn. New units rest until your next turn.\n\nKEYWORDS\nGUARD — Defeat enemy Guards before attacking other units or the Sanctum.\nRUSH — A newly summoned unit may attack units immediately, but not the Sanctum.\nARRIVAL — An effect happens once when the unit enters the battlefield.\nWARD — The first damage the unit would take is prevented.\nLIFESTEAL — Damage the unit deals restores your Sanctum.\nDEATHRATTLE — An effect happens when the unit dies.\nDamage spells ignore Guard. Healing never exceeds 25 health. Your board holds 5 units.\n\nRUNNING OUT OF CARDS\nAn empty deck deals increasing fatigue damage each draw. Full hands (9 cards) burn new draws.\n\nCONTROLS\nClick or tap cards to inspect and select them. Use the left panel to confirm a play.\nCancel a selection with Escape or CANCEL. End Turn gives control to the AI.\nThe match menu pauses AI actions. Concede ends the match; rematch starts a fresh duel."
 var node := label(body,text,Rect2(38,93,980,630),20,CREAM)
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
 game.start(faction,0,match_rival,deck_cards)
 if bonus_hp > 0: game.sides[1].hp += bonus_hp
 match_rival = game.sides[1].faction
 selection = -1
 attacker = -1
 busy = false
 screen = "battle"
 inspected_data = DB.card(game.sides[0].hand[0])
 notice = "Your oath begins. Select a card from your hand."
 render_battle()

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
  panel(content,Rect2(250,y,1100,104),Color("0f1c2cee") if unlocked else Color("0a121cdd"),GOLD if cleared else Color("5a4e36"))
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
 view.targetable = mode == "enemy" and target_valid(data.get("uid",-1))
 view.chosen.connect(on_card_chosen)
 view.inspected.connect(func(card): inspect(card.data))
 parent.add_child(view)
 return view

func target_valid(uid: int) -> bool:
 if busy or game == null or game.current != 0: return false
 if selection >= 0 and selection < game.sides[0].hand.size():
  return DB.card(game.sides[0].hand[selection]).get("effect","") == "damage"
 return attacker >= 0 and game.can_attack(0,attacker,uid)

func render_battle() -> void:
 if game == null: return
 if game.winner != -1:
  show_result()
  return
 clear_screen()
 screen = "battle"
 image(content,"res://assets/backgrounds/battlefield.png",Rect2(0,0,1600,900))
 panel(content,Rect2(0,0,1600,63),Color("07111bf5"),Color("51442e"),0)
 label(content,"OATHFALL",Rect2(26,12,250,39),28,GOLD,DISPLAY)
 label(content,"CLASH OF PANTHEONS",Rect2(250,22,320,24),13,Color("a8b7bf"),BOLD)
 button(content,"MATCH MENU",Rect2(1370,12,205,40),show_pause)
 label(content,"ROUND %02d" % ceili(game.turn/2.0),Rect2(640,19,230,28),18,GOLD,BOLD)
 label(content,"YOUR TURN" if game.current == 0 else "RIVAL'S TURN",Rect2(960,18,300,30),20,TEAL if game.current==0 else Color("edaf8d"),BOLD)
 var player: Dictionary = game.sides[0]
 var enemy: Dictionary = game.sides[1]
 panel(content,Rect2(250,77,1080,67),Color("111b27e8"))
 icon(content,2,Rect2(269,86,46,46))
 var enemy_button := button(content,"%s SANCTUM   %d / 25" % [enemy.faction.to_upper(),enemy.hp],Rect2(322,88,345,43),func(): choose_enemy(-1))
 if target_valid(-1): enemy_button.add_theme_color_override("font_color",TEAL)
 icon(content,0,Rect2(685,89,40,40))
 label(content,"%d / %d" % [enemy.power,enemy.max_power],Rect2(731,97,120,29),19,TEAL,BOLD)
 var hidden_count: int = enemy.hand.size()
 for i in range(mini(hidden_count,7)):
  image(content,"res://assets/cards/card_back.png",Rect2(884+i*34,85,32,48))
 label(content,"%d CARDS" % hidden_count,Rect2(1146,100,160,25),14,Color("a4b1bb"))
 label(content,"RIVAL'S FIELD",Rect2(275,152,260,24),13,Color("a8b7bf"),BOLD)
 label(content,"YOUR FIELD",Rect2(275,418,260,24),13,TEAL,BOLD)
 for side in range(2):
  var units: Array = game.sides[side].board
  var row_y := 454 if side==0 else 170
  for slot in range(5):
   panel(content,Rect2(389+slot*173,row_y,150,211),Color("0c15255a"),Color("77705b45"))
  var start_x := 790.0 - (units.size()*165.0-15.0)/2.0
  for i in range(units.size()):
   var unit_view = add_card(content,units[i],Vector2(start_x+i*165,row_y-7),Vector2(150,225),"board" if side==0 else "enemy",-1,side==0 and units[i].ready and game.current==0 and not busy)
   unit_positions[units[i].uid] = Vector2(start_x+i*165+75,row_y+105)
   unit_views[units[i].uid] = unit_view
 if player.board.is_empty(): label(content,"Summon your first ally from your hand.",Rect2(580,530,600,50),21,Color("9ca8b6"))
 if enemy.board.is_empty(): label(content,"The rival's field is empty.",Rect2(650,260,540,50),21,Color("788a9b"))
 panel(content,Rect2(252,681,1078,219),Color("091421d9"),Color("665536"),8)
 var hand_size: int = player.hand.size()
 var step := minf(147.0,1030.0/maxi(hand_size,1))
 var hand_x := 790.0-(step*maxi(hand_size-1,0)+140)/2.0
 for i in range(hand_size):
  add_card(content,DB.card(player.hand[i]),Vector2(hand_x+i*step,686),Vector2(140,210),"hand",i,game.can_play(0,i) and not busy)
 render_inspector()
 panel(content,Rect2(1350,77,225,809),Color("0b1725ee"))
 icon(content,0,Rect2(1369,91,42,42))
 label(content,"POWER",Rect2(1417,91,140,27),14,GOLD,BOLD)
 label(content,"%d / %d" % [player.power,player.max_power],Rect2(1417,119,140,39),29,TEAL,BOLD)
 icon(content,2,Rect2(1369,174,40,40))
 label(content,"YOUR SANCTUM",Rect2(1417,174,150,25),13,GOLD,BOLD)
 label(content,"%d / 25" % player.hp,Rect2(1417,201,140,38),29,CREAM,BOLD)
 icon(content,5,Rect2(1368,254,38,38))
 label(content,"DECK  %d    HAND  %d" % [player.deck.size(),player.hand.size()],Rect2(1411,262,160,30),13,Color("acb9c4"))
 var end := button(content,"END TURN" if not busy else "RIVAL THINKING…",Rect2(1366,322,193,60),end_player_turn,true)
 end.disabled = busy or game.current!=0
 button(content,"CANCEL",Rect2(1366,394,193,40),cancel_selection).disabled = busy
 label(content,"BATTLE CHRONICLE",Rect2(1368,456,205,30),14,GOLD,BOLD)
 for i in range(mini(game.history.size(),7)):
  var entry := label(content,game.history[i],Rect2(1368,500+i*47,191,45),14,Color("bac4cc") if i==0 else Color("8394a3"))
  entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 panel(content,Rect2(273,393,1035,28),Color("0a1924ce"),Color("5f68534a"),4)
 var hint := label(content,notice,Rect2(289,393,1000,27),16,TEAL if attacker>=0 or selection>=0 else CREAM)
 hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 play_fx()

func render_inspector() -> void:
 if is_instance_valid(inspection):
  content.remove_child(inspection)
  inspection.queue_free()
 inspection = Control.new()
 content.add_child(inspection)
 panel(inspection,Rect2(21,77,207,809),Color("0a1724ed"))
 label(inspection,"CARD INSPECTION",Rect2(36,96,190,30),14,GOLD,BOLD)
 if inspected_data.is_empty(): return
 add_card(inspection,inspected_data,Vector2(33,141),Vector2(183,274.5),"inspect")
 label(inspection,inspected_data.faction.to_upper()+" · "+inspected_data.rarity.to_upper(),Rect2(34,435,185,30),12,GOLD,BOLD)
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
 label(inspection,"Tap a card to inspect.\nGold outlines = playable.\nTeal outlines = targets.",Rect2(35,788,180,70),13,Color("8c9eac"))

func inspect(data: Dictionary) -> void:
 if screen != "battle" or game == null: return
 if selection >= 0 or attacker >= 0: return
 inspected_data = data.duplicate(true)
 if not content.is_queued_for_deletion(): render_inspector()

func on_card_chosen(view) -> void:
 if busy or game.current!=0 or game.winner!=-1 or is_instance_valid(modal): return
 inspected_data = view.data.duplicate(true)
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

func cancel_selection() -> void:
 selection = -1
 attacker = -1
 notice = "Selection cleared."
 render_battle()

func end_player_turn() -> void:
 if busy or game.current!=0 or is_instance_valid(modal): return
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
 panel(content,Rect2(400,135,800,640),Color("0b1826f0"),GOLD)
 label(content,"THE OATH IS FULFILLED" if game.winner==0 else "THE REALMS REMEMBER",Rect2(510,185,670,40),18,TEAL,BOLD)
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
  var tab_button := button(content,"ALL" if tab == "" else tab.to_upper(),Rect2(480+i*148,18,138,44),func(): builder_filter = tab; show_deck_builder())
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
 panel(p,Rect2(1044,96,536,788),Color("0b1725f0"))
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
  button(p,faction.substr(0,3).to_upper(),Rect2(1064+i*80,752,74,36),func(): builder_cards = DB.deck(faction); builder_message = "Loaded the %s starter deck." % faction; builder_refresh())
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
   "turn":
    if game.turn > 1: turn_banner("YOUR TURN" if event.side == 0 else "RIVAL'S TURN",TEAL if event.side == 0 else Color("edaf8d"))
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

func turn_banner(text: String, color: Color) -> void:
 var band := ColorRect.new()
 band.color = Color(.03,.07,.11,.82)
 band.position = Vector2(-1600,390)
 band.size = Vector2(1600,110)
 band.mouse_filter = Control.MOUSE_FILTER_IGNORE
 fx_layer.add_child(band)
 var title := label(band,text,Rect2(0,18,1600,74),58,color,DISPLAY)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var tween := create_tween()
 tween.tween_property(band,"position:x",0.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tween.tween_interval(.55)
 tween.tween_property(band,"position:x",1600.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
 tween.tween_callback(band.queue_free)

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
