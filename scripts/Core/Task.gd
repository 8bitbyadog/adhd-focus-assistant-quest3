class_name Task
extends RefCounted

var id: String
var title: String
var description: String
var priority: String
var completed: bool
var creation_time: float
var completion_time: float
var spatial_position: Vector3

func _init(p_id: String, p_title: String, p_description: String = "", p_priority: String = "medium") -> void:
    id = p_id
    title = p_title
    description = p_description
    priority = p_priority
    completed = false
    creation_time = Time.get_unix_time_from_system()
    completion_time = 0.0
    spatial_position = Vector3.ZERO

func to_dict() -> Dictionary:
    return {
        "id": id,
        "title": title,
        "description": description,
        "priority": priority,
        "completed": completed,
        "creation_time": creation_time,
        "completion_time": completion_time,
        "spatial_position": {
            "x": spatial_position.x,
            "y": spatial_position.y,
            "z": spatial_position.z
        }
    }

static func from_dict(data: Dictionary) -> Task:
    var task = Task.new(
        data["id"],
        data["title"],
        data["description"],
        data["priority"]
    )
    task.completed = data["completed"]
    task.creation_time = data["creation_time"]
    task.completion_time = data["completion_time"]
    
    var pos = data["spatial_position"]
    task.spatial_position = Vector3(pos["x"], pos["y"], pos["z"])
    
    return task

func complete() -> void:
    completed = true
    completion_time = Time.get_unix_time_from_system()

func uncomplete() -> void:
    completed = false
    completion_time = 0.0

func update_position(position: Vector3) -> void:
    spatial_position = position 