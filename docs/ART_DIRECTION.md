# First Age asset manifest

Tool: built-in ImageGen, no external image API credentials. Images are project-local PNGs; editable text is rendered by Godot. All generation prompts request painted 2D illustrations rather than 3D renders.

## Shared prompt direction

Premium hand-painted mythology TCG, antique gold and midnight navy, atmospheric lighting, crisp silhouettes readable at card size. Portrait assets are individual 2:3 compositions with no borders, text, or watermark. The reusable frame has transparent outside margins and a transparent artwork opening, separate blank plaques and statistic sockets.

## Prompt set and saved assets

- `assets/backgrounds/menu.png`: wide ancient sanctuary where Greek marble architecture meets snowy Norse mountains, celestial gate on the right, quiet dark space on the left for title and navigation.
- `assets/backgrounds/battlefield.png`: flat top-down dark stone altar, gold celestial inlays, Greek lower edge and Norse upper edge, quiet playing surface with no cards or text.
- `assets/ui/icons.png`: transparent 3×2 atlas; cyan Power crystal, gold crossed attack swords, ruby health heart, Guard shield, spell lightning, card deck. Texture regions are used directly without destructive crops.
- `assets/cards/frames/master_frame_concept_v1.png`: neutral ancient gold, bronze, and charcoal frame, large transparent art window, parchment rules panel, blank name and number sockets. Border rim colors distinguish rarities.
- `assets/cards/frames/epic_purple_v1.png`: ImageGen edit of the master; replace all golden metal with rich amethyst purple and lilac highlights, preserve plaque/socket geometry, charcoal, ivory parchment, and alpha. Epic cards use this purple frame. Legendary cards use the golden master frame.
- `assets/cards/art/zeus.png`: silver-bearded Greek sky god, ivory and gold armor, branching lightning, storm-lit Olympus.
- `assets/cards/art/poseidon.png`: Greek sea god, dark teal hair, bronze armor, luminous trident, ocean and submerged marble.
- `assets/cards/art/cerberus.png`: three-headed black hound, bronze collars, ancient underworld gateway, violet fire.
- `assets/cards/art/hoplite.png`: mortal Greek soldier, bronze helmet and red crest, round shield and spear, marble fortress.
- `assets/cards/art/thor.png`: red-bearded Norse thunder god, iron and fur armor, rune hammer, snowy lightning storm.
- `assets/cards/art/valkyrie.png`: armored Norse warrior woman, winged helmet, spear and blue shield, snowy aurora.
- `assets/cards/art/fenrir.png`: colossal dark wolf, pale blue eyes, broken rune chains, moonlit snow.
- `assets/cards/art/raider.png`: mortal Norse warrior, braided beard, chainmail and fur, axe and round shield, fjord and longship.
- `assets/cards/card_back.png`: universal full-bleed portrait navy enamel back, gold celestial oath rings around a turquoise rift, exact title “OATHFALL” and subtitle “CLASH OF PANTHEONS”. Shared by all cards and factions.
- `assets/ui/app_icon.png`: square gold broken oath ring around a turquoise rift, midnight navy background, no text, centered safe zone.
- `assets/ui/app_icon_v2.png`: new phone launcher icon for v0.1.1; bold broken-gold oath ring, sharply defined teal lightning rift, restrained card silhouette on navy, no text. Generated with built-in ImageGen; original icon preserved.

Spells currently reuse related deity/character portraits. Rarity, cost, name, concise on-card summaries, full inspected rules, and current combat statistics remain live UI layers.
