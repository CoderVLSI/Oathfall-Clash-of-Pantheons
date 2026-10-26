class_name OathCardView
extends Control

signal chosen(view)
signal inspected(view)
const FRAME = preload("res://assets/cards/frames/master_frame_concept_v1.png")
const DISPLAY = preload("res://assets/fonts/display.ttf")
const BODY = preload("res://assets/fonts/body_bold.ttf")
const RARITY_COLORS = {"Common":Color("a6acb6"),"Uncommon":Color("a4cba5"),"Rare":Color("80c8f0"),"Epic":Color("cc9df1"),"Legendary":Color("f4cc79"),"Mythic":Color("6de0d4")}
var data: Dictionary = {}
var mode := "hand"
var index := -1
var playable := false
var selected := false
var targetable := false
var card_size := Vector2(150,225)
var built := false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_STOP
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 mouse_entered.connect(func():
  if mode != "inspect": inspected.emit(self)
  _hover(true))
 mouse_exited.connect(func(): _hover(false))
 build()

func picture(path: String, rect: Rect2) -> TextureRect:
 var image := TextureRect.new()
 image.texture = load(path) if ResourceLoader.exists(path) else FRAME
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 image.position = rect.position * card_size
 image.size = rect.size * card_size
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(image)
 return image

func text_at(value: String, rect: Rect2, font_size: int, color: Color = Color("fff2d3"), font: Font = BODY) -> Label:
 var label := Label.new()
 label.clip_text = true
 label.autowrap_mode = TextServer.AUTOWRAP_OFF
 label.position = rect.position * card_size
 label.size = rect.size * card_size
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_override("font",font)
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
 label.add_theme_constant_override("shadow_offset_x",1)
 label.add_theme_constant_override("shadow_offset_y",1)
 label.text = value
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 label.size = rect.size * card_size
 return label

func build() -> void:
 if data.is_empty(): return
 for child in get_children(): child.queue_free()
 size = card_size
 custom_minimum_size = card_size
 pivot_offset = card_size/2
 var border := Panel.new()
 border.position = Vector2(-3,-3)
 border.size = card_size+Vector2(6,6)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0,0,0,0.25)
 style.border_color = Color("72f2df") if selected or targetable else (Color("fce4a3") if playable else RARITY_COLORS.get(data.rarity,Color("a6acb6")))
 style.set_border_width_all(2)
 style.set_corner_radius_all(10)
 style.shadow_color = Color("35b4b070") if selected or targetable else Color(0,0,0,0.5)
 style.shadow_size = 10 if selected or targetable else 5
 border.add_theme_stylebox_override("panel",style)
 border.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(border)
 picture("res://assets/cards/art/%s.png" % data.get("art","zeus"),Rect2(.11,.125,.78,.49))
 var frame_path := "res://assets/cards/frames/epic_purple_v1.png" if data.rarity == "Epic" else "res://assets/cards/frames/master_frame_concept_v1.png"
 var frame := picture(frame_path,Rect2(0,0,1,1))
 frame.stretch_mode = TextureRect.STRETCH_SCALE
 var factor := card_size.x/150.0
 text_at(str(data.cost),Rect2(.015,.035,.2,.13),int(22*factor))
 var name_label := text_at(data.name,Rect2(.225,.048,.64,.075),int(12*factor),Color("302317"),DISPLAY)
 name_label.name = "CardName"
 name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 name_label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
 var fitted_size := int(12*factor)
 while DISPLAY.get_string_size(data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted_size).x > card_size.x*.62 and fitted_size>7:
  fitted_size-=1
 name_label.add_theme_font_size_override("font_size",fitted_size)
 text_at(data.category.to_upper(),Rect2(.21,.600,.58,.06),int(8*factor),Color("e2c78b"))
 var short_rules: String = data.text
 if data.get("guard",false): short_rules = "GUARD\nProtects your allies."
 elif data.get("rush",false): short_rules = "RUSH\nAttacks units now."
 elif data.has("arrival_damage"): short_rules = "ARRIVAL\n2 damage to all enemy units."
 elif data.has("heal"): short_rules = "ARRIVAL\nRestore 3 Sanctum health."
 elif data.get("effect","")=="damage": short_rules = "Deal 3 damage\nto any enemy."
 elif data.get("effect","")=="heal": short_rules = "Restore 5 health\nto your Sanctum."
 elif data.category=="Mortal": short_rules = "A mortal warrior\nbound by oath."
 var rules := text_at("",Rect2(.15,.664,.70,.19),maxi(9,int(10*factor)),Color("342b24"))
 rules.name = "RulesText"
 rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 rules.text = short_rules
 rules.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
 rules.size = Vector2(.70,.19)*card_size
 var rarity := text_at(data.rarity.to_upper(),Rect2(.23,.94,.54,.05),int(7*factor),RARITY_COLORS.get(data.rarity,Color.GOLD))
 rarity.visible = mode != "board"
 if data.category != "Spell":
  text_at(str(data.attack),Rect2(.025,.832,.19,.12),int(22*factor)).name = "AttackValue"
  text_at(str(data.get("hp",data.health)),Rect2(.785,.832,.19,.12),int(22*factor)).name = "HealthValue"
 else:
  var texture: Texture2D = load("res://assets/ui/icons.png")
  var atlas := AtlasTexture.new()
  atlas.atlas = texture
  atlas.region = Rect2(texture.get_width()/3.0,texture.get_height()/2.0,texture.get_width()/3.0,texture.get_height()/2.0)
  for x in [.03,.79]:
   var spell_icon := TextureRect.new()
   spell_icon.texture = atlas
   spell_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   spell_icon.position = Vector2(x,.85)*card_size
   spell_icon.size = Vector2(.18,.08)*card_size
   spell_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   add_child(spell_icon)
 if mode == "board":
  var status := "READY" if data.get("ready",false) else ("RESTING" if data.get("fresh",false) else "EXHAUSTED")
  if data.get("guard",false): status = "GUARD · " + status
  var tag := text_at(status,Rect2(.04,.948,.92,.06),int(8*factor),Color("81e0d0") if data.get("ready",false) else Color("e3cba0"))
  tag.add_theme_color_override("font_shadow_color",Color.BLACK)
 built = true

func _hover(enter: bool) -> void:
 if mode == "inspect": return
 z_index = 12 if enter else 0
 var tween := create_tween()
 tween.tween_property(self,"scale",Vector2.ONE*(1.055 if enter else 1.0),.12)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_LEFT:
   inspected.emit(self)
   chosen.emit(self)
   accept_event()
  elif event.button_index == MOUSE_BUTTON_RIGHT:
   inspected.emit(self)
   accept_event()

