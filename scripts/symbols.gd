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
