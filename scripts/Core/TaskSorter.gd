class_name TaskSorter
extends Node

signal sort_changed

enum SortType {
    CREATION_TIME_DESC,    # Newest first
    CREATION_TIME_ASC,     # Oldest first
    PRIORITY_DESC,         # High to Low
    PRIORITY_ASC,         # Low to High
    COMPLETION_TIME_DESC,  # Recently completed first
    COMPLETION_TIME_ASC,   # Oldest completed first
    SPATIAL_DISTANCE,      # Closest to user first
    SPATIAL_HEIGHT,        # Top to bottom
    SPATIAL_HORIZONTAL     # Left to right
}

const PRIORITY_VALUES := {
    "high": 3,
    "medium": 2,
    "low": 1
}

var current_sort: SortType = SortType.CREATION_TIME_DESC
var camera: XRCamera3D

func _ready() -> void:
    # Get camera reference for spatial sorting
    await get_tree().create_timer(0.5).timeout  # Wait for scene setup
    camera = get_viewport().get_camera_3d()

func sort_tasks(tasks: Array) -> Array:
    var sorted_tasks = tasks.duplicate()
    
    match current_sort:
        SortType.CREATION_TIME_DESC:
            sorted_tasks.sort_custom(_sort_by_creation_time_desc)
        SortType.CREATION_TIME_ASC:
            sorted_tasks.sort_custom(_sort_by_creation_time_asc)
        SortType.PRIORITY_DESC:
            sorted_tasks.sort_custom(_sort_by_priority_desc)
        SortType.PRIORITY_ASC:
            sorted_tasks.sort_custom(_sort_by_priority_asc)
        SortType.COMPLETION_TIME_DESC:
            sorted_tasks.sort_custom(_sort_by_completion_time_desc)
        SortType.COMPLETION_TIME_ASC:
            sorted_tasks.sort_custom(_sort_by_completion_time_asc)
        SortType.SPATIAL_DISTANCE:
            if camera:
                sorted_tasks.sort_custom(func(a, b): return _sort_by_distance(a, b))
        SortType.SPATIAL_HEIGHT:
            sorted_tasks.sort_custom(_sort_by_height)
        SortType.SPATIAL_HORIZONTAL:
            sorted_tasks.sort_custom(_sort_by_horizontal)
    
    return sorted_tasks

func set_sort_type(type: SortType) -> void:
    if current_sort != type:
        current_sort = type
        emit_signal("sort_changed")

# Sorting functions
func _sort_by_creation_time_desc(a: Task, b: Task) -> bool:
    return a.creation_time > b.creation_time

func _sort_by_creation_time_asc(a: Task, b: Task) -> bool:
    return a.creation_time < b.creation_time

func _sort_by_priority_desc(a: Task, b: Task) -> bool:
    return PRIORITY_VALUES[a.priority] > PRIORITY_VALUES[b.priority]

func _sort_by_priority_asc(a: Task, b: Task) -> bool:
    return PRIORITY_VALUES[a.priority] < PRIORITY_VALUES[b.priority]

func _sort_by_completion_time_desc(a: Task, b: Task) -> bool:
    # Put incomplete tasks at the end
    if not a.completed and not b.completed:
        return false
    if not a.completed:
        return false
    if not b.completed:
        return true
    return a.completion_time > b.completion_time

func _sort_by_completion_time_asc(a: Task, b: Task) -> bool:
    # Put incomplete tasks at the end
    if not a.completed and not b.completed:
        return false
    if not a.completed:
        return false
    if not b.completed:
        return true
    return a.completion_time < b.completion_time

func _sort_by_distance(a: Task, b: Task) -> bool:
    if not camera:
        return false
    
    var camera_pos = camera.global_position
    var dist_a = a.spatial_position.distance_to(camera_pos)
    var dist_b = b.spatial_position.distance_to(camera_pos)
    return dist_a < dist_b

func _sort_by_height(a: Task, b: Task) -> bool:
    return a.spatial_position.y > b.spatial_position.y

func _sort_by_horizontal(a: Task, b: Task) -> bool:
    if not camera:
        return false
    
    # Project positions onto camera's right vector
    var right = camera.global_transform.basis.x
    var pos_a = a.spatial_position.project(right)
    var pos_b = b.spatial_position.project(right)
    return pos_a.x < pos_b.x

# Helper function to get sort type name
func get_sort_type_name(type: SortType) -> String:
    match type:
        SortType.CREATION_TIME_DESC:
            return "Newest First"
        SortType.CREATION_TIME_ASC:
            return "Oldest First"
        SortType.PRIORITY_DESC:
            return "High Priority First"
        SortType.PRIORITY_ASC:
            return "Low Priority First"
        SortType.COMPLETION_TIME_DESC:
            return "Recently Completed"
        SortType.COMPLETION_TIME_ASC:
            return "First Completed"
        SortType.SPATIAL_DISTANCE:
            return "Nearest First"
        SortType.SPATIAL_HEIGHT:
            return "Top to Bottom"
        SortType.SPATIAL_HORIZONTAL:
            return "Left to Right"
        _:
            return "Unknown" 