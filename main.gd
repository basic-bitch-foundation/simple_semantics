extends Node2D

@onready var input_panel = $InputPanel
@onready var raw_msg = $InputPanel/rawmsg
@onready var ban_words = $InputPanel/ban_words
@onready var msg_input = $InputPanel/input
@onready var send_btn = $InputPanel/send

@onready var card = $Card
@onready var portrait = $Card/Portrait
@onready var msg_label = $Card/MessageLabel
@onready var name_label = $Card/NameLabel
@onready var next_btn = $Card/Button

const BANNED = ["poison", "assassin", "kill", "murder", "attack", "danger"]

const MSGS = [
	"The King's wine will be poisoned at tonight's feast.  Warn him before midnight.",
]

const NPCS = [
	{
		"name":  "The Child",
		"personality": "childlike",
		"prompt": "You are a 7-year-old child.  Rewrite this message using simple childlike words.  Maybe misunderstand some things.  Keep it to 1-2 sentences.  Just give the rewritten message, nothing else."
	},
	{
		"name": "The Guard", 
		"personality": "paranoid",
		"prompt": "You are a paranoid palace guard. Rewrite this message with suspicion and military framing. Keep it to 1-2 sentences. Just give the rewritten message, nothing else."
	},
	{
		"name":  "The Merchant",
		"personality": "optimistic", 
		"prompt": "You are an optimistic merchant.  Rewrite this message with a positive spin. Keep it to 1-2 sentences. Just give the rewritten message, nothing else."
	}
]

var raw: String = ""
var player_msg: String = ""
var cur_msg: String = ""
var npc_idx: int = 0

var typ_label: Label = null
var typ_text: String = ""
var typ_idx: int = 0
var typ_speed: float = 0.03
var typ_timer: float = 0.0
var typing: bool = false
var typ_callback: Callable

signal typing_finished

func _ready():
	send_btn.pressed.connect(send)
	next_btn.pressed.connect(next)
	card.visible = false
	next_btn.disabled = true
	portrait.texture = load("res://icon.svg")
	start_input()

func _process(delta):
	if not typing: 
		return
	
	typ_timer += delta
	
	while typ_timer >= typ_speed and typ_idx < typ_text.length():
		typ_timer -= typ_speed
		typ_idx += 1
		typ_label.text = typ_text.substr(0, typ_idx) + "▌"
	
	if typ_idx >= typ_text.length():
		typing = false
		typ_label.text = typ_text
		typing_finished.emit()

func type(label: Label, text: String, callback: Callable = Callable()):
	typ_label = label
	typ_text = text
	typ_idx = 0
	typ_timer = 0.0
	typing = true
	typ_callback = callback
	label.text = "▌"

func start_input():
	input_panel.visible = true
	card.visible = false
	raw = MSGS[0]
	msg_input.text = ""
	type(raw_msg, raw)
	await typing_finished
	type(ban_words, "🚫 Banned:  " + ", ".join(BANNED))
	await typing_finished

func send():
	var txt = msg_input.text.strip_edges()
	
	if txt.is_empty():
		return
	
	var found = []
	for word in BANNED: 
		if txt.to_lower().contains(word):
			found.append(word)
	
	if found.size() > 0:
		type(ban_words, "⚠️ CAUGHT!  Found:  " + ", ".join(found))
		return
	
	player_msg = txt
	start_card()

func start_card():
	input_panel.visible = false
	card.visible = true
	npc_idx = 0
	cur_msg = player_msg
	show_npc(npc_idx)

func show_npc(idx: int):
	if idx >= NPCS.size():
		return
	
	var npc = NPCS[idx]
	next_btn.disabled = true
	type(name_label, npc["name"])
	await typing_finished
	msg_label.text = "Thinking..."
	
	await get_tree().create_timer(1.0).timeout
	type(msg_label, cur_msg)
	await typing_finished
	next_btn.disabled = false

func next():
	npc_idx += 1
	
	if npc_idx >= NPCS.size():
		pass
	else:
		show_npc(npc_idx)
