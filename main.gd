extends Node2D

@onready var input_panel = $InputPanel
@onready var banned = $InputPanel/ban_words
@onready var msg_box = $InputPanel/input
@onready var raw = $InputPanel/rawmsg
@onready var btn = $InputPanel/send
@onready var tab = $InputPanel/writing_tab
@onready var npc_text = $InputPanel/NPCINT
@onready var prev = $InputPanel/prevNPC
@onready var prev_icon = $InputPanel/prevNPC/previcon
@onready var prev_msg = $InputPanel/prevNPC/prevmsg
@onready var prev_bubble = $InputPanel/prevNPC/prev_bubble

@onready var card = $Card
@onready var card_bg = $Card/CardBG
@onready var personality = $Card/personality

@onready var results = $Node2D
@onready var score = $Node2D/score
@onready var retry = $Node2D/restart

const messages = [
	{
		"text": "The King's wine will be poisoned at tonight's feast. Warn him before midnight.",
		"banned": ["poison", "wine", "kill", "death", "midnight", "feast"]
	},
	{
		"text": "An assassin hides among the royal guards. The King must not attend the ceremony.",
		"banned": ["assassin", "guard", "kill", "murder", "ceremony", "royal"]
	},
	{
		"text": "The Queen's necklace contains a deadly trap. Remove it before sunset.",
		"banned": ["trap", "deadly", "necklace", "queen", "kill", "sunset"]
	},
	{
		"text": "Enemy spies have infiltrated the castle kitchen. Do not eat the bread.",
		"banned": ["spy", "enemy", "poison", "bread", "kitchen", "infiltrate"]
	},
	{
		"text": "The bridge will collapse at dawn. The King must take the forest path.",
		"banned": ["collapse", "bridge", "danger", "dawn", "destroy", "fall"]
	},
]

const npcs = [
	{
		"name": "The Merchant",
		"personality": "A shrewd traveling trader.\n\nSees profit in everything. Turns messages into business opportunities. Exaggerates value and worth.",
		"frame": "res://image/merchant_frame.png",
		"icon": "res://image/merchant.png"
	},
	{
		"name": "The Boy",
		"personality": "A curious 7-year-old messenger.\n\nThinks everything is a game. Uses baby words. Turns scary things into silly adventures.",
		"frame": "res://image/boy_frame.png",
		"icon": "res://image/boy.png"
	},
	{
		"name": "The Guard",
		"personality": "A paranoid palace guard.\n\nSees threats everywhere. Uses military language. Suspects everyone of treason.",
		"frame": "res://image/guard_frame.png",
		"icon": "res://image/guard.png"
	},
	{
		"name": "The Drunk",
		"personality": "The town's happiest tavern regular.\n\nSlurs every other word. Forgets mid-sentence. Adds 'hic!' randomly.",
		"frame": "res://image/drunk_frame.png",
		"icon": "res://image/drunk.png"
	},
	{
		"name": "The Scholar",
		"personality": "A wise but confusing academic.\n\nOvercomplicates everything. Uses big words nobody understands. Adds unnecessary details.",
		"frame": "res://image/scholar_frame.png",
		"icon": "res://image/scholar.png"
	},
]

const api_url = "https://ai.hackclub.com/proxy/v1/chat/completions"
const api_key = "sk-hc-v1-59b7cc0ad92147a2881b6826f986ecccb13db1c5d63c49cb8deb918da49abc62"
var http: HTTPRequest

enum state { input, waiting, showing, done }
var mode: state = state.input

var current_msg: Dictionary = {}
var raw_text: String = ""
var banned_words: Array = []
var player_text: String = ""
var npc_pos: int = 0
var chain: Array = []
var king: Dictionary = {}

var typer: Label = null
var typer_txt: String = ""
var typer_at: int = 0
var typer_spd: float = 0.035
var typer_time: float = 0.0
var is_typing: bool = false

signal typing_finished

var cursor_on: bool = true
var cursor_time: float = 0.0
var cursor_spd: float = 0.4
var wait_cursor: bool = false

var tween_card: Tween = null

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(on_response)
	
	btn.pressed.connect(on_btn)
	retry.pressed.connect(restart)
	
	raw.autowrap_mode = TextServer.AUTOWRAP_WORD
	banned.autowrap_mode = TextServer.AUTOWRAP_WORD
	personality.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	score.autowrap_mode = TextServer.AUTOWRAP_WORD
	npc_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	start_input()

func _process(delta):
	if is_typing:
		typer_time += delta
		while typer_time >= typer_spd and typer_at < typer_txt.length():
			typer_time -= typer_spd
			typer_at += 1
			typer.text = typer_txt.substr(0, typer_at) + "▌"
		
		if typer_at >= typer_txt.length():
			is_typing = false
			typer.text = typer_txt
			typing_finished.emit()
	
	if wait_cursor:
		cursor_time += delta
		if cursor_time >= cursor_spd:
			cursor_time = 0.0
			cursor_on = !cursor_on
			npc_text.text = "▌" if cursor_on else ""

func type(lbl: Label, txt: String):
	typer = lbl
	typer_txt = txt
	typer_at = 0
	typer_time = 0.0
	is_typing = true
	lbl.text = "▌"

func cursor_start():
	wait_cursor = true
	cursor_time = 0.0
	cursor_on = true
	npc_text.text = "▌"

func cursor_stop():
	wait_cursor = false
	npc_text.text = ""

func load_frame(idx: int):
	var npc = npcs[idx]
	if ResourceLoader.exists(npc["frame"]):
		card_bg.texture = load(npc["frame"])

func load_icon(idx: int):
	var npc = npcs[idx]
	if ResourceLoader.exists(npc["icon"]):
		prev_icon.texture = load(npc["icon"])

func swap_card(cb: Callable):
	if tween_card:
		tween_card.kill()
	
	tween_card = create_tween()
	var orig = card.scale
	
	tween_card.tween_property(card, "scale", Vector2(0.8, 0.8), 0.15).set_ease(Tween.EASE_IN)
	tween_card.parallel().tween_property(card, "modulate:a", 0.0, 0.15)
	tween_card.tween_callback(cb)
	tween_card.tween_property(card, "scale", orig, 0.15).set_ease(Tween.EASE_OUT)
	tween_card.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
	
	await tween_card.finished

func enter_card():
	if tween_card:
		tween_card.kill()
	
	tween_card = create_tween()
	var target = card.position
	card.position.x += 200
	card.scale = Vector2(0.5, 0.5)
	card.modulate.a = 0.0
	
	tween_card.tween_property(card, "position", target, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_card.parallel().tween_property(card, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
	tween_card.parallel().tween_property(card, "modulate:a", 1.0, 0.2)
	
	await tween_card.finished

func start_input():
	mode = state.input
	
	input_panel.visible = true
	msg_box.visible = true
	banned.visible = true
	tab.visible = true
	
	prev.visible = false
	prev_bubble.visible = false
	card.visible = false
	results.visible = false
	npc_text.text = ""
	
	btn.text = "Send"
	btn.disabled = false
	btn.visible = true
	
	npc_pos = 0
	chain.clear()
	king.clear()
	
	current_msg = messages[randi() % messages.size()]
	raw_text = current_msg["text"]
	banned_words = current_msg["banned"]
	msg_box.text = ""
	
	type(raw, raw_text)
	await typing_finished
	
	type(banned, "🚫 Banned: " + ", ".join(banned_words))
	await typing_finished

func on_btn():
	if mode == state.input:
		send()
	elif mode == state.showing:
		next_npc()

func send():
	var txt = msg_box.text.strip_edges()
	
	if txt.is_empty():
		type(banned, "⚠️ Write something first!")
		return
	
	var found = []
	for word in banned_words:
		if txt.to_lower().contains(word.to_lower()):
			found.append(word)
	
	if found.size() > 0:
		type(banned, "⚠️ CAUGHT! " + ", ".join(found))
		return
	
	player_text = txt
	mode = state.waiting
	btn.disabled = true
	btn.text = "..."
	
	msg_box.visible = false
	banned.visible = false
	tab.visible = false
	
	prev.visible = true
	prev_bubble.visible = true
	prev_icon.visible = false
	prev_msg.text = "Your message:\n\"" + player_text + "\""
	
	card.visible = true
	load_frame(0)
	personality.text = npcs[0]["name"] + "\n\n" + npcs[0]["personality"]
	
	await enter_card()
	
	cursor_start()
	ask_ai()

func ask_ai():
	var npc_list = ""
	for i in range(npcs.size()):
		npc_list += str(i+1) + ". " + npcs[i]["name"] + "\n"
	
	var sys = """You simulate a message passing through medieval NPCs.

RULES:
- Each NPC only sees the PREVIOUS NPC's message (not original)
- Apply their personality to reinterpret
- 1-2 sentences per NPC
- Misunderstandings compound through the chain

NPCs:
""" + npc_list + """

After all NPCs, KING judges:
- survival_score (0-100): how much warning survived
- verdict: what king understood

RESPOND ONLY IN JSON:
{
  "chain": [
    {"npc": "The Merchant", "message": "..."},
    {"npc": "The Boy", "message": "..."},
    {"npc": "The Guard", "message": "..."},
    {"npc": "The Drunk", "message": "..."},
    {"npc": "The Scholar", "message": "..."}
  ],
  "king": {
    "survival_score": 50,
    "verdict": "..."
  }
}"""

	var usr = """ORIGINAL: "%s"
PLAYER WROTE: "%s"
Simulate chain.""" % [raw_text, player_text]

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]
	
	var body = {
		"model": "gpt-4o-mini",
		"messages": [
			{"role": "system", "content": sys},
			{"role": "user", "content": usr}
		],
		"temperature": 0.8,
		"max_tokens": 1000
	}
	
	var err = http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	
	if err != OK:
		cursor_stop()
		fail()

func on_response(result, _code, _headers, body):
	cursor_stop()
	
	if result != HTTPRequest.RESULT_SUCCESS:
		fail()
		return
	
	var txt = body.get_string_from_utf8()
	var data = JSON.parse_string(txt)
	
	if data == null or not data.has("choices"):
		fail()
		return
	
	var content = data["choices"][0]["message"]["content"]
	var parsed = parse_json(content)
	
	if parsed != null and parsed.has("chain"):
		chain = parsed["chain"]
		king = parsed.get("king", {"survival_score": 0, "verdict": "Unknown"})
		show_npcs()
	else:
		fail()

func fail():
	btn.text = "Retry"
	btn.disabled = false
	mode = state.input

func parse_json(txt: String):
	var parsed = JSON.parse_string(txt)
	if parsed != null:
		return parsed
	
	var start = txt.find("{")
	var end = txt.rfind("}") + 1
	if start >= 0 and end > start:
		return JSON.parse_string(txt.substr(start, end - start))
	
	return null

func show_npcs():
	mode = state.showing
	
	input_panel.visible = true
	msg_box.visible = false
	banned.visible = false
	tab.visible = false
	
	prev.visible = true
	prev_bubble.visible = true
	card.visible = true
	results.visible = false
	
	
	btn.disabled = false
	
	npc_pos = 0
	show_current()

func show_current():
	if npc_pos >= chain.size():
		show_end()
		return
	
	var npc = npcs[npc_pos]
	var interp = chain[npc_pos]
	
	btn.disabled = true
	
	load_frame(npc_pos)
	personality.text = npc["name"] + "\n\n" + npc["personality"]
	
	if npc_pos > 0:
		prev_icon.visible = true
		load_icon(npc_pos - 1)
		var prev_interp = chain[npc_pos - 1]
		var prev_txt = prev_interp.get("message", "...")
		if prev_txt.length() > 80:
			prev_txt = prev_txt.substr(0, 77) + "..."
		prev_msg.text = npcs[npc_pos - 1]["name"] + " said:\n\"" + prev_txt + "\""
	else:
		prev_icon.visible = false
		prev_msg.text = "Your message:\n\"" + player_text + "\""
	
	var msg = interp.get("message", "...")
	type(npc_text, "\"" + msg + "\"")
	await typing_finished
	
	btn.disabled = false

func next_npc():
	npc_pos += 1
	
	if npc_pos >= chain.size():
		show_end()
	else:
		await swap_card(show_current)

func show_end():
	mode = state.done
	
	card.visible = false
	results.visible = true
	btn.visible = false
	
	if chain.size() > 0:
		prev.visible = true
		prev_bubble.visible = true
		prev_icon.visible = true
		load_icon(npcs.size() - 1)
		var last = chain[chain.size() - 1]
		prev_msg.text = "Final message:\n\"" + last.get("message", "...").substr(0, 60) + "\""
	
	var survival = king.get("survival_score", 0)
	var verdict = king.get("verdict", "Unknown")
	
	var txt = " THE KING\n\n"
	txt += " Survival: " + str(survival) + "%\n\n"
	
	if survival >= 70:
		txt += "ok" + verdict
	elif survival >= 40:
		txt += "err" + verdict
	else:
		txt += "noo " + verdict
	
	type(score, txt)

func restart():
	btn.visible = true
	start_input()
		
