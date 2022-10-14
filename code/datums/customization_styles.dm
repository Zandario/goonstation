ABSTRACT_TYPE(/datum/customization_style)
ABSTRACT_TYPE(/datum/customization_style/hair)
ABSTRACT_TYPE(/datum/customization_style/hair/short)
ABSTRACT_TYPE(/datum/customization_style/hair/long)
ABSTRACT_TYPE(/datum/customization_style/hair/hairup)
ABSTRACT_TYPE(/datum/customization_style/hair/gimmick)
ABSTRACT_TYPE(/datum/customization_style/moustache)
ABSTRACT_TYPE(/datum/customization_style/beard)
ABSTRACT_TYPE(/datum/customization_style/sideburns)
ABSTRACT_TYPE(/datum/customization_style/eyebrows)
ABSTRACT_TYPE(/datum/customization_style/makeup)
ABSTRACT_TYPE(/datum/customization_style/biological)


#define FEMININE 1
#define MASCULINE 2

/datum/customization_style/
	var/name = null
	var/id = null
	var/gender = 0
	/// Which mob icon layer this should go on (under or over glasses)
	var/default_layer = MOB_HAIR_LAYER1 //Under by default, more direct subtypes where that makes sense

/datum/customization_style/none
	name = "None"
	id = "none"
	gender = MASCULINE
/datum/customization_style/hair
	default_layer = MOB_HAIR_LAYER2

/datum/customization_style/hair/short/afro
	name = "Afro"
	id = "afro"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/afro_fade
	name = "Afro: Faded"
	id = "afro_fade"
/datum/customization_style/hair/short/afroHR
	name = "Afro: Left Half"
	id = "afroHR"
/datum/customization_style/hair/short/afroHL
	name = "Afro: Right Half"
	id = "afroHL"
/datum/customization_style/hair/short/afroST
	name = "Afro: Top"
	id = "afroST"
/datum/customization_style/hair/short/afroSM
	name = "Afro: Middle Band"
	id = "afroSM"
/datum/customization_style/hair/short/afroSB
	name = "Afro: Bottom"
	id = "afroSB"
/datum/customization_style/hair/short/afroSL
	name = "Afro: Left Side"
	id = "afroSL"
/datum/customization_style/hair/short/afroSR
	name = "Afro: Right Side"
	id = "afroSR"
/datum/customization_style/hair/short/afroSC
	name = "Afro: Center Streak"
	id = "afroSC"
/datum/customization_style/hair/short/afroCNE
	name = "Afro: NE Corner"
	id = "afroCNE"
/datum/customization_style/hair/short/afroCNW
	name = "Afro: NW Corner"
	id = "afroCNW"
/datum/customization_style/hair/short/afroCSE
	name = "Afro: SE Corner"
	id = "afroCSE"
/datum/customization_style/hair/short/afroCSW
	name = "Afro: SW Corner"
	id = "afroCSW"
/datum/customization_style/hair/short/afroSV
	name = "Afro: Tall Stripes"
	id = "afroSV"
/datum/customization_style/hair/short/afroSH
	name = "Afro: Long Stripes"
	id = "afroSH"
/datum/customization_style/hair/short/balding
	name = "Balding"
	id = "balding"
	gender = MASCULINE
/datum/customization_style/hair/short/bangs
	name = "Bangs"
	id = "bangs"
	gender = MASCULINE
/datum/customization_style/hair/short/bieb
	name = "Bieber"
	id = "bieb"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/bloom
	name = "Bloom"
	id = "bloom"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/bobcut
	name = "Bobcut"
	id = "bobcut"
	gender = FEMININE
/datum/customization_style/hair/short/baum_s
	name = "Bobcut Alt"
	id = "baum_s"
	gender = FEMININE
/datum/customization_style/hair/short/bowl
	name = "Bowl Cut"
	id = "bowl"
	gender = MASCULINE
/datum/customization_style/hair/short/cut
	name = "Buzzcut"
	id = "cut"
	gender = MASCULINE
/datum/customization_style/hair/short/clown
	name = "Clown"
	id = "clown"
/datum/customization_style/hair/short/clownT
	name = "Clown: Top"
	id = "clownT"
/datum/customization_style/hair/short/clownM
	name = "Clown: Middle Band"
	id = "clownM"
/datum/customization_style/hair/short/clownB
	name = "Clown: Bottom"
	id = "clownB"
/datum/customization_style/hair/short/combed_s
	name = "Combed"
	id = "combed_s"
	gender = MASCULINE
/datum/customization_style/hair/short/combedbob_s
	name = "Combed Bob"
	id = "combedbob_s"
	gender = FEMININE
/datum/customization_style/hair/short/chop_short
	name = "Choppy Short"
	id = "chop_short"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/einstein
	name = "Einstein"
	id = "einstein"
	gender = MASCULINE
/datum/customization_style/hair/short/einalt
	name = "Einstein: Alternating"
	id = "einalt"
/datum/customization_style/hair/short/emo
	name = "Emo"
	id = "emo"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/emoH
	name = "Emo: Highlight"
	id = "emoH"
/datum/customization_style/hair/short/flattop
	name = "Flat Top"
	id = "flattop"
	gender = MASCULINE
/datum/customization_style/hair/short/flick
	name = "Flick"
	id = "flick"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/flick_fade
	name = "Flick: Faded"
	id = "flick_fade"
/datum/customization_style/hair/short/floof
	name = "Floof"
	id = "floof"
	gender = FEMININE
/datum/customization_style/hair/short/ignite
	name = "Ignite"
	id = "ignite"
	gender = MASCULINE
/datum/customization_style/hair/short/igniteshaved
	name = "Ignite: Shaved"
	id = "igniteshaved"
/datum/customization_style/hair/short/streak
	name = "Hair Streak"
	id = "streak"
/datum/customization_style/hair/short/mohawk
	name = "Mohawk"
	id= "mohawk"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/mohawkFT
	name = "Mohawk: Fade from End"
	id = "mohawkFT"
/datum/customization_style/hair/short/mohawkFB
	name = "Mohawk: Fade from Root"
	id = "mohawkFB"
/datum/customization_style/hair/short/mohawkS
	name = "Mohawk: Stripes"
	id = "mohawkS"
/datum/customization_style/hair/short/mysterious
	name = "Mysterious"
	id = "mysterious"
	gender = FEMININE
/datum/customization_style/hair/short/long
	name = "Mullet"
	id = "long"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/part
	name = "Parted Hair"
	id = "part"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/pomp
	name = "Pompadour"
	id = "pomp"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/pompS
	name = "Pompadour: Greaser Shine"
	id = "pompS"
/datum/customization_style/hair/short/scruffy
	name = "Scruffy"
	id = "scruffy"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/shavedhead
	name = "Shaved Head"
	id = "shavedhead"
/datum/customization_style/hair/short/shortflip
	name = "Punky Flip"
	id = "shortflip"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/sparks
	name = "Sparks"
	id = "sparks"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/spiky
	name = "Spiky"
	id = "spiky"
	gender = MASCULINE
/datum/customization_style/hair/short/subtlespiky
	name = "Subtle Spiky"
	id = "subtlespiky"
	gender = MASCULINE
/datum/customization_style/hair/short/temsik
	name = "Temsik"
	id = "temsik"
	gender = MASCULINE
/datum/customization_style/hair/short/tonsure
	name = "Tonsure"
	id = "tonsure"
	gender = MASCULINE
/datum/customization_style/hair/short/short
	name = "Trimmed"
	id = "short"
	gender = MASCULINE
/datum/customization_style/hair/short/tulip
	name = "Tulip"
	id = "tulip"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/short/visual
	name = "Visual"
	id = "visual"
	gender = MASCULINE
/datum/customization_style/hair/short/combedfront
	name = "Combed Front"
	id = "combedfront"
/datum/customization_style/hair/short/combedfrontshort
	name = "Combed Front Short"
	id = "combedfrontshort"
/datum/customization_style/hair/short/longfront
	name = "Long Front"
	id = "longfront"

/datum/customization_style/hair/long/chub2_s
	name = "Bang: Left"
	id = "chub2_s"
/datum/customization_style/hair/long/chub_s
	name = "Bang: Right"
	id = "chub_s"
/datum/customization_style/hair/long/twobangs_long
	name = "Two Bangs: Long"
	id = "2bangs_long"
/datum/customization_style/hair/long/twobangs_short
	name = "Two Bangs: Short"
	id = "2bangs_short"
/datum/customization_style/hair/long/flatbangs
	name = "Bangs: Flat"
	id = "flatbangs"
/datum/customization_style/hair/long/shortflatbangs
	name = "Bangs: Flat Shorter"
	id = "shortflatbangs"
/datum/customization_style/hair/long/longwavebangs
	name = "Bangs: Long Wavy"
	id = "longwavebangs"
/datum/customization_style/hair/long/shortwavebangs
	name = "Bangs: Short Wavy"
	id = "shortwavebangs"
/datum/customization_style/hair/long/sidebangs
	name = "Bangs: Sides"
	id = "sidebangs"
/datum/customization_style/hair/long/mysterybangs
	name = "Bangs: Mysterious"
	id = "mysterybangs"
/datum/customization_style/hair/long/bedhead
	name = "Bedhead"
	id = "bedhead"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/breezy
	name = "Breezy"
	id = "breezy"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/breezy_fade
	name = "Breezy: Faded"
	id = "breezy_fade"
/datum/customization_style/hair/long/disheveled
	name = "Disheveled"
	id = "disheveled"
	gender = FEMININE
/datum/customization_style/hair/long/doublepart
	name = "Double-Part"
	id = "doublepart"
/datum/customization_style/hair/long/shoulders
	name = "Draped"
	id = "shoulders"
	gender = FEMININE
/datum/customization_style/hair/long/dreads
	name = "Dreadlocks"
	id = "dreads"
	gender = MASCULINE
/datum/customization_style/hair/long/dreadsA
	name = "Dreadlocks: Alternating"
	id = "dreadsA"
/datum/customization_style/hair/long/fabio
	name = "Fabio"
	id = "fabio"
	gender = FEMININE
/datum/customization_style/hair/long/glammetal
	name = "Glammetal"
	id = "glammetal"
	gender = FEMININE
/datum/customization_style/hair/long/glammetalO
	name = "Glammetal: Faded"
	id = "glammetalO"
/datum/customization_style/hair/long/eighties
	name = "Hairmetal"
	id = "80s"
	gender = FEMININE
/datum/customization_style/hair/long/eightiesfade
	name = "Hairmetal: Faded"
	id = "80sfade"
/datum/customization_style/hair/long/halfshavedR
	name = "Half-Shaved: Left"
	id = "halfshavedR"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/halfshaved_s
	name = "Half-Shaved: Long"
	id = "halfshaved_s"
	gender = FEMININE
/datum/customization_style/hair/long/halfshavedL
	name = "Half-Shaved: Right"
	id = "halfshavedL"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/kingofrockandroll
	name = "Kingmetal"
	id = "king-of-rock-and-roll"
	gender = MASCULINE
/datum/customization_style/hair/long/froofy_long
	name = "Long and Froofy"
	id = "froofy_long"
	gender = FEMININE
/datum/customization_style/hair/long/lionsmane
	name = "Lionsmane"
	id = "lionsmane"
	gender = MASCULINE
/datum/customization_style/hair/long/lionsmane_fade
	name = "Lionsmane: Faded"
	id = "lionsmane_fade"
/datum/customization_style/hair/long/pinion
	name = "Pinion"
	id = "pinion"
	gender = MASCULINE
/datum/customization_style/hair/long/longbraid
	name = "Long Braid"
	id = "longbraid"
	gender = FEMININE
/datum/customization_style/hair/long/looselongbraid
	name = "Loose Long Braid"
	id = "looselongbraid"
	gender = FEMININE
/datum/customization_style/hair/long/looselongbraidtwincolor
	name = "Loose Long Braid: Twin Color"
	id = "looselongbraidfaded"
	gender = FEMININE
/datum/customization_style/hair/long/looselongbraidshoulder
	name = "Loose Long Braid Over Shoulder"
	id = "looselongbraidshoulder"
	gender = FEMININE
/datum/customization_style/hair/long/longsidepart_s
	name = "Long Flip"
	id = "longsidepart_s"
	gender = FEMININE
/datum/customization_style/hair/long/longwaves
	name = "Waves"
	id = "longwaves"
	gender = FEMININE
/datum/customization_style/hair/long/longwaves_fade
	name = "Waves: Faded"
	id = "longwaves_fade"
/datum/customization_style/hair/long/pulledb
	name = "Pulled Back"
	id = "pulledb"
	gender = FEMININE
/datum/customization_style/hair/long/ripley
	name = "Ripley"
	id = "ripley"
	gender = FEMININE
/datum/customization_style/hair/long/ripley_fade
	name = "Ripley: Faded"
	id = "ripley_fade"
/datum/customization_style/hair/long/sage
	name = "Sage"
	id = "sage"
	gender = FEMININE
/datum/customization_style/hair/long/scraggly
	name = "Scraggly"
	id = "scraggly"
	gender = MASCULINE
/datum/customization_style/hair/long/pulledf
	name = "Shoulder Drape"
	id = "pulledf"
	gender = FEMININE
/datum/customization_style/hair/long/shoulderl
	name = "Shoulder-Length"
	id = "shoulderl"
	gender = FEMININE
/datum/customization_style/hair/long/slightlymess_s
	name = "Shoulder-Length Mess"
	id = "slightlymessy_s"
	gender = FEMININE
/datum/customization_style/hair/long/smoothwave
	name = "Smooth Waves"
	id = "smoothwave"
	gender = FEMININE
/datum/customization_style/hair/long/smoothwave_fade
	name = "Smooth Waves: Faded"
	id = "smoothwave_fade"
/datum/customization_style/hair/long/mermaid
	name = "Mermaid"
	id = "mermaid"
	gender = FEMININE
/datum/customization_style/hair/long/mermaidfade
	name = "Mermaid: Faded"
	id = "mermaidfade"
/datum/customization_style/hair/long/midb
	name = "Mid-Back Length"
	id = "midb"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/bluntbangs_s
	name = "Mid-Length Curl"
	id = "bluntbangs_s"
	gender = FEMININE
/datum/customization_style/hair/long/vlong
	name = "Very Long"
	id = "vlong"
	gender = FEMININE
/datum/customization_style/hair/long/violet
	name = "Violet"
	id = "violet"
	gender = FEMININE
/datum/customization_style/hair/long/violet_fade
	name = "Violet: Faded"
	id = "violet_fade"
/datum/customization_style/hair/long/willow
	name = "Willow"
	id = "willow"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/long/willow_fade
	name = "Willow: Faded"
	id = "willow_fade"

/datum/customization_style/hair/hairup/bun
	name = "Bun"
	id = "bun"
	gender = FEMININE
/datum/customization_style/hair/hairup/bundercut
	name = "Bun Undercut"
	id = "bundercut"
	gender = MASCULINE
/datum/customization_style/hair/hairup/sakura
	name = "Captor"
	id = "sakura"
	gender = FEMININE
/datum/customization_style/hair/hairup/croft
	name = "Croft"
	id = "croft"
	gender = FEMININE
/datum/customization_style/hair/hairup/indian
	name = "Double Braids"
	id = "indian"
	gender = FEMININE
/datum/customization_style/hair/hairup/doublebun
	name = "Double Buns"
	id = "doublebun"
	gender = FEMININE
/datum/customization_style/hair/hairup/drill
	name = "Drill"
	id = "drill"
/datum/customization_style/hair/hairup/fun_bun
	name = "Fun Bun"
	id = "fun_bun"
	gender = FEMININE
/datum/customization_style/hair/hairup/charioteers
	name = "High Flat Top"
	id = "charioteers"
	gender = MASCULINE
/datum/customization_style/hair/hairup/spud
	name = "High Ponytail"
	id = "spud"
	gender = FEMININE
/datum/customization_style/hair/hairup/longtailed
	name = "Long Mini Tail"
	id = "longtailed"
	gender = FEMININE
/datum/customization_style/hair/hairup/longtwintail
	name = "Long Twin Tails"
	id = "longtwintail"
	gender = FEMININE
/datum/customization_style/hair/hairup/glamponytail
	name = "Glam Ponytail"
	id = "glamponytail"
/datum/customization_style/hair/hairup/rockponytail
	name = "Rock Ponytail"
	id = "rockponytail"
	gender = FEMININE
/datum/customization_style/hair/hairup/rockponytail_fade
	name = "Rock Ponytail: Faded"
	id = "rockponytail_fade"
/datum/customization_style/hair/hairup/spikyponytail
	name = "Spiky Ponytail"
	id = "spikyponytail"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/hairup/messyponytail
	name = "Messy Ponytail"
	id = "messyponytail"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/hairup/untidyponytail
	name = "Untidy Ponytail"
	id = "untidyponytail"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/hairup/lowpig
	name = "Low Pigtails"
	id = "lowpig"
	gender = FEMININE
/datum/customization_style/hair/hairup/band
	name = "Low Ponytail"
	id = "band"
	gender = FEMININE
/datum/customization_style/hair/hairup/minipig
	name = "Mini Pigtails"
	id = "minipig"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/hairup/pig
	name = "Pigtails"
	id = "pig"
	gender = FEMININE
/datum/customization_style/hair/hairup/pompompigtail
	name = "Pompom Pigtails"
	id = "pompompigtail"
	gender = FEMININE
/datum/customization_style/hair/hairup/ponytail
	name = "Ponytail"
	id = "ponytail"
	gender = MASCULINE | FEMININE
/datum/customization_style/hair/hairup/geisha_s
	name = "Shimada"
	id = "geisha_s"
	gender = FEMININE
/datum/customization_style/hair/hairup/twotail
	name = "Split-Tails"
	id = "twotail"
	gender = MASCULINE
/datum/customization_style/hair/hairup/wavy_tail
	name = "Wavy Ponytail"
	id = "wavy_tail"
	gender = FEMININE

/datum/customization_style/hair/gimmick/afroHA
	name = "Afro: Alternating Halves"
	id = "afroHA"
/datum/customization_style/hair/gimmick/afroRB
	name = "Afro: Rainbow"
	id = "afroRB"
/datum/customization_style/hair/gimmick/bart
	name = "Bart"
	id = "bart"
/datum/customization_style/hair/gimmick/ewave_s
	name = "Elegant Wave"
	id = "ewave_s"
/datum/customization_style/hair/gimmick/flames
	name = "Flame Hair"
	id = "flames"
/datum/customization_style/hair/gimmick/goku
	name = "Goku"
	id = "goku"
/datum/customization_style/hair/gimmick/homer
	name = "Homer"
	id = "homer"
/datum/customization_style/hair/gimmick/jetson
	name = "Jetson"
	id = "jetson"
/datum/customization_style/hair/gimmick/sailor_moon
	name = "Sailor Moon"
	id = "sailor_moon"
/datum/customization_style/hair/gimmick/sakura
	name = "Sakura"
	id = "sakura"
/datum/customization_style/hair/gimmick/wiz
	name = "Wizard"
	id = "wiz"
/datum/customization_style/hair/gimmick/xcom
	name = "X-COM Rookie"
	id = "xcom"
/datum/customization_style/hair/gimmick/zapped
	name = "Zapped"
	id = "zapped"
/datum/customization_style/hair/gimmick/shitty_hair
	name = "Shitty Hair"
	id = "shitty_hair"
/datum/customization_style/hair/gimmick/shitty_beard
	name = "Shitty Beard"
	id = "shitty_beard"
/datum/customization_style/hair/gimmick/shitty_beard_stains
	name = "Shitty Beard Stains"
	id = "shitty_beard_stains"

/datum/customization_style/moustache/fu
	name = "Biker"
	id = "fu"
/datum/customization_style/moustache/chaplin
	name = "Chaplin"
	id = "chaplin"
/datum/customization_style/moustache/dali
	name = "Dali"
	id = "dali"
/datum/customization_style/moustache/hogan
	name = "Hogan"
	id = "hogan"
/datum/customization_style/moustache/devil
	name = "Old Nick"
	id = "devil"
/datum/customization_style/moustache/robo
	name = "Robotnik"
	id = "robo"
/datum/customization_style/moustache/selleck
	name = "Selleck"
	id = "selleck"
/datum/customization_style/moustache/villain
	name = "Twirly"
	id = "villain"
/datum/customization_style/moustache/vandyke
	name = "Van Dyke"
	id = "vandyke"
/datum/customization_style/moustache/watson
	name = "Watson"
	id = "watson"

/datum/customization_style/beard/abe
	name = "Abe"
	id = "abe"
/datum/customization_style/beard/bstreak
	name = "Beard Streaks"
	id = "bstreak"
/datum/customization_style/beard/braided
	name = "Braided Beard"
	id = "braided"
/datum/customization_style/beard/chin
	name = "Chinstrap"
	id = "chin"
/datum/customization_style/beard/fullbeard
	name = "Full Beard"
	id = "fullbeard"
/datum/customization_style/beard/fiveoclock
	name = "Five O'Clock Shadow"
	id = "fiveoclock"
/datum/customization_style/beard/gt
	name = "Goatee"
	id = "gt"
/datum/customization_style/beard/hip
	name = "Hipster"
	id = "hip"
/datum/customization_style/beard/longbeard
	name = "Long Beard"
	id = "longbeard"
/datum/customization_style/beard/longbeardfade
	name = "Long Beard: Faded"
	id = "longbeardfade"
/datum/customization_style/beard/motley
	name = "Motley"
	id = "motley"
/datum/customization_style/beard/neckbeard
	name = "Neckbeard"
	id = "neckbeard"
/datum/customization_style/beard/puffbeard
	name = "Puffy Beard"
	id = "puffbeard"
/datum/customization_style/beard/tramp
	name = "Tramp"
	id = "tramp"
/datum/customization_style/beard/trampstains
	name = "Tramp: Beard Stains"
	id = "trampstains"

/datum/customization_style/sideburns/elvis
	name = "Elvis"
	id = "elvis"

/datum/customization_style/eyebrows/eyebrows
	name = "Eyebrows"
	id = "eyebrows"
/datum/customization_style/eyebrows/thufir
	name = "Huge Eyebrows"
	id  = "thufir"

/datum/customization_style/makeup/eyeshadow
	name = "Eyeshadow"
	id = "eyeshadow"
/datum/customization_style/makeup/lipstick
	name = "Lipstick"
	id = "lipstick"

/datum/customization_style/biological/hetcroL
	name = "Heterochromia: Left"
	id = "hetcroL"
/datum/customization_style/biological/hetcroR
	name = "Heterochromia: Right"
	id = "hetcroR"

/proc/select_custom_style(list/datum/customization_style/customization_types, mob/living/carbon/human/user as mob)
	var/list/datum/customization_style/options = list()
	for (var/datum/customization_style/styletype as anything in customization_types)
		var/datum/customization_style/CS = new styletype
		options[CS.name] = CS
	var/new_style = tgui_input_list(user, "Please select style", "Style", options)
	return options[new_style]

/proc/find_style_by_name(target_name)
	for (var/datum/customization_style/styletype as anything in concrete_typesof(/datum/customization_style))
		var/datum/customization_style/CS = new styletype
		if(CS.name == target_name)
			return CS
	return new /datum/customization_style/none

/proc/find_style_by_id(target_id)
	for (var/datum/customization_style/styletype as anything in concrete_typesof(/datum/customization_style))
		var/datum/customization_style/CS = new styletype
		if(CS.id == target_id)
			return CS
	return new /datum/customization_style/none
