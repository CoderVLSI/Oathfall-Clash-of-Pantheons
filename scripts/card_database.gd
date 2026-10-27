class_name CardDatabase
extends RefCounted

# Data-driven keywords: guard, rush, ward (absorbs first damage), lifesteal (damage heals owner's Sanctum),
# deathrattle + deathrattle_amount ("draw" | "damage" | "heal"), heal / arrival_damage / arrival_draw /
# buff_attack+buff_health (all other allies) on units, and spell effects damage | heal | draw | buff | sweep.
# "short" overrides the compact on-card rules text.
const CARDS = {
 "hoplite": {"name":"Bronze Hoplite","faction":"Greek","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"guard":false,"text":"A steadfast soldier of the marble cities.","art":"hoplite"},
 "cerberus": {"name":"Cerberus","faction":"Greek","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"cerberus"},
 "poseidon": {"name":"Poseidon","faction":"Greek","category":"God","rarity":"Legendary","cost":5,"attack":5,"health":7,"heal":3,"text":"ARRIVAL · Restore 3 health to your Sanctum.","art":"poseidon"},
 "zeus": {"name":"Zeus","faction":"Greek","category":"God","rarity":"Mythic","cost":7,"attack":7,"health":8,"arrival_damage":2,"text":"ARRIVAL · Deal 2 damage to every enemy unit.","art":"zeus"},
 "bolt": {"name":"Olympian Bolt","faction":"Greek","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"zeus"},
 "aegis": {"name":"Aegis Blessing","faction":"Greek","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"poseidon"},
 "phalanx": {"name":"Aegis Phalanx","faction":"Greek","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"hoplite"},
 "oracle": {"name":"Delphic Oracle","faction":"Greek","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"poseidon"},
 "hydra": {"name":"Lernaean Hydra","faction":"Greek","category":"Beast","rarity":"Epic","cost":4,"attack":3,"health":4,"deathrattle":"draw","deathrattle_amount":2,"text":"DEATHRATTLE · When this unit dies, draw 2 cards.","short":"DEATHRATTLE\nDraw 2 cards.","art":"cerberus"},
 "athena": {"name":"Athena","faction":"Greek","category":"God","rarity":"Legendary","cost":4,"attack":3,"health":4,"buff_attack":1,"buff_health":1,"text":"ARRIVAL · Give your other units +1/+1.","short":"ARRIVAL\nOther allies get +1/+1.","art":"zeus"},
 "prophecy": {"name":"Delphic Prophecy","faction":"Greek","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"poseidon"},
 "aphrodite": {"name":"Aphrodite","faction":"Greek","category":"God","rarity":"Legendary","cost":5,"attack":4,"health":6,"heal":3,"lifesteal":true,"text":"ARRIVAL · Restore 3 health to your Sanctum. LIFESTEAL · Damage dealt by this unit restores your Sanctum.","short":"ARRIVAL: Heal 3\nLIFESTEAL","art":"aphrodite"},
 "triumph": {"name":"Olympic Triumph","faction":"Greek","category":"Spell","rarity":"Rare","cost":3,"effect":"buff","buff_attack":1,"buff_health":1,"text":"Give all your units +1/+1.","short":"All your units\nget +1/+1.","art":"zeus"},
 "raider": {"name":"Fjord Raider","faction":"Norse","category":"Mortal","rarity":"Common","cost":1,"attack":3,"health":2,"text":"A fearless warrior of the northern fjords.","art":"raider"},
 "valkyrie": {"name":"Valkyrie","faction":"Norse","category":"Immortal","rarity":"Rare","cost":3,"attack":3,"health":5,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"valkyrie"},
 "fenrir": {"name":"Fenrir","faction":"Norse","category":"Beast","rarity":"Legendary","cost":5,"attack":6,"health":5,"rush":true,"text":"RUSH · Can attack enemy units on the turn it is summoned.","art":"fenrir"},
 "thor": {"name":"Thor","faction":"Norse","category":"God","rarity":"Mythic","cost":7,"attack":8,"health":7,"arrival_damage":2,"text":"ARRIVAL · Deal 2 damage to every enemy unit.","art":"thor"},
 "storm": {"name":"Runic Thunder","faction":"Norse","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"thor"},
 "feast": {"name":"Feast of the Hall","faction":"Norse","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"valkyrie"},
 "huginn": {"name":"Huginn the Raven","faction":"Norse","category":"Beast","rarity":"Uncommon","cost":1,"attack":1,"health":1,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"raider"},
 "draugr": {"name":"Draugr Reaver","faction":"Norse","category":"Immortal","rarity":"Rare","cost":3,"attack":3,"health":2,"lifesteal":true,"text":"LIFESTEAL · Damage dealt by this unit restores your Sanctum.","short":"LIFESTEAL\nDamage heals your Sanctum.","art":"valkyrie"},
 "garm": {"name":"Garm, Hel's Hound","faction":"Norse","category":"Beast","rarity":"Epic","cost":4,"attack":4,"health":3,"deathrattle":"damage","deathrattle_amount":3,"text":"DEATHRATTLE · When this unit dies, deal 3 damage to the enemy Sanctum.","short":"DEATHRATTLE\n3 damage to enemy Sanctum.","art":"fenrir"},
 "tyr": {"name":"Tyr, Oathkeeper","faction":"Norse","category":"God","rarity":"Legendary","cost":5,"attack":3,"health":6,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"valkyrie"},
 "gale": {"name":"Frostbite Gale","faction":"Norse","category":"Spell","rarity":"Rare","cost":3,"effect":"sweep","amount":2,"text":"Deal 2 damage to every enemy unit.","short":"2 damage to all\nenemy units.","art":"thor"},
 "rune": {"name":"Rune of Might","faction":"Norse","category":"Spell","rarity":"Uncommon","cost":3,"effect":"buff","buff_attack":2,"buff_health":0,"text":"Give all your units +2/+0.","short":"All your units\nget +2/+0.","art":"thor"},
 "legionary": {"name":"Roman Legionary","faction":"Roman","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"text":"A disciplined soldier of the eternal legions.","art":"legionary"},
 "centurion": {"name":"Testudo Centurion","faction":"Roman","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"centurion"},
 "augur": {"name":"Vestal Augur","faction":"Roman","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"augur"},
 "wolf": {"name":"Capitoline She-Wolf","faction":"Roman","category":"Beast","rarity":"Epic","cost":4,"attack":3,"health":4,"deathrattle":"draw","deathrattle_amount":2,"text":"DEATHRATTLE · When this unit dies, draw 2 cards.","short":"DEATHRATTLE\nDraw 2 cards.","art":"wolf"},
 "gladiator": {"name":"Arena Gladiator","faction":"Roman","category":"Mortal","rarity":"Rare","cost":3,"attack":4,"health":2,"rush":true,"text":"RUSH · Can attack enemy units on the turn it is summoned.","art":"gladiator"},
 "mars": {"name":"Mars","faction":"Roman","category":"God","rarity":"Legendary","cost":5,"attack":5,"health":5,"buff_attack":1,"buff_health":1,"text":"ARRIVAL · Give your other units +1/+1.","short":"ARRIVAL\nOther allies get +1/+1.","art":"mars"},
 "minerva": {"name":"Minerva","faction":"Roman","category":"God","rarity":"Legendary","cost":5,"attack":4,"health":6,"heal":4,"text":"ARRIVAL · Restore 4 health to your Sanctum.","short":"ARRIVAL\nRestore 4 health.","art":"minerva"},
 "jupiter": {"name":"Jupiter","faction":"Roman","category":"God","rarity":"Mythic","cost":7,"attack":6,"health":8,"arrival_damage":3,"text":"ARRIVAL · Deal 3 damage to every enemy unit.","short":"ARRIVAL\n3 damage to all enemy units.","art":"jupiter"},
 "pilum": {"name":"Pilum Volley","faction":"Roman","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"gladiator"},
 "salve": {"name":"Salve of Asclepius","faction":"Roman","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"minerva"},
 "counsel": {"name":"Senate's Counsel","faction":"Roman","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"augur"},
 "rally": {"name":"Rally the Legion","faction":"Roman","category":"Spell","rarity":"Rare","cost":3,"effect":"buff","buff_attack":1,"buff_health":1,"text":"Give all your units +1/+1.","short":"All your units\nget +1/+1.","art":"mars"},
 "medjay": {"name":"Medjay Warrior","faction":"Egyptian","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"text":"A watchful guardian of the Nile cities.","art":"medjay"},
 "scarab": {"name":"Scarab Sentinel","faction":"Egyptian","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"scarab"},
 "thothpriest": {"name":"Priest of Thoth","faction":"Egyptian","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"thothpriest"},
 "sphinx": {"name":"Great Sphinx","faction":"Egyptian","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"sphinx"},
 "mummy": {"name":"Cursed Mummy Lord","faction":"Egyptian","category":"Immortal","rarity":"Epic","cost":4,"attack":4,"health":3,"deathrattle":"damage","deathrattle_amount":3,"text":"DEATHRATTLE · When this unit dies, deal 3 damage to the enemy Sanctum.","short":"DEATHRATTLE\n3 damage to enemy Sanctum.","art":"mummy"},
 "sekhmet": {"name":"Sekhmet","faction":"Egyptian","category":"God","rarity":"Legendary","cost":5,"attack":5,"health":5,"lifesteal":true,"text":"LIFESTEAL · Damage dealt by this unit restores your Sanctum.","short":"LIFESTEAL\nDamage heals your Sanctum.","art":"sekhmet"},
 "isis": {"name":"Isis","faction":"Egyptian","category":"God","rarity":"Legendary","cost":5,"attack":4,"health":6,"heal":4,"text":"ARRIVAL · Restore 4 health to your Sanctum.","short":"ARRIVAL\nRestore 4 health.","art":"isis"},
 "ra": {"name":"Ra","faction":"Egyptian","category":"God","rarity":"Mythic","cost":7,"attack":7,"health":7,"arrival_damage":3,"text":"ARRIVAL · Deal 3 damage to every enemy unit.","short":"ARRIVAL\n3 damage to all enemy units.","art":"ra"},
 "horus": {"name":"Spear of Horus","faction":"Egyptian","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"ra"},
 "nile": {"name":"Blessing of the Nile","faction":"Egyptian","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"isis"},
 "scroll": {"name":"Scroll of Thoth","faction":"Egyptian","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"thothpriest"},
 "locusts": {"name":"Plague of Locusts","faction":"Egyptian","category":"Spell","rarity":"Rare","cost":3,"effect":"sweep","amount":2,"text":"Deal 2 damage to every enemy unit.","short":"2 damage to all\nenemy units.","art":"mummy"},
 "ashigaru": {"name":"Ashigaru Spearman","faction":"Japanese","category":"Mortal","rarity":"Common","cost":1,"attack":3,"health":2,"text":"A conscript spearman of the warring provinces.","art":"ashigaru"},
 "miko": {"name":"Shrine Maiden","faction":"Japanese","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"miko"},
 "kitsune": {"name":"Kitsune Trickster","faction":"Japanese","category":"Beast","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"kitsune"},
 "oni": {"name":"Oni Gatekeeper","faction":"Japanese","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"oni"},
 "onryo": {"name":"Onryo Spirit","faction":"Japanese","category":"Immortal","rarity":"Epic","cost":4,"attack":4,"health":3,"deathrattle":"damage","deathrattle_amount":3,"text":"DEATHRATTLE · When this unit dies, deal 3 damage to the enemy Sanctum.","short":"DEATHRATTLE\n3 damage to enemy Sanctum.","art":"onryo"},
 "tengu": {"name":"Tengu Skywatcher","faction":"Japanese","category":"Immortal","rarity":"Rare","cost":3,"attack":4,"health":3,"rush":true,"text":"RUSH · Can attack enemy units on the turn it is summoned.","art":"tengu"},
 "amaterasu": {"name":"Amaterasu","faction":"Japanese","category":"God","rarity":"Legendary","cost":4,"attack":3,"health":4,"buff_attack":1,"buff_health":1,"text":"ARRIVAL · Give your other units +1/+1.","short":"ARRIVAL\nOther allies get +1/+1.","art":"amaterasu"},
 "susanoo": {"name":"Susanoo","faction":"Japanese","category":"God","rarity":"Mythic","cost":7,"attack":8,"health":7,"arrival_damage":2,"text":"ARRIVAL · Deal 2 damage to every enemy unit.","art":"susanoo"},
 "kusanagi": {"name":"Kusanagi Strike","faction":"Japanese","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"susanoo"},
 "sake": {"name":"Sacred Sake","faction":"Japanese","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"miko"},
 "kamikaze": {"name":"Divine Wind","faction":"Japanese","category":"Spell","rarity":"Rare","cost":3,"effect":"sweep","amount":2,"text":"Deal 2 damage to every enemy unit.","short":"2 damage to all\nenemy units.","art":"tengu"},
 "omikuji": {"name":"Omikuji Fortune","faction":"Japanese","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"kitsune"},
 "halberdier": {"name":"Jade Halberdier","faction":"Chinese","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"text":"A disciplined soldier of the jade-armored legions.","art":"jadehalberdier"},
 "wudangmonk": {"name":"Wudang Shield-Monk","faction":"Chinese","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"wudangmonk"},
 "scholar": {"name":"Immortal Scholar","faction":"Chinese","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"scholar"},
 "lion": {"name":"Stone Guardian Lion","faction":"Chinese","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"lion"},
 "vermilionbird": {"name":"Vermilion Bird","faction":"Chinese","category":"Beast","rarity":"Epic","cost":4,"attack":3,"health":4,"deathrattle":"heal","deathrattle_amount":4,"text":"DEATHRATTLE · When this unit dies, restore 4 health to your Sanctum.","short":"DEATHRATTLE\nRestore 4 health.","art":"vermilionbird"},
 "whitetiger": {"name":"White Tiger of the West","faction":"Chinese","category":"Beast","rarity":"Rare","cost":3,"attack":4,"health":3,"rush":true,"text":"RUSH · Can attack enemy units on the turn it is summoned.","art":"whitetiger"},
 "nezha": {"name":"Nezha, Lotus Prince","faction":"Chinese","category":"God","rarity":"Legendary","cost":4,"attack":3,"health":4,"buff_attack":1,"buff_health":1,"text":"ARRIVAL · Give your other units +1/+1.","short":"ARRIVAL\nOther allies get +1/+1.","art":"nezha"},
 "azuredragon": {"name":"Azure Dragon","faction":"Chinese","category":"God","rarity":"Mythic","cost":7,"attack":7,"health":7,"arrival_damage":3,"text":"ARRIVAL · Deal 3 damage to every enemy unit.","short":"ARRIVAL\n3 damage to all enemy units.","art":"azuredragon"},
 "heavenlybolt": {"name":"Heavenly Lightning","faction":"Chinese","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"azuredragon"},
 "peach": {"name":"Peach of Longevity","faction":"Chinese","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"nezha"},
 "arrows": {"name":"Rain of Arrows","faction":"Chinese","category":"Spell","rarity":"Rare","cost":3,"effect":"sweep","amount":2,"text":"Deal 2 damage to every enemy unit.","short":"2 damage to all\nenemy units.","art":"jadehalberdier"},
 "sagescroll": {"name":"Sage's Scroll","faction":"Chinese","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"scholar"},
 "eaglewarrior": {"name":"Eagle Warrior","faction":"Aztec","category":"Mortal","rarity":"Common","cost":1,"attack":2,"health":3,"text":"An elite warrior of the Mexica eagle order.","art":"eaglewarrior"},
 "chimalli": {"name":"Chimalli Guardian","faction":"Aztec","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"guard":true,"ward":true,"text":"GUARD · WARD · The first damage this unit would take is prevented.","short":"GUARD · WARD\nBlocks the first hit.","art":"chimalli"},
 "aztecseer": {"name":"Calendar Seer","faction":"Aztec","category":"Mortal","rarity":"Uncommon","cost":2,"attack":1,"health":3,"arrival_draw":1,"text":"ARRIVAL · Draw a card.","short":"ARRIVAL\nDraw a card.","art":"aztecseer"},
 "xolotl": {"name":"Xolotl, Fire Hound","faction":"Aztec","category":"Beast","rarity":"Epic","cost":3,"attack":3,"health":6,"guard":true,"text":"GUARD · Enemies must defeat your Guards before attacking other targets.","art":"xolotl"},
 "quetzalbird": {"name":"Quetzal Spirit","faction":"Aztec","category":"Beast","rarity":"Epic","cost":4,"attack":3,"health":4,"deathrattle":"heal","deathrattle_amount":4,"text":"DEATHRATTLE · When this unit dies, restore 4 health to your Sanctum.","short":"DEATHRATTLE\nRestore 4 health.","art":"quetzalbird"},
 "huitzilopochtl": {"name":"Huitzilopochtl","faction":"Aztec","category":"God","rarity":"Legendary","cost":4,"attack":3,"health":4,"buff_attack":1,"buff_health":1,"text":"ARRIVAL · Give your other units +1/+1.","short":"ARRIVAL\nOther allies get +1/+1.","art":"huitzilopochtl"},
 "tezcatlipoca": {"name":"Tezcatlipoca","faction":"Aztec","category":"God","rarity":"Legendary","cost":5,"attack":5,"health":5,"lifesteal":true,"text":"LIFESTEAL · Damage dealt by this unit restores your Sanctum.","short":"LIFESTEAL\nDamage heals your Sanctum.","art":"tezcatlipoca"},
 "quetzalcoatl": {"name":"Quetzalcoatl","faction":"Aztec","category":"God","rarity":"Mythic","cost":7,"attack":7,"health":7,"arrival_damage":3,"text":"ARRIVAL · Deal 3 damage to every enemy unit.","short":"ARRIVAL\n3 damage to all enemy units.","art":"quetzalcoatl"},
 "dart": {"name":"Obsidian Dart","faction":"Aztec","category":"Spell","rarity":"Rare","cost":2,"effect":"damage","amount":3,"text":"Deal 3 damage to an enemy unit or Sanctum. Ignores Guard.","art":"tezcatlipoca"},
 "maize": {"name":"Gift of Maize","faction":"Aztec","category":"Spell","rarity":"Uncommon","cost":2,"effect":"heal","amount":5,"text":"Restore 5 health to your Sanctum.","art":"quetzalbird"},
 "tlalocrain": {"name":"Rain of Tlaloc","faction":"Aztec","category":"Spell","rarity":"Rare","cost":3,"effect":"sweep","amount":2,"text":"Deal 2 damage to every enemy unit.","short":"2 damage to all\nenemy units.","art":"xolotl"},
 "codex": {"name":"Codex of Days","faction":"Aztec","category":"Spell","rarity":"Uncommon","cost":2,"effect":"draw","amount":2,"text":"Draw 2 cards.","short":"Draw 2 cards.","art":"aztecseer"}
}

const FACTIONS = ["Greek","Norse","Roman","Egyptian","Japanese","Chinese","Aztec"]

# Pantheon Power: one hero ability per pantheon, usable once per turn for its Power cost.
# target: "none" | "ally" (friendly unit) | "enemy" (enemy unit).
const HERO_POWERS = {
 "Greek": {"name":"Aegis of Olympus","cost":3,"target":"ally","effect":"ward","text":"Give a friendly unit Ward."},
 "Norse": {"name":"Runic Fury","cost":2,"target":"ally","effect":"fury","text":"A friendly unit gets +2 Attack this turn."},
 "Roman": {"name":"Legion Orders","cost":3,"target":"ally","effect":"orders","text":"Ready a friendly unit that already acted."},
 "Egyptian": {"name":"Whisper of Anubis","cost":2,"target":"none","effect":"whisper","text":"Deal 1 damage to the enemy Sanctum and restore 1 to yours."},
 "Japanese": {"name":"Fox-fire","cost":2,"target":"enemy","effect":"foxfire","text":"Deal 1 damage to an enemy unit."},
 "Chinese": {"name":"Harmony of Qi","cost":2,"target":"none","effect":"harmony","text":"Draw a card and restore 1 to your Sanctum."},
 "Aztec": {"name":"Solar Blessing","cost":3,"target":"ally","effect":"blessing","text":"A friendly unit gets +1/+1."}
}

static func hero_power(faction: String) -> Dictionary:
 return HERO_POWERS.get(faction,HERO_POWERS["Greek"])
# 24-card starter decks, one per pantheon.
const DECKS = {
 "Greek": ["hoplite","hoplite","hoplite","hoplite","cerberus","cerberus","poseidon","poseidon","zeus","bolt","bolt","bolt","aegis","phalanx","phalanx","oracle","oracle","hydra","hydra","athena","aphrodite","prophecy","prophecy","triumph"],
 "Norse": ["raider","raider","raider","raider","raider","valkyrie","valkyrie","fenrir","fenrir","thor","storm","storm","storm","feast","huginn","huginn","draugr","draugr","garm","garm","tyr","gale","gale","rune"],
 "Roman": ["legionary","legionary","legionary","legionary","legionary","centurion","centurion","augur","augur","wolf","wolf","gladiator","gladiator","mars","minerva","minerva","jupiter","pilum","pilum","pilum","salve","counsel","counsel","rally"],
 "Egyptian": ["medjay","medjay","medjay","medjay","medjay","scarab","scarab","thothpriest","thothpriest","sphinx","sphinx","mummy","mummy","sekhmet","isis","ra","horus","horus","horus","nile","scroll","scroll","locusts","locusts"],
 "Japanese": ["ashigaru","ashigaru","ashigaru","ashigaru","ashigaru","miko","miko","kitsune","kitsune","oni","oni","onryo","onryo","tengu","tengu","amaterasu","susanoo","kusanagi","kusanagi","kusanagi","sake","kamikaze","omikuji","omikuji"],
 "Aztec": ["eaglewarrior","eaglewarrior","eaglewarrior","eaglewarrior","eaglewarrior","chimalli","chimalli","aztecseer","aztecseer","xolotl","xolotl","quetzalbird","quetzalbird","huitzilopochtl","tezcatlipoca","quetzalcoatl","dart","dart","dart","maize","tlalocrain","tlalocrain","codex","codex"],
 "Chinese": ["halberdier","halberdier","halberdier","halberdier","halberdier","wudangmonk","wudangmonk","scholar","scholar","lion","lion","vermilionbird","vermilionbird","whitetiger","whitetiger","nezha","azuredragon","heavenlybolt","heavenlybolt","heavenlybolt","peach","arrows","sagescroll","sagescroll"]
}

static func card(id: String) -> Dictionary:
 var result: Dictionary = CARDS[id].duplicate(true)
 result["id"] = id
 return result

static func deck(faction: String) -> Array:
 return DECKS.get(faction,DECKS["Greek"]).duplicate()

const DECK_SIZE = 24
const COPY_LIMITS = {"Common":6,"Uncommon":3,"Rare":3,"Epic":2,"Legendary":2,"Mythic":1}

static func copy_limit(id: String) -> int:
 return COPY_LIMITS.get(CARDS[id].rarity,2)

# Returns an empty string when the deck is legal, otherwise the first problem found.
static func validate_deck(ids: Array) -> String:
 if ids.size() != DECK_SIZE: return "A deck needs exactly %d cards (has %d)." % [DECK_SIZE,ids.size()]
 var counts := {}
 for id in ids:
  if not CARDS.has(id): return "Unknown card: %s." % str(id)
  counts[id] = counts.get(id,0) + 1
  if counts[id] > copy_limit(id): return "%s allows at most %d copies." % [CARDS[id].name,copy_limit(id)]
 return ""

# Card ids in collection order, optionally limited to one pantheon.
static func card_ids(faction: String = "") -> Array:
 var result: Array = []
 for id in CARDS:
  if faction == "" or CARDS[id].faction == faction: result.append(id)
 return result
