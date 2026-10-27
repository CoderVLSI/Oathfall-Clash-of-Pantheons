class_name PlayerProfile
extends RefCounted

const DB = preload("res://scripts/card_database.gd")
const STAGES = 6
const STAGE_LEVELS = [0,1,1,2,2,2]
const STAGE_TITLES = ["Initiate's Trial","Warband Skirmish","Pantheon Rivalry","Champion's Duel","Gauntlet of Legends","Trial of the Mythic"]
const DECK_SLOTS = 3
const DIFFICULTY_NAMES = ["EASY","NORMAL","HARD"]

var wins := 0
var games := 0
var muted := false
var difficulty := 1
var xp := 0
var campaign := {}      # faction -> highest stage cleared (0..STAGES)
var faction_wins := {}  # faction -> victories
var decks := {}         # slot index (as string) -> {"name": String, "cards": Array}

func level() -> int:
 return 1 + int((sqrt(1.0 + 8.0 * xp / 100.0) - 1.0) / 2.0)

# XP required to reach the next level, and progress toward it.
func level_progress() -> Dictionary:
 var lv := level()
 var floor_xp := 50 * lv * (lv - 1)
 var next_xp := 50 * (lv + 1) * lv
 return {"level":lv,"into":xp - floor_xp,"needed":next_xp - floor_xp}

func stage_cleared(faction: String) -> int:
 return int(campaign.get(faction,0))

# The ordered rivals for a pantheon's campaign: every other pantheon, the last as the boss.
func campaign_rivals(faction: String) -> Array:
 var others: Array = DB.FACTIONS.filter(func(f): return f != faction)
 return others

func stage_info(faction: String, stage: int) -> Dictionary:
 var rivals := campaign_rivals(faction)
 var index := clampi(stage - 1,0,STAGES - 1)
 return {"stage":index + 1,"rival":rivals[index],"level":STAGE_LEVELS[index],"title":STAGE_TITLES[index],"bonus_hp":5 if index == STAGES - 1 else 0}

func stage_unlocked(faction: String, stage: int) -> bool:
 return stage >= 1 and stage <= STAGES and stage <= stage_cleared(faction) + 1

# Records a finished match and returns the XP awarded. stage is 0 for a casual duel.
func record_result(faction: String, won: bool, ai_level: int, stage: int = 0) -> int:
 games += 1
 var gained := 30
 if won:
  wins += 1
  faction_wins[faction] = int(faction_wins.get(faction,0)) + 1
  gained = 100 + 25 * ai_level
  if stage > 0 and stage > stage_cleared(faction):
   campaign[faction] = stage
   gained += 150 + 50 * stage
 xp += gained
 return gained

func save_deck(slot: int, deck_name: String, cards: Array) -> bool:
 if slot < 0 or slot >= DECK_SLOTS or DB.validate_deck(cards) != "": return false
 decks[str(slot)] = {"name":deck_name,"cards":cards.duplicate()}
 return true

func deck_in_slot(slot: int) -> Dictionary:
 return decks.get(str(slot),{})

func achievements() -> Array:
 var cleared_any := false
 var all_factions := true
 for f in DB.FACTIONS:
  if stage_cleared(f) >= STAGES: cleared_any = true
  if int(faction_wins.get(f,0)) < 1: all_factions = false
 return [
  {"id":"first_win","name":"First Oath","text":"Win a duel.","done":wins >= 1},
  {"id":"ten_wins","name":"Seasoned Duelist","text":"Win 10 duels.","done":wins >= 10},
  {"id":"all_pantheons","name":"Voice of Every Pantheon","text":"Win with all seven pantheons.","done":all_factions},
  {"id":"campaign","name":"Trial Complete","text":"Clear a full pantheon campaign.","done":cleared_any},
  {"id":"deckbuilder","name":"Architect of Myth","text":"Save a custom deck.","done":not decks.is_empty()},
  {"id":"level_5","name":"Rising Legend","text":"Reach player level 5.","done":level() >= 5}
 ]

func load_from(path: String) -> void:
 var config := ConfigFile.new()
 if config.load(path) != OK: return
 wins = int(config.get_value("record","wins",0))
 games = int(config.get_value("record","games",0))
 xp = int(config.get_value("record","xp",0))
 campaign = config.get_value("record","campaign",{})
 faction_wins = config.get_value("record","faction_wins",{})
 muted = bool(config.get_value("settings","muted",false))
 difficulty = clampi(int(config.get_value("settings","difficulty",1)),0,2)
 var stored = config.get_value("decks","slots",{})
 decks = {}
 if stored is Dictionary:
  for key in stored:
   var entry = stored[key]
   if entry is Dictionary and entry.has("cards") and DB.validate_deck(entry.cards) == "": decks[str(key)] = entry

func save_to(path: String) -> void:
 var config := ConfigFile.new()
 config.set_value("record","wins",wins)
 config.set_value("record","games",games)
 config.set_value("record","xp",xp)
 config.set_value("record","campaign",campaign)
 config.set_value("record","faction_wins",faction_wins)
 config.set_value("settings","muted",muted)
 config.set_value("settings","difficulty",difficulty)
 config.set_value("decks","slots",decks)
 config.save(path)
