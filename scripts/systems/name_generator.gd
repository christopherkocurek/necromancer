class_name NameGenerator
## Generates lore-accurate names for player characters based on race, house, and gender.
## Name banks are organized by race + house combination, with separate male/female lists.

# Name banks organized by race + house key
# Keys: "Race_House" or just "Race" for races without house-specific banks
static var name_banks: Dictionary = {
	# === ELF HOUSES ===
	# Lothlorien: Sindarin/Silvan names - woodland elves of the Golden Wood
	"Elf_Lothlorien": {
		"male": [
			"Haldir", "Rumil", "Orophin", "Celeborn", "Amroth", "Galathil",
			"Amdir", "Calanon", "Thaladon", "Mirion", "Galion", "Celegorn",
			"Amdil", "Nimion", "Laeron", "Tauren", "Galadhor", "Silvan"
		],
		"female": [
			"Galadriel", "Nimrodel", "Celebrian", "Nerdanel", "Aredhel",
			"Earwen", "Morwen", "Nellas", "Miriel", "Idril", "Amarie",
			"Lalwen", "Silinde", "Eleniel", "Galadwen", "Lorien"
		]
	},
	# Rivendell: Noldorin/Sindarin names - the Last Homely House
	"Elf_Rivendell": {
		"male": [
			"Elrond", "Elladan", "Elrohir", "Erestor", "Lindir", "Gildor",
			"Glorfindel", "Celebrimbor", "Finrod", "Turgon", "Fingolfin",
			"Maglor", "Cirdan", "Voronwe", "Ecthelion", "Egalmoth",
			"Pengolodh", "Salgant"
		],
		"female": [
			"Arwen", "Celebrian", "Idril", "Aredhel", "Finduilas", "Elwing",
			"Nerdanel", "Miriel", "Galadriel", "Earwen", "Anaire",
			"Lalwen", "Amarie", "Irime", "Indis", "Elenwe"
		]
	},
	# Mirkwood/Greenwood: Silvan/Sindarin names - forest-dwelling elves
	"Elf_Greenwood": {
		"male": [
			"Legolas", "Thranduil", "Galion", "Oropher", "Beleg", "Mablung",
			"Daeron", "Saeros", "Amdir", "Calanon", "Feredir", "Thandir",
			"Belegorn", "Laegon", "Taurion", "Celebren", "Edhelen", "Maethor"
		],
		"female": [
			"Tauriel", "Nimrodel", "Nellas", "Luthien", "Morwen", "Rian",
			"Gilwen", "Silivren", "Tawariel", "Meliniel", "Galadwen",
			"Brethilwen", "Aerlinn", "Nariel", "Lalaith", "Elanor"
		]
	},

	# === MAN HOUSES ===
	# Gondor: Numenorean/Sindarin names - soldiers of the White Tower
	"Man_Gondor": {
		"male": [
			"Boromir", "Faramir", "Denethor", "Beregond", "Bergil", "Imrahil",
			"Angbor", "Dervorin", "Duinhir", "Forlong", "Golasgil", "Hirluin",
			"Mardil", "Thorongil", "Ecthelion", "Turgon", "Belecthor",
			"Cirion", "Earnil"
		],
		"female": [
			"Finduilas", "Morwen", "Ioreth", "Gilraen", "Lothiriel", "Ivorwen",
			"Firiel", "Miriel", "Beruthiel", "Ancalime", "Telperiel",
			"Silmarien", "Lindorie", "Inzilbeth", "Erendis", "Almarian"
		]
	},
	# Rohan: Anglo-Saxon style names - the horse-lords
	"Man_Rohan": {
		"male": [
			"Theoden", "Eomer", "Eomund", "Theodred", "Elfhelm", "Gamling",
			"Grimbold", "Hama", "Erkenbrand", "Helm", "Aldor", "Brytta",
			"Deor", "Folcwine", "Frealaf", "Brego", "Baldor", "Ceorl",
			"Dunhere", "Guthlaf"
		],
		"female": [
			"Eowyn", "Morwen", "Elfhild", "Theodwyn", "Goldwyn", "Hild",
			"Leofwyn", "Aelfwyn", "Freda", "Brynja", "Wulfhild", "Hereswith",
			"Saelind", "Garwyn", "Cynewyn", "Elswith"
		]
	},
	# Dunedain: Sindarin names with Ar- prefix tradition - Rangers of the North
	"Man_Dunedain": {
		"male": [
			"Aragorn", "Arathorn", "Halbarad", "Dirhael", "Arador", "Argonui",
			"Aravorn", "Arvedui", "Isildur", "Valandil", "Elendil", "Anarion",
			"Arvegil", "Argeleb", "Araphant", "Malvegil", "Celepharn",
			"Mallor", "Beleg"
		],
		"female": [
			"Gilraen", "Ivorwen", "Firiel", "Silmarien", "Miriel", "Beruthiel",
			"Erendis", "Almarian", "Lindorie", "Inzilbeth", "Ancalime",
			"Telperiel", "Vanimalda", "Tar-Miriel", "Haleth", "Andreth"
		]
	},

	# === DWARF ===
	# Dwarves use Norse-inspired names from the Dvergatal
	# All dwarf houses share a name pool (no house-specific banks needed)
	"Dwarf": {
		"male": [
			"Gimli", "Gloin", "Thorin", "Balin", "Dwalin", "Fili", "Kili",
			"Oin", "Ori", "Nori", "Dori", "Bifur", "Bofur", "Bombur",
			"Dain", "Nain", "Thror", "Thrain", "Fundin", "Durin",
			"Farin", "Gror", "Borin", "Loni", "Nali", "Frar"
		],
		"female": [
			"Dis", "Mili", "Groa", "Jari", "Vari", "Thrud", "Grima",
			"Hild", "Bruni", "Vigdis", "Frida", "Audr", "Dagny",
			"Gudrun", "Sigrid", "Thyra"
		]
	},

	# === HOBBIT ===
	# Hobbits use English country names
	# All hobbit houses share a name pool
	"Hobbit": {
		"male": [
			"Bilbo", "Frodo", "Samwise", "Meriadoc", "Peregrin", "Hamfast",
			"Bandobras", "Drogo", "Otho", "Lotho", "Fredegar", "Folco",
			"Paladin", "Saradoc", "Gerontius", "Bungo", "Hugo", "Ponto",
			"Largo", "Mungo", "Isengrim", "Hildifons", "Adelard", "Rorimac"
		],
		"female": [
			"Rosie", "Lobelia", "Belladonna", "Primula", "Elanor", "Estella",
			"Diamond", "Pearl", "Daisy", "Poppy", "Ruby", "Esmeralda",
			"Pervinca", "Amaranth", "Myrtle", "Camellia", "Pansy", "Angelica"
		]
	},
}


static func _normalize_house(house: String) -> String:
	## Strip common prefixes from house alternate names for key lookup.
	## "the Dunedain" -> "Dunedain", "the Shire" -> "Shire", etc.
	var h: String = house.strip_edges()
	if h.begins_with("the "):
		h = h.substr(4)
	return h


static func get_random_name(race: String, house: String, gender: String) -> String:
	## Return a random name appropriate for the given race, house, and gender.
	## Falls back to race-only if no house-specific bank exists.
	var normalized_house: String = _normalize_house(house)
	var key: String = race + "_" + normalized_house
	# Fall back to race-only key if no house-specific bank
	if key not in name_banks:
		key = race
	if key not in name_banks:
		return "Stranger"

	var bank: Dictionary = name_banks[key]
	var names: Array = bank.get(gender, bank.get("male", ["Unknown"]))
	return names.pick_random()


static func get_all_names_for(race: String, house: String, gender: String) -> Array:
	## Return the full name list for a given race/house/gender combo.
	var normalized_house: String = _normalize_house(house)
	var key: String = race + "_" + normalized_house
	if key not in name_banks:
		key = race
	if key not in name_banks:
		return []

	var bank: Dictionary = name_banks[key]
	return bank.get(gender, bank.get("male", []))
