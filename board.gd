extends Node2D

#UI class to be completed with buttons, keyboard shortcuts etc.
#For this demo, the "1" key triggers a "placement" mode to put soldiers on the map
@onready var ui := %UI

#3 different elevations. One map + One overlay + One empty grid for unit placement per elevation
@onready var sea_layer := %SeaLayer
@onready var sea_overlay := %SeaOverlay
@onready var sea_units = %SeaUnits

@onready var ground_layer := %GroundLayer
@onready var ground_overlay := %GroundOverlay
@onready var ground_units = %GroundUnits

@onready var elevation_layer := %ElevationLayer
@onready var elevation_overlay := %ElevationOverlay
@onready var elevation_units = %ElevationUnits

#Array of resources used to track the map overlay mod currently active (here, default or soldier placement)
@export var overlay_mods : Array[OverlayMod]

#properties defining the cursor to display
var current_overlay_mod :OverlayMod
var current_cursor_atlas_coordinates :Vector2i

#reference for a "null" Vector2i, to be modified depending on map origin
const null_coordinates := Vector2i(-10,-10)

#properties to track the last cell displaying the cursor
var last_overlay_cell := null_coordinates
var last_overlay_layer : TileMapLayer = null


#Arrays and dictionnaries to navigate the tilemaplayers and reference maps <-> overlays
var maps_from_bottom : Array[TileMapLayer]
var maps_from_top : Array[TileMapLayer]
var overlays_from_bottom : Array[TileMapLayer]
var overlays_from_top : Array[TileMapLayer]
var maps_by_overlays := {}
var overlays_by_maps := {}
var units_by_overlays := {}
var overlays_by_units := {}
var map_dictionnary := {}


func _ready():
	#defines the overlay mod to default at the start
	current_overlay_mod = overlay_mods[0]
	current_cursor_atlas_coordinates = overlay_mods[0].atlas_coordinates_ok
	#fills the tilemaplayers data structures
	maps_by_overlays = {
		sea_overlay: sea_layer,
		ground_overlay: ground_layer,
		elevation_overlay: elevation_layer
	}
	overlays_by_maps = {
		sea_layer: sea_overlay,
		ground_layer: ground_overlay,
		elevation_layer: elevation_overlay
	}
	units_by_overlays = {
		sea_overlay: sea_units,
		ground_overlay: ground_units,
		elevation_overlay: elevation_units
	}
	overlays_by_units = {
		sea_units: sea_overlay,
		ground_units: ground_overlay,
		elevation_units: elevation_overlay
	}
	maps_from_bottom = [
		sea_layer,
		ground_layer,
		elevation_layer
	]
	maps_from_top = maps_from_bottom.duplicate(true)
	maps_from_top.reverse()
	overlays_from_bottom = [
		sea_overlay,
		ground_overlay,
		elevation_overlay
	]
	overlays_from_top = overlays_from_bottom.duplicate(true)
	overlays_from_top.reverse()
	for overlay in overlays_from_bottom:
		overlay.modulate.a = 0.5
	
	map_dictionnary = get_map_dictionnary()
	
	#connects the signals from the UI node to the functions that change the overlay mod	
	ui.toggled_soldier_mode.connect(change_overlay_mod.bind("soldier_mode"))
	ui.was_cancelled.connect(change_overlay_mod.bind("default"))

func _process(delta):
	var tile_coordinates := get_selected_tile_coordinates()
	display_cursor(
		get_selected_overlay(tile_coordinates), 
		tile_coordinates, 
		select_overlay_cursor_atlas_coordinates(tile_coordinates), 
		current_overlay_mod.source_id
		)
	
	#Interactions can go here. Right now, if in soldier placement mode, left click places a soldier
func _unhandled_input(event):
	if event is InputEventMouseButton and current_overlay_mod.name == "soldier_mode":
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_action_pressed("validate"):
				var tile_coordinates = get_selected_tile_coordinates()
				place_soldier(tile_coordinates, get_selected_overlay(tile_coordinates))


func place_soldier(tile_coordinates: Vector2i, overlay: TileMapLayer)->void:
	var unitlayer:TileMapLayer= units_by_overlays[overlay] 
	var soldier_instance = preload("res://units/soldier.tscn").instantiate()
	soldier_instance.y_sort_enabled = true
	soldier_instance.global_position = overlay.to_global(overlay.map_to_local(tile_coordinates)) + Vector2(0,20-overlay.global_position.y*2)
	soldier_instance.offset = Vector2(0,overlay.global_position.y-45) 
	unitlayer.add_child(soldier_instance)



func select_overlay_cursor_atlas_coordinates(coordinates: Vector2i) -> Vector2i:
	var atlas_coordinates : Vector2i
	match current_overlay_mod.name:
		"default":
			atlas_coordinates = current_overlay_mod.atlas_coordinates_ok
		"soldier_mode":
			atlas_coordinates = current_overlay_mod.atlas_coordinates_ok
	return atlas_coordinates

func change_overlay_mod(name: String) -> void:
	current_overlay_mod = overlay_mods[0]
	for overlay_mod in overlay_mods:
		if overlay_mod.name == name:
			current_overlay_mod = overlay_mod
			break
	last_overlay_cell = null_coordinates
	last_overlay_layer = null







func get_map_dictionnary() -> Dictionary:
	var map_dictionnary := {}
	var map_rect :Rect2i= sea_layer.get_used_rect()
	for x in range (map_rect.position.x, map_rect.end.x):
		for y in range (map_rect.position.y, map_rect.end.y):
			var cell=Vector2i(x,y)
			if sea_layer.get_cell_source_id(cell) != -1:
				if elevation_layer.get_cell_source_id(cell) != -1:
					map_dictionnary[cell] = elevation_layer
				elif ground_layer.get_cell_source_id(cell) != -1:
					map_dictionnary[cell] = ground_layer
				else:
					map_dictionnary[cell] = sea_layer
	return map_dictionnary
	

func get_selected_tile_coordinates() -> Vector2i:
	var coordinates := null_coordinates
	for layer in maps_from_top:
		var mouse_coordinates = layer.to_local(get_global_mouse_position())
		var tile_coordinates = layer.local_to_map(mouse_coordinates)
		if layer.get_cell_source_id(tile_coordinates) != -1 :
			coordinates = tile_coordinates
			break
	return coordinates
	


func get_selected_overlay(coordinates: Vector2i) -> TileMapLayer:
	var selected_overlay : TileMapLayer = null
	if coordinates != null_coordinates:
		var max_height_map : TileMapLayer = map_dictionnary[coordinates]
		selected_overlay = overlays_by_maps[max_height_map]
	return selected_overlay


func display_cursor(
	overlay_layer: TileMapLayer, 
	tile_coordinates: Vector2i, 
	cursor_atlas_coordinates : Vector2i,
	cursor_atlas_source: int
	) -> void:
	if overlay_layer == last_overlay_layer and tile_coordinates == last_overlay_cell:
		pass
	else:
		if last_overlay_layer != null and last_overlay_cell != null_coordinates:
			last_overlay_layer.erase_cell(last_overlay_cell)	
		if overlay_layer == null or tile_coordinates == null_coordinates:
			last_overlay_cell = null_coordinates
			last_overlay_layer = null
		else:
			var current_map_layer: TileMapLayer = maps_by_overlays[overlay_layer]
			overlay_layer.set_cell(tile_coordinates, cursor_atlas_source, cursor_atlas_coordinates)
			last_overlay_cell = tile_coordinates
			last_overlay_layer = overlay_layer
