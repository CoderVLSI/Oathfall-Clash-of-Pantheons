extends Control

const STATE = preload("res://scripts/match_state.gd")
const DB = preload("res://scripts/card_database.gd")
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
var selection := -1
var attacker := -1
var busy := false
var generation := 0
var inspected_data: Dictionary = {}
var inspection: Control
var notice := ""
var muted := false
var completed_games := 0
var wins := 0
var sound_player: AudioStreamPlayer
var sound_bank: Dictionary = {}
var testing := false

func _ready() -> void:
 get_window().min_size = Vector2i(960,540)
 load_profile()
 sound_player = AudioStreamPlayer.new()
 add_child(sound_player)
 for key in ["click","summon","attack","win","lose"]:
  if ResourceLoader.exists("res://assets/audio/%s.wav" % key): sound_bank[key] = load("res://assets/audio/%s.wav" % key)
 show_menu()

func sound(key: String) -> void:
 if muted or not sound_bank.has(key): return
 sound_player.stream = sound_bank[key]
 sound_player.volume_db = -10
 sound_player.play()

func load_profile() -> void:
 var config := ConfigFile.new()
 if config.load("user://profile.cfg") == OK:
  wins = int(config.get_value("record","wins",0))
  completed_games = int(config.get_value("record","games",0))
  muted = bool(config.get_value("settings","muted",false))

func save_profile() -> void:
 if testing: return
 var config := ConfigFile.new()
 config.set_value("record","wins",wins)
 config.set_value("record","games",completed_games)
 config.set_value("settings","muted",muted)
 config.save("user://profile.cfg")

func clear_screen() -> void:
 if is_instance_valid(modal): modal.queue_free()
 modal = null
 if is_instance_valid(content):
  remove_child(content)
  content.queue_free()
 content = Control.new()
 content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(content)
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
 label(content,"A MYTHOLOGICAL CARD BATTLE",Rect2(86,115,540,30),15,TEAL,BOLD)
 label(content,"OATHFALL",Rect2(80,158,700,112),83,GOLD,DISPLAY)
 label(content,"CLASH OF PANTHEONS",Rect2(87,275,600,42),28,CREAM,DISPLAY)
 var intro := label(content,"Gods descend. Beasts awaken.\nYour oath decides the fate of the realms.",Rect2(88,342,500,75),23,Color("c0c6ca"))
 intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button(content,"ENTER THE ARENA",Rect2(88,461,350,64),show_factions,true)
 button(content,"CARD COLLECTION",Rect2(88,543,350,55),show_collection)
 button(content,"HOW TO PLAY",Rect2(88,612,350,55),show_rules)
 button(content,"SOUND: OFF" if muted else "SOUND: ON",Rect2(88,681,220,48),func(): muted = not muted; save_profile(); show_menu())
 button(content,"QUIT",Rect2(322,681,116,48),func(): get_tree().quit())
 label(content,"%d VICTORIES  /  %d MATCHES" % [wins,completed_games],Rect2(88,782,500,28),15,GOLD,BOLD)
 label(content,"GREEK  ×  NORSE",Rect2(1190,767,340,35),24,GOLD,DISPLAY)
 label(content,"FIRST AGE  ·  OFFLINE DUELS",Rect2(1190,810,360,24),14,CREAM)
 label(content,"2D painted worlds · 12 unique cards · Two starter decks",Rect2(88,849,800,24),14,Color("8997a2"))

func show_factions() -> void:
 screen = "factions"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900),Color(.5,.5,.55))
 label(content,"CHOOSE YOUR OATH",Rect2(395,60,900,70),44,GOLD,DISPLAY)
 label(content,"Two pantheons. One battlefield. All cards are unlocked.",Rect2(455,139,800,40),22)
 for p in range(2):
  var x := 330+p*500
  panel(content,Rect2(x,220,440,535))
  image(content,"res://assets/cards/art/%s.png" % ("zeus" if p==0 else "thor"),Rect2(x+12,232,416,285))
  label(content,"OLYMPIAN COVENANT" if p==0 else "OATH OF THE NORTH",Rect2(x+25,535,400,42),24,GOLD,DISPLAY)
  var info := label(content,"GREEK · Defense & divine power\nHold the line with Cerberus. Restore your\nSanctum, then summon Poseidon and Zeus." if p==0 else "NORSE · Pressure & fierce beasts\nLead raiders into battle. Unchain Fenrir,\nthen let Thor finish the conflict.",Rect2(x+25,590,390,95),18,CREAM)
  info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var faction := "Greek" if p==0 else "Norse"
  button(content,"PLAY " + faction.to_upper(),Rect2(x+25,696,390,43),func(): start_match(faction),true)
 button(content,"BACK",Rect2(60,55,150,48),show_menu)

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
 var text := "WIN THE DUEL\nReduce the opposing Sanctum from 25 health to zero. Both starter decks contain 18 cards.\n\nYOUR TURN\nGain one maximum Power (up to 10), refill it, ready your units, and draw one card.\nTap a card in your hand, then SUMMON / CAST in the left panel. Damage spells need a target.\n\nCOMBAT\nTap a ready friendly unit, then an enemy unit or the enemy Sanctum. Both units deal damage\nsimultaneously. Every unit attacks once per turn. New units rest until your next turn.\n\nKEYWORDS\nGUARD — Defeat enemy Guards before attacking other units or the Sanctum.\nRUSH — A newly summoned unit may attack units immediately, but not the Sanctum.\nARRIVAL — An effect happens once when the unit enters the battlefield.\nDamage spells ignore Guard. Healing never exceeds 25 health. Your board holds 5 units.\n\nRUNNING OUT OF CARDS\nAn empty deck deals increasing fatigue damage each draw. Full hands (9 cards) burn new draws.\n\nCONTROLS\nClick or tap cards to inspect and select them. Use the left panel to confirm a play.\nCancel a selection with Escape or CANCEL. End Turn gives control to the AI.\nThe match menu pauses AI actions. Concede ends the match; rematch starts a fresh duel."
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

func start_match(faction: String) -> void:
 generation += 1
 close_modal()
 chosen_faction = faction
 game = STATE.new()
 game.start(faction)
 selection = -1
 attacker = -1
 busy = false
 screen = "battle"
 inspected_data = DB.card(game.sides[0].hand[0])
 notice = "Your oath begins. Select a card from your hand."
 render_battle()

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
   add_card(content,units[i],Vector2(start_x+i*165,row_y-7),Vector2(150,225),"board" if side==0 else "enemy",-1,side==0 and units[i].ready and game.current==0 and not busy)
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
 button(body,"SOUND: OFF" if muted else "SOUND: ON",Rect2(65,260,500,52),func(): muted=not muted; save_profile(); show_pause())
 button(body,"CONCEDE MATCH",Rect2(65,330,500,52),func(): close_modal(); game.concede(0); render_battle())
 label(body,"AI actions wait while this menu is open.",Rect2(92,425,490,30),17,Color("94a6b4"))

func show_result() -> void:
 generation += 1
 busy = false
 if screen != "result":
  completed_games += 1
  if game.winner==0: wins += 1
  save_profile()
  sound("win" if game.winner==0 else "lose")
 screen = "result"
 clear_screen()
 image(content,"res://assets/backgrounds/menu.png",Rect2(0,0,1600,900),Color(.38,.42,.48))
 panel(content,Rect2(400,155,800,590),Color("0b1826f0"),GOLD)
 label(content,"THE OATH IS FULFILLED" if game.winner==0 else "THE REALMS REMEMBER",Rect2(510,207,670,40),18,TEAL,BOLD)
 var title := "VICTORY" if game.winner==0 else ("DRAW" if game.winner==2 else "DEFEAT")
 var headline := label(content,title,Rect2(430,273,740,100),69,GOLD,DISPLAY)
 headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var summary := label(content,"%s · %d ROUNDS\nYour Sanctum: %d  /  Rival Sanctum: %d" % [chosen_faction.to_upper(),ceili(game.turn/2.0),maxi(0,game.sides[0].hp),maxi(0,game.sides[1].hp)],Rect2(470,404,660,90),23,CREAM)
 summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 button(content,"REMATCH",Rect2(550,543,500,60),func(): start_match(chosen_faction),true)
 button(content,"MAIN MENU",Rect2(550,622,500,54),show_menu)

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if is_instance_valid(modal): close_modal()
  elif screen=="battle":
   if selection>=0 or attacker>=0: cancel_selection()
   else: show_pause()
  elif screen=="factions": show_menu()
