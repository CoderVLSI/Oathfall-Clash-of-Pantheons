class_name Symbols
extends RefCounted

# Symbol icons (assets/ui/sym/<name>.png) that replace text on cards and in the battle UI.
const DIR = "res://assets/ui/sym/"
static var cache: Dictionary = {}

static func tex(symbol_name: String) -> Texture2D:
 if cache.has(symbol_name): return cache[symbol_name]
 var path := DIR + symbol_name + ".png"
 var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
 cache[symbol_name] = texture
 return texture

static func emblem(faction: String) -> Texture2D:
 return tex("emblem_" + faction.to_lower())

static func rarity(rarity_name: String) -> Texture2D:
 return tex(rarity_name.to_lower())

static func category(category_name: String) -> Texture2D:
 return tex(category_name.to_lower())

# What a card does, as an ordered list of {"icon": name, "value": text}. Cards with no
# abilities return an empty list.
static func chips(data: Dictionary) -> Array:
 var result: Array = []
 if data.get("category","") == "Spell":
  var amount := int(data.get("amount",0))
  match data.get("effect",""):
   "damage": result.append({"icon":"damage","value":str(amount)})
   "heal": result.append({"icon":"heal","value":str(amount)})
   "draw": result.append({"icon":"draw","value":str(amount)})
   "sweep": result.append({"icon":"sweep","value":str(amount)})
   "buff": result.append({"icon":"buff","value":"+%d/+%d" % [int(data.get("buff_attack",0)),int(data.get("buff_health",0))]})
  return result
 if data.get("guard",false): result.append({"icon":"guard","value":""})
 if data.get("ward",false): result.append({"icon":"ward","value":""})
 if data.get("rush",false): result.append({"icon":"rush","value":""})
 if data.get("lifesteal",false): result.append({"icon":"lifesteal","value":""})
 if data.has("heal"):
  result.append({"icon":"arrival","value":""})
  result.append({"icon":"heal","value":str(int(data.heal))})
 if data.has("arrival_damage"):
  result.append({"icon":"arrival","value":""})
  result.append({"icon":"sweep","value":str(int(data.arrival_damage))})
 if data.has("arrival_draw"):
  result.append({"icon":"arrival","value":""})
  result.append({"icon":"draw","value":str(int(data.arrival_draw))})
 if data.has("buff_attack") or data.has("buff_health"):
  result.append({"icon":"arrival","value":""})
  result.append({"icon":"buff","value":"+%d/+%d" % [int(data.get("buff_attack",0)),int(data.get("buff_health",0))]})
 if data.get("deathrattle","") != "":
  result.append({"icon":"deathrattle","value":""})
  var kind: String = data.deathrattle
  result.append({"icon":kind,"value":str(int(data.get("deathrattle_amount",1)))})
 return result
