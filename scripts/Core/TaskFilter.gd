extends Node

signal filters_changed

# Filter states
var priority_filter: Array = []
var status_filter: Array = []
var time_range: String = "all_time"

# Time range options
const TIME_RANGES = {
    "all_time": {
        "start": 0,
        "end": 9223372036854775807  # Max int64
    },
    "today": {
        "start": 0,  # Will be calculated
        "end": 0    # Will be calculated
    },
    "this_week": {
        "start": 0,  # Will be calculated
        "end": 0    # Will be calculated
    }
}

func _ready() -> void:
    _update_time_ranges()

func apply_filters(tasks: Array) -> Array:
    var filtered_tasks: Array = []
    
    for task in tasks:
        if task is Task and _passes_filters(task):
            filtered_tasks.append(task)
    
    return filtered_tasks

func set_priority_filter(priorities: Array) -> void:
    priority_filter = priorities
    emit_signal("filters_changed")

func set_status_filter(statuses: Array) -> void:
    status_filter = statuses
    emit_signal("filters_changed")

func set_time_range(range_type: String) -> void:
    if range_type in TIME_RANGES:
        time_range = range_type
        _update_time_ranges()
        emit_signal("filters_changed")

func clear_filters() -> void:
    priority_filter.clear()
    status_filter.clear()
    time_range = "all_time"
    emit_signal("filters_changed")

func _passes_filters(task: Task) -> bool:
    # Check priority filter
    if priority_filter.size() > 0 and not task.priority in priority_filter:
        return false
    
    # Check status filter
    if status_filter.size() > 0:
        var task_status = "completed" if task.completed else "pending"
        if not task_status in status_filter:
            return false
    
    # Check time range
    var ranges = TIME_RANGES[time_range]
    if task.creation_time < ranges.start or task.creation_time > ranges.end:
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