import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> _tasks = [];
  DateTime? _selectedDate; // null = no filter
  DateTime _focusedDate = DateTime.now();

  // Save tasks
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> taskList = _tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('tasks', taskList);
  }

  // Load tasks
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? taskList = prefs.getStringList('tasks');
    if (taskList != null) {
      setState(() {
        _tasks.clear();
        _tasks.addAll(
          taskList.map((t) => Task.fromJson(jsonDecode(t))).toList(),
        );
        _tasks.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Task categorization
  List<Task> get _completedTasks =>
      _tasks.where((task) => task.isDone).toList();

  List<Task> get _pendingTasks => _tasks.where((task) =>
  !task.isDone &&
      task.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

  List<Task> get _expiredTasks =>
      _tasks.where((task) => !task.isDone && task.date.isBefore(DateTime.now())).toList();

  List<Task> get _todayTasks => _tasks.where((task) =>
  task.date.year == DateTime.now().year &&
      task.date.month == DateTime.now().month &&
      task.date.day == DateTime.now().day).toList();

  List<Task> get _tomorrowTasks => _tasks.where((task) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return task.date.year == tomorrow.year &&
        task.date.month == tomorrow.month &&
        task.date.day == tomorrow.day;
  }).toList();

  List<Task> get _upcomingTasks => _tasks.where((task) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return task.date.isAfter(tomorrow) && !task.isDone;
  }).toList();

  // Add Task
  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
    });
    _saveTasks();
  }

  // Toggle Done with confirmation if undoing
  void _toggleTask(int index) {
    if (_tasks[index].isDone) {
      // If already completed → ask before undo
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Mark as Pending"),
            content: const Text("Do you want to mark this task as pending again?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tasks[index].toggleDone(); // undo completion
                  });
                  _saveTasks();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Yes",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Normal complete (no confirmation needed)
      setState(() {
        _tasks[index].toggleDone();
      });
      _saveTasks();
    }
  }


  // Delete Task with confirmation
  void _deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                _saveTasks();
                Navigator.pop(context); // close dialog
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }


  // Tasks for selected date
  List<Task> _filteredTasks() {
    if (_selectedDate == null) return [];
    return _tasks
        .where((task) =>
    task.date.year == _selectedDate!.year &&
        task.date.month == _selectedDate!.month &&
        task.date.day == _selectedDate!.day)
        .toList();
  }

  // Calendar popup
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Expanded(
                  child: TableCalendar<Task>(
                    focusedDay: _focusedDate,
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) =>
                    _selectedDate != null &&
                        day.year == _selectedDate!.year &&
                        day.month == _selectedDate!.month &&
                        day.day == _selectedDate!.day,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDate = focusedDay;
                      });
                      Navigator.pop(context);
                    },
                    eventLoader: (day) => _tasksForDate(day),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final tasksForDay = _tasksForDate(day);
                        if (tasksForDay.isNotEmpty) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Green circle
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade200,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                            ],
                          );
                        }
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final tasksForDay = _tasksForDate(day);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (tasksForDay.isNotEmpty)
                              Positioned(
                                top: 2,
                                right: 6,
                                child: Text(
                                  '${tasksForDay.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null; // clear filter
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Show All by Category"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tasks for a date
  List<Task> _tasksForDate(DateTime date) {
    return _tasks
        .where((task) =>
    task.date.year == date.year &&
        task.date.month == date.month &&
        task.date.day == date.day)
        .toList();
  }

  // Show task list in dialog (for stat cards)
  void _showTaskListDialog(String title, List<Task> tasks) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: tasks.isEmpty
                ? const Text("No tasks available")
                : ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final actualIndex = _tasks.indexOf(task);
                return TaskTile(
                  task: task,
                  onToggle: () => _toggleTask(actualIndex),
                  onDelete: () => _deleteTask(actualIndex),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  // UI build
  @override
  Widget build(BuildContext context) {
    final todayTasksCount = _todayTasks.length;
    final completedTodayCount =
        _todayTasks.where((task) => task.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Day To Day"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendarDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Greeting
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "You have $todayTasksCount tasks today",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress
          if (todayTasksCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Progress",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: todayTasksCount > 0
                        ? completedTodayCount / todayTasksCount
                        : 0,
                    color: Colors.green,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$completedTodayCount of $todayTasksCount completed",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // Task sections
          Expanded(
            child: _selectedDate != null
                ? _buildTaskSection(
              "Tasks for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              _filteredTasks(),
              Colors.blue,
            )
                : ListView(
              children: [
                if (_todayTasks.isNotEmpty)
                  _buildTaskSection("Today", _todayTasks, Colors.blue),
                if (_tomorrowTasks.isNotEmpty)
                  _buildTaskSection(
                      "Tomorrow", _tomorrowTasks, Colors.orange),
                if (_upcomingTasks.isNotEmpty)
                  _buildTaskSection(
                      "Upcoming", _upcomingTasks, Colors.green),
                if (_todayTasks.isEmpty &&
                    _tomorrowTasks.isEmpty &&
                    _upcomingTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.task_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No tasks available",
                              style: TextStyle(
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (newTask != null) _addTask(newTask);
        },
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Reusable section widget
  Widget _buildTaskSection(String title, List<Task> tasks, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${tasks.length}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final actualIndex = _tasks.indexOf(task);
            return TaskTile(
              task: task,
              onToggle: () => _toggleTask(actualIndex),
              onDelete: () => _deleteTask(actualIndex),
            );
          }).toList(),
        ],
      ),
    );
  }
}
