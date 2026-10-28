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
var symbols_fit := true

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

# Dark translucent backing so small labels stay readable over ornate frame patterns.
func pill(rect: Rect2) -> void:
 var node := Panel.new()
 node.position = rect.position * card_size
 node.size = rect.size * card_size
 var style := StyleBoxFlat.new()
 style.bg_color = Color(.03,.06,.12,.78)
 style.set_corner_radius_all(int(rect.size.y * card_size.y * .45))
 style.border_color = Color(.85,.7,.4,.55)
 style.set_border_width_all(1)
 node.add_theme_stylebox_override("panel",style)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(node)

func icon_at(texture: Texture2D, pos: Vector2, icon_size: float, tint: Color = Color.WHITE) -> TextureRect:
 var node := TextureRect.new()
 node.texture = texture
 node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.position = pos
 node.size = Vector2(icon_size,icon_size)
 node.modulate = tint
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(node)
 return node

# Lays the card's abilities out as a centred row of icons (with numbers) on the parchment panel.
func build_symbols(factor: float) -> void:
 var area_pos := Vector2(.15 * card_size.x,.664 * card_size.y)
 var area_size := Vector2(.70 * card_size.x,.19 * card_size.y)
 var holder := Control.new()
 holder.name = "Symbols"
 holder.position = area_pos
 holder.size = area_size
 holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(holder)
 var chips := Symbols.chips(data)
 symbols_fit = true
 if chips.is_empty():
  var emblem := Symbols.emblem(str(data.get("faction","")))
  if emblem != null:
   var emblem_size := area_size.y * .8
   var mark := TextureRect.new()
   mark.texture = emblem
   mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   mark.position = (area_size - Vector2(emblem_size,emblem_size)) * .5
   mark.size = Vector2(emblem_size,emblem_size)
   mark.modulate = Color(1,1,1,.4)
   mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
   holder.add_child(mark)
  return
 var icon_px := minf(area_size.y * .78,34.0 * factor)
 var font_px := int(maxf(9.0,18.0 * factor))
 var widths: Array = []
 var total := 0.0
 var gap := icon_px * .16
 for chip in chips:
  var value_text: String = chip.value
  var chip_width := icon_px + (BODY.get_string_size(value_text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_px).x + 2.0 if value_text != "" else 0.0)
  widths.append(chip_width)
  total += chip_width
 total += gap * (chips.size() - 1)
 var scale_fit := minf(1.0,area_size.x * .97 / total)
 icon_px *= scale_fit
 font_px = int(maxf(7.0,font_px * scale_fit))
 gap *= scale_fit
 var x := (area_size.x - total * scale_fit) * .5
 for i in range(chips.size()):
  var chip: Dictionary = chips[i]
  var texture := Symbols.tex(chip.icon)
  if texture != null:
   var picture_node := TextureRect.new()
   picture_node.texture = texture
   picture_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   picture_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   picture_node.position = Vector2(x,(area_size.y - icon_px) * .5)
   picture_node.size = Vector2(icon_px,icon_px)
   picture_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
   holder.add_child(picture_node)
  if chip.value != "":
   var number := Label.new()
   number.text = chip.value
   number.position = Vector2(x + icon_px + 1.0,(area_size.y - icon_px) * .5)
   number.size = Vector2(widths[i] * scale_fit - icon_px,icon_px)
   number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   number.add_theme_font_override("font",BODY)
   number.add_theme_font_size_override("font_size",font_px)
   number.add_theme_color_override("font_color",Color("342b24"))
   number.mouse_filter = Control.MOUSE_FILTER_IGNORE
   holder.add_child(number)
  x += widths[i] * scale_fit + gap
 symbols_fit = x - gap <= area_size.x + 0.5

func build() -> void:
 if data.is_empty(): return
 for child in get_children(): child.queue_free()
 tooltip_text = "%s\n%s" % [data.name,data.text]
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
 var rarity_color: Color = RARITY_COLORS.get(data.rarity,Color("a6acb6"))
 style.shadow_color = Color("35b4b0b0") if selected or targetable else (Color(0.99,0.89,0.64,0.45) if playable else Color(rarity_color.r,rarity_color.g,rarity_color.b,0.4))
 style.shadow_size = 10 if selected or targetable else (6 if playable else 5)
 border.add_theme_stylebox_override("panel",style)
 border.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(border)
 # Pantheon-themed overlay frames let the illustration run full-bleed behind the ornament.
 var themed_frame := "res://assets/cards/frames/frame_%s.png" % str(data.get("faction","")).to_lower()
 var has_theme := ResourceLoader.exists(themed_frame)
 picture("res://assets/cards/art/%s.png" % data.get("art","zeus"),Rect2(0,0,1,1) if has_theme else Rect2(.11,.125,.78,.49))
 var frame_path := themed_frame if has_theme else ("res://assets/cards/frames/epic_purple_v1.png" if data.rarity == "Epic" else "res://assets/cards/frames/master_frame_concept_v1.png")
 var frame := picture(frame_path,Rect2(0,0,1,1))
 frame.stretch_mode = TextureRect.STRETCH_SCALE
 var factor := card_size.x/150.0
 text_at(str(data.cost),Rect2(.015,.035,.2,.13),int(22*factor))
 var name_label := text_at(data.name,Rect2(.245,.048,.55,.075) if has_theme else Rect2(.225,.048,.64,.075),int(12*factor),Color("302317"),DISPLAY)
 name_label.name = "CardName"
 name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 name_label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
 var fitted_size := int(12*factor)
 while DISPLAY.get_string_size(data.name,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted_size).x > card_size.x*(.50 if has_theme else .62) and fitted_size>7:
  fitted_size-=1
 name_label.add_theme_font_size_override("font_size",fitted_size)
 # Category, abilities, rarity and status are shown as symbols; the inspector keeps the full text.
 var category_icon := Symbols.category(data.category)
 if category_icon != null:
  var medallion := .18 * card_size.x
  pill(Rect2(.5 - .12,.63 - .042,.24,.084))
  icon_at(category_icon,Vector2(.5 * card_size.x - medallion * .5,.63 * card_size.y - medallion * .5),medallion)
 else:
  if has_theme: pill(Rect2(.27,.604,.46,.052))
  text_at(data.category.to_upper(),Rect2(.21,.600,.58,.06),int(8*factor),Color("e2c78b"))
 build_symbols(factor)
 if mode != "board":
  var gem := Symbols.rarity(data.rarity)
  if gem != null:
   var gem_size := .15 * card_size.x
   icon_at(gem,Vector2(.5 * card_size.x - gem_size * .5,.93 * card_size.y - gem_size * .5),gem_size)
  else:
   if has_theme: pill(Rect2(.30,.932,.40,.058))
   text_at(data.rarity.to_upper(),Rect2(.23,.94,.54,.05),int(7*factor),RARITY_COLORS.get(data.rarity,Color.GOLD))
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
  var states: Array = []
  if data.get("guard",false): states.append("guard")
  if data.get("ward",false): states.append("ward")
  states.append("attack" if data.get("ready",false) else "hourglass")
  var state_size := .115 * card_size.x
  var row_width := states.size() * state_size + (states.size() - 1) * state_size * .25
  for i in range(states.size()):
   var state_icon := Symbols.tex(states[i])
   if state_icon == null: continue
   var state_tint := Color.WHITE if data.get("ready",false) or states[i] != "hourglass" else Color(.75,.85,1.0,.9)
   icon_at(state_icon,Vector2(.5 * card_size.x - row_width * .5 + i * state_size * 1.25,.945 * card_size.y),state_size,state_tint)
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

