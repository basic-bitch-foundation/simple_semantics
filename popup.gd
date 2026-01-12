extends Node2D

signal message_sealed(encrypted_text: String)

# Secret message
var secret = "Army will attack at dawn"

# Banned words
var banned = ["army", "attack", "war"]

func _ready():
	# Show secret + banned words in one label
	var text = "SECRET MESSAGE:\n" + secret
	text += "\n\nBANNED WORDS:\n" + ", ".join(banned)
	$text/rawmessage.text = text
	
	# Connect button
	$send.pressed.connect(_on_send)

func _on_send():
	var player_msg = $text/Input.text.strip_edges()
	
	# Empty check
	if player_msg == "":
		print("❌ Empty message!")
		return
	
	# Banned word check
	for word in banned:
		if player_msg.to_lower().contains(word):
			print("❌ Contains banned word: " + word)
			_shake()
			return
	
	# Success!
	print("\n📜 MESSAGE SENT")
	print("Original: " + secret)
	print("Encrypted: " + player_msg)
	print()
	
	message_sealed.emit(player_msg)
	hide()

func _shake():
	var orig = $scrolpaper.position
	for i in 4:
		$scrolpaper.position = orig + Vector2(randf_range(-10, 10), 0)
		await get_tree().create_timer(0.01).timeout
	$scrolpaper.position = orig
