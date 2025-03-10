extends Control

@onready var priority_high = $MarginContainer/VBoxContainer/PrioritySection/PriorityOptions/HighCheck
@onready var priority_medium = $MarginContainer/VBoxContainer/PrioritySection/PriorityOptions/MediumCheck
@onready var priority_low = $MarginContainer/VBoxContainer/PrioritySection/PriorityOptions/LowCheck

@onready var status_pending = $MarginContainer/VBoxContainer/StatusSection/StatusOptions/PendingCheck
@onready var status_completed = $MarginContainer/VBoxContainer/StatusSection/StatusOptions/CompletedCheck

@onready var time_range_option = $MarginContainer/VBoxContainer/TimeSection/TimeRangeOption

@onready var time_sort = $MarginContainer/VBoxContainer/SortSection/SortOptions/TimeSort
@onready var priority_sort = $MarginContainer/VBoxContainer/SortSection/SortOptions/PrioritySort
@onready var spatial_sort = $MarginContainer/VBoxContainer/SortSection/SortOptions/SpatialSort

var task_filter: Node
var task_sorter: Node
var task_manager: Node

func _ready() -> void:
    task_filter = get_node("/root/Main/TaskFilter")
    task_sorter = get_node("/root/Main/TaskSorter")
    task_manager = get_node("/root/Main/TaskManager")
    
    # Connect checkboxes
    priority_high.toggled.connect(_on_priority_filter_changed)
    priority_medium.toggled.connect(_on_priority_filter_changed)
    priority_low.toggled.connect(_on_priority_filter_changed)
    
    status_pending.toggled.connect(_on_status_filter_changed)
    status_completed.toggled.connect(_on_status_filter_changed)
    
    # Set up time range options
    time_range_option.add_item("All Time")
    time_range_option.add_item("Today")
    time_range_option.add_item("This Week")
    time_range_option.selected = 0
    
    time_range_option.item_selected.connect(_on_time_range_changed)
    
    # Set up sorting options
    _setup_sort_options()

func _setup_sort_options() -> void:
    # Time-based sorting
    time_sort.add_item("Time Sort")
    time_sort.add_item("Newest First", TaskSorter.SortType.CREATION_TIME_DESC)
    time_sort.add_item("Oldest First", TaskSorter.SortType.CREATION_TIME_ASC)
    time_sort.add_item("Recently Completed", TaskSorter.SortType.COMPLETION_TIME_DESC)
    time_sort.add_item("First Completed", TaskSorter.SortType.COMPLETION_TIME_ASC)
    
    # Priority-based sorting
    priority_sort.add_item("Priority Sort")
    priority_sort.add_item("High to Low", TaskSorter.SortType.PRIORITY_DESC)
    priority_sort.add_item("Low to High", TaskSorter.SortType.PRIORITY_ASC)
    
    # Spatial sorting
    spatial_sort.add_item("Spatial Sort")
    spatial_sort.add_item("Nearest First", TaskSorter.SortType.SPATIAL_DISTANCE)
    spatial_sort.add_item("Top to Bottom", TaskSorter.SortType.SPATIAL_HEIGHT)
    spatial_sort.add_item("Left to Right", TaskSorter.SortType.SPATIAL_HORIZONTAL)

func _on_priority_filter_changed(_toggled: bool) -> void:
    var priorities := []
    if priority_high.button_pressed:
        priorities.append("high")
    if priority_medium.button_pressed:
        priorities.append("medium")
    if priority_low.button_pressed:
        priorities.append("low")
    
    task_filter.set_priority_filter(priorities)

func _on_status_filter_changed(_toggled: bool) -> void:
    var statuses := []
    if status_pending.button_pressed:
        statuses.append("pending")
    if status_completed.button_pressed:
        statuses.append("completed")
    
    task_filter.set_status_filter(statuses)

func _on_time_range_changed(index: int) -> void:
    match index:
        0: task_filter.set_time_range("all_time")
        1: task_filter.set_time_range("today")
        2: task_filter.set_time_range("this_week")

func _on_clear_filters_pressed() -> void:
    # Reset UI
    priority_high.button_pressed = false
    priority_medium.button_pressed = false
    priority_low.button_pressed = false
    
    status_pending.button_pressed = false
    status_completed.button_pressed = false
    
    time_range_option.selected = 0
    
    # Reset sort options
    time_sort.selected = 0
    priority_sort.selected = 0
    spatial_sort.selected = 0
    
    # Clear filters
    task_filter.clear_filters()

func _on_apply_sort_pressed() -> void:
    var sort_type = TaskSorter.SortType.CREATION_TIME_DESC  # Default
    
    # Check which sort option is selected
    if time_sort.selected > 0:
        sort_type = time_sort.get_selected_id()
    elif priority_sort.selected > 0:
        sort_type = priority_sort.get_selected_id()
    elif spatial_sort.selected > 0:
        sort_type = spatial_sort.get_selected_id()
    
    task_sorter.set_sort_type(sort_type) 