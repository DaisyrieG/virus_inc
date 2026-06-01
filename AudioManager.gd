extends Node


@onready var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	add_child(bgm_player)
	add_child(sfx_player)
	
	# Optional: Set default volumes
	# bgm_player.volume_db = -10.0
	# sfx_player.volume_db = -5.0

func play_bgm(stream: AudioStream):
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm():
	bgm_player.stop()

func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()
