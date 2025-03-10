extends Node

signal filters_changed

# Filter states
var priority_filter: Array = []
var status_filter: Array = []
var time_range: String = "all_time"

# Time range options
const TIME_RANGES = {
    "all_time": {"days": -1},
    "today": {"days": 1},
    "this_week": {"days": 7}
}

func _ready() -> void:
    _update_time_ranges()

func apply_filters(tasks: Array) -> Array:
    var filtered_tasks: Array = []
    
    for task in tasks:
        if _task_matches_filters(task):
            filtered_tasks.append(task)
    
    return filtered_tasks

func set_priority_filter(priorities: Array) -> void:
    priority_filter = priorities
    emit_signal("filters_changed")

func set_status_filter(statuses: Array) -> void:
    status_filter = statuses
    emit_signal("filters_changed")

func set_time_range(range: String) -> void:
    time_range = range
    emit_signal("filters_changed")

func clear_filters() -> void:
    priority_filter.clear()
    status_filter.clear()
    time_range = "all_time"
    emit_signal("filters_changed")

func _task_matches_filters(task: Task) -> bool:
    # Priority filter
    if priority_filter.size() > 0 and not task.priority in priority_filter:
        return false
    
    # Status filter
    if status_filter.size() > 0:
        var task_status = "completed" if task.completed else "pending"
        if not task_status in status_filter:
            return false
    
    # Time range filter
    if time_range != "all_time":
        var days = TIME_RANGES[time_range]["days"]
        var current_time = Time.get_unix_time_from_system()
        var time_diff = current_time - task.creation_time
        
        if time_diff > days * 86400:  # 86400 seconds in a day
            return false
    
    return true

func _update_time_ranges() -> void:
    var current_time = Time.get_unix_time_from_system()
    
    # Update today's range
    var today_start = Time.get_unix_time_from_datetime_dict({
        "year": Time.get_date_dict_from_unix_time(current_time)["year"],
        "month": Time.get_date_dict_from_unix_time(current_time)["month"],
        "day": Time.get_date_dict_from_unix_time(current_time)["day"],
        "hour": 0,
        "minute": 0,
        "second": 0
    })
    
    TIME_RANGES["today"]["start"] = today_start
    TIME_RANGES["today"]["end"] = today_start + 86400  # 24 hours
    
    # Update this week's range
    var weekday = Time.get_date_dict_from_unix_time(current_time)["weekday"]
    var week_start = today_start - (weekday * 86400)
    
    TIME_RANGES["this_week"]["start"] = week_start
    TIME_RANGES["this_week"]["end"] = week_start + (7 * 86400)  # 7 days 