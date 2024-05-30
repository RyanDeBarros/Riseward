extends Node


const sfx_dict = {
	"parry": preload("res://assets/audio/sfx/616493__empiremonkey__block3.mp3"),
	"jump": preload("res://assets/audio/sfx/slime_jump.wav"),
	"dash": preload("res://assets/audio/sfx/714258__qubodup__cloud-poof.wav"),
	"throw": preload("res://assets/audio/sfx/sfx_throw.mp3"),
	"pickup": preload("res://assets/audio/sfx/pickup1.mp3"),
	"swap": preload("res://assets/audio/sfx/pickup2.mp3"),
	"drop": preload("res://assets/audio/sfx/pickup3.mp3"),
	"swing1": preload("res://assets/audio/sfx/394414__inspectorj__bamboo-swing-a10.mp3"),
	"swing2": preload("res://assets/audio/sfx/422513__nightflame__swinging-staff-whoosh-strong-04.mp3"),
	"parry_success": preload("res://assets/audio/sfx/churchbell.mp3"),
	"player_hit": preload("res://assets/audio/sfx/632281__robinhood76__11004-broken-string-bounce.mp3"),
	"enemy_attack": preload("res://assets/audio/sfx/507162__ruidososoundfx__heavy-woosh-ricrob-nm-22.mp3"), # enemy attack
	"enemy_hit": preload("res://assets/audio/sfx/676465__stevenmaertens__hit-5.mp3"),
	"pop": preload("res://assets/audio/sfx/cork.mp3"),
	"rumble": preload("res://assets/audio/sfx/hjm-big_explosion_3.mp3"),
	"death": preload("res://assets/audio/sfx/93012__cosmicd__41.mp3"),
	"win": preload("res://assets/audio/sfx/270466__littlerobotsoundfactory__jingle_win_00.mp3"), # TODO win
}

const music_dict = {
	"menu": preload("res://assets/audio/music/TremLoadingloopl.mp3"),
	"level": preload("res://assets/audio/music/song21.mp3"),
}

var soundtrack_player: AudioStreamPlayer


func _ready() -> void:
	soundtrack_player = AudioStreamPlayer.new()
	add_child(soundtrack_player)
	soundtrack_player.finished.connect(soundtrack_player.play)


func play_sfx(track: String, volume_offset_db := 0.0, start_at := 0.0, pitch_scale := 1.0,\
		time_limit := -1.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx_dict[track]
	player.pitch_scale = pitch_scale
	player.volume_db += volume_offset_db
	if time_limit > 0.0:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -20.0, time_limit)
		tween.finished.connect(player.queue_free)
	else:
		player.finished.connect(player.queue_free)
	player.play(start_at)


func play_sfx_random_pitch(track: String, volume_offset_db := 0.0, start_at := 0.0,\
		pitch_min_scale := 0.85, pitch_max_scale := 1.15, time_limit := -1.0) -> void:
	play_sfx(track, volume_offset_db, start_at, randf_range(pitch_min_scale, pitch_max_scale), time_limit)


func play_music(track: String, loop := true) -> void:
	soundtrack_player.stream = music_dict[track]
	if not soundtrack_player.playing:
		soundtrack_player.play()
