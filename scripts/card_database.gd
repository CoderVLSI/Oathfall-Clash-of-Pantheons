class_name CardDatabase
extends RefCounted

const CARDS = {
 "hoplite": {"name":"Bronze Hoplite","faction":"Greek","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"guard":false,"text":"A steadfast soldier of the marble cities.","art":"hoplite"},
 "cerberus": {"name":"Cerberus","faction":"Greek","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"cerberus"},
 "poseidon": {"name":"Poseidon","faction":"Greek","category":"God","rarity":"Legendary","cost":5,"attack":5,"health":7,"heal":3,"text":"ARRIVAL · Restore 3 health to your Sanctum.","art":"poseidon"},
 "zeus": {"name":"Zeus","faction":"Greek","category":"God","rarity":"Mythic","cost":7,"attack":7,"health":8,"arrival_damage":2,"text":"ARRIVAL · Deal 2 damage to every enemy unit.","art":"zeus"},
 "bolt": {"name":"Olympian Bolt","faction":"Greek","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"zeus"},
 "aegis": {"name":"Aegis Blessing","faction":"Greek","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"poseidon"},
 "raider": {"name":"Fjord Raider","faction":"Norse","category":"Mortal","rarity":"Common","cost":1,"attack":3,"health":2,"text":"A fearless warrior of the northern fjords.","art":"raider"},
 "valkyrie": {"name":"Valkyrie","faction":"Norse","category":"Immortal","rarity":"Rare","cost":3,"attack":3,"health":5,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"valkyrie"},
 "fenrir": {"name":"Fenrir","faction":"Norse","category":"Beast","rarity":"Legendary","cost":5,"attack":6,"health":5,"rush":true,"text":"RUSH · Can attack enemy units on the turn it is summoned.","art":"fenrir"},
 "thor": {"name":"Thor","faction":"Norse","category":"God","rarity":"Mythic","cost":7,"attack":8,"health":7,"arrival_damage":2,"text":"ARRIVAL · Deal 2 damage to every enemy unit.","art":"thor"},
 "storm": {"name":"Runic Thunder","faction":"Norse","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"thor"},
 "feast": {"name":"Feast of the Hall","faction":"Norse","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"valkyrie"}
}

static func card(id: String) -> Dictionary:
 var result: Dictionary = CARDS[id].duplicate(true)
 result["id"] = id
 return result

static func deck(faction: String) -> Array:
 var ids: Array = ["hoplite","hoplite","hoplite","hoplite","hoplite","hoplite","cerberus","cerberus","cerberus","poseidon","poseidon","zeus","bolt","bolt","bolt","bolt","aegis","aegis"]
 if faction == "Norse":
  ids = ["raider","raider","raider","raider","raider","raider","valkyrie","valkyrie","valkyrie","fenrir","fenrir","thor","storm","storm","storm","storm","feast","feast"]
 return ids

