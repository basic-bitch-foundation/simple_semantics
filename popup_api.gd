extends Control

signal confirmed

@onready var bg     = $bg       # TextureRect  — background
@onready var xbtn   = $xbtn     # Button       — close (top left, your texture)
@onready var info   = $info     # RichTextLabel — your bbcode text
@onready var inp    = $inp      # LineEdit      — key input field
@onready var savbtn = $savbtn   # Button        — save
@onready var lnk    = $lnk      # Button        — hyperlink

const savepath = "user://api.cfg"
const hacksite = "https://ai.hackclub.com"

func _ready():
	xbtn.pressed.connect(on_close)
	savbtn.pressed.connect(on_save)
	lnk.pressed.connect(on_lnk)

	
	

	
	var cfg = ConfigFile.new()
	if cfg.load(savepath) == OK:
		inp.text = cfg.get_value("api", "key", "")

func open():
	visible = true
	inp.grab_focus()

func on_close():
	visible = false   #

func on_save():
	var k = inp.text.strip_edges()
	if k.is_empty():
		info.text = "[color=red]paste your key first![/color]"
		return
	var cfg = ConfigFile.new()
	cfg.load(savepath)
	cfg.set_value("api", "key", k)
	cfg.save(savepath)
	visible = false
	confirmed.emit()

func on_lnk():
	OS.shell_open(hacksite)
