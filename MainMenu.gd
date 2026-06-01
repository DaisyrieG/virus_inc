extends Control

@onready var screen1 = $Screen1
@onready var screen2 = $Screen2
@onready var screen3 = $Screen3
@onready var instr1 = $InstrScreen1
@onready var instr2 = $InstrScreen2
@onready var instr3 = $InstrScreen3
@onready var screen4 = $Screen4

@onready var start_button = $Screen1/StartButton
@onready var yes_button = $Screen2/YesButton
@onready var no_button = $Screen2/NoButton
@onready var next_button = $Screen3/NextButton
@onready var instr1_next = $InstrScreen1/NextBtn
@onready var instr2_next = $InstrScreen2/NextBtn
@onready var instr3_next = $InstrScreen3/NextBtn
@onready var text_cover = $Screen4/EnterPrompt/TextCover
@onready var virus_name_input = $Screen4/EnterPrompt/VirusNameInput

# Store the initial position of the No button so it resets properly if needed
var no_button_initial_pos: Vector2

func _ready():
    screen1.show()
    screen2.hide()
    screen3.hide()
    instr1.hide()
    instr2.hide()
    instr3.hide()
    screen4.hide()
    text_cover.hide()
    
    # Connect signals
    start_button.pressed.connect(_on_start_pressed)
    yes_button.pressed.connect(_on_yes_pressed)
    no_button.mouse_entered.connect(_on_no_mouse_entered)
    no_button.pressed.connect(_on_no_pressed)
    next_button.pressed.connect(_on_next_pressed)
    instr1_next.pressed.connect(_on_instr1_next)
    instr2_next.pressed.connect(_on_instr2_next)
    instr3_next.pressed.connect(_on_instr3_next)
    virus_name_input.text_changed.connect(_on_virus_name_changed)
    virus_name_input.text_submitted.connect(_on_virus_name_submitted)
    
    # Need to defer this slightly so the sizes/positions are calculated by Godot
    call_deferred("_store_initial_pos")

func _store_initial_pos():
    no_button_initial_pos = no_button.global_position

func _on_start_pressed():
    screen1.hide()
    screen2.show()
    
    # Reset No button back to its initial position every time Screen 2 is shown
    if no_button_initial_pos != Vector2.ZERO:
        no_button.global_position = no_button_initial_pos
        # Need to remove anchor positioning so we can move it freely via code
        no_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
        no_button.global_position = no_button_initial_pos

func _on_yes_pressed():
    print("User clicked YES!")
    screen2.hide()
    screen3.show()

func _on_no_mouse_entered():
    # Make the NO button run away from the cursor
    var viewport_size = get_viewport_rect().size
    var button_size = no_button.size
    
    # Generate a random position within the visible viewport bounds
    # Add a bit of margin so it doesn't clip off screen
    var margin = 20.0
    var random_x = randf_range(margin, viewport_size.x - button_size.x - margin)
    var random_y = randf_range(margin, viewport_size.y - button_size.y - margin)
    
    # Smoothly move it to the new location using a tween
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(no_button, "global_position", Vector2(random_x, random_y), 0.15)

func _on_no_pressed():
    print("Somehow clicked NO!")

func _on_next_pressed():
    screen3.hide()
    instr1.show()

func _on_instr1_next():
    instr1.hide()
    instr2.show()

func _on_instr2_next():
    instr2.hide()
    instr3.show()

func _on_instr3_next():
    instr3.hide()
    screen4.show()
    virus_name_input.grab_focus()

func _on_virus_name_changed(new_text: String):
    # Hide the baked-in text by showing a red color rect over it if the user has typed anything
    if new_text.length() > 0:
        text_cover.show()
    else:
        text_cover.hide()

func _on_virus_name_submitted(virus_name: String):
    print("Virus name chosen: ", virus_name)
    Global.virus_name = virus_name
    get_tree().change_scene_to_file("res://GameScene.tscn")
