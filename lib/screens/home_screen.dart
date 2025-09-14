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

  List<Task> get _pendingTasks => _tasks
      .where((task) =>
  !task.isDone &&
      task.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
      .toList();

  List<Task> get _expiredTasks => _tasks
      .where((task) => !task.isDone && task.date.isBefore(DateTime.now()))
      .toList();

  List<Task> get _todayTasks => _tasks
      .where((task) =>
  task.date.year == DateTime.now().year &&
      task.date.month == DateTime.now().month &&
      task.date.day == DateTime.now().day)
      .toList();

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
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Mark as Pending"),
            content: const Text("Do you want to mark this task as pending again?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tasks[index].toggleDone();
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                _saveTasks();
                Navigator.pop(context);
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



                    // 🔥 Custom builders for colored circles + task count badge
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final tasks = _tasksForDate(day);
                        if (tasks.isNotEmpty) {
                          final completedCount =
                              tasks.where((t) => t.isDone).length;

                          Color bgColor;
                          if (completedCount == tasks.length) {
                            bgColor = Colors.green; // ✅ all done
                          } else if (completedCount > 0) {
                            bgColor = Colors.orange; // ⚠️ some done
                          } else {
                            bgColor = Colors.red; // ❌ none done
                          }

                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              // 🔢 Task count badge (superscript style)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${tasks.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        // 🟦 Highlight today if no tasks
                        if (day.year == DateTime.now().year &&
                            day.month == DateTime.now().month &&
                            day.day == DateTime.now().day) {
                          return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          );
                        }

                        return null;
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
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

  // Group tasks by date
  Map<DateTime, List<Task>> _groupTasksByDate(List<Task> tasks) {
    Map<DateTime, List<Task>> grouped = {};
    for (var task in tasks) {
      final date = DateTime(task.date.year, task.date.month, task.date.day);
      if (!grouped.containsKey(date)) grouped[date] = [];
      grouped[date]!.add(task);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    Map<DateTime, List<Task>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  // Show expired tasks popup
  void _showExpiredTasksDialog() {
    final groupedTasks = _groupTasksByDate(_expiredTasks);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Expired Tasks"),
          content: SizedBox(
            width: double.maxFinite,
            child: _expiredTasks.isEmpty
                ? const Text("No expired tasks available")
                : ListView(
              shrinkWrap: true,
              children: groupedTasks.entries.map((entry) {
                final date = entry.key;
                final tasks = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${date.day}/${date.month}/${date.year}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ...tasks.map((task) {
                      final actualIndex = _tasks.indexOf(task);
                      return TaskTile(
                        task: task,
                        onToggle: () => _toggleTask(actualIndex),
                        onDelete: () => _deleteTask(actualIndex),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              }).toList(),
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

  // Show completed tasks popup
  void _showCompletedTasksDialog() {
    final groupedTasks = _groupTasksByDate(_completedTasks);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Completed Tasks"),
          content: SizedBox(
            width: double.maxFinite,
            child: _completedTasks.isEmpty
                ? const Text("No completed tasks available")
                : ListView(
              shrinkWrap: true,
              children: groupedTasks.entries.map((entry) {
                final date = entry.key;
                final tasks = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${date.day}/${date.month}/${date.year}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ...tasks.map((task) {
                      final actualIndex = _tasks.indexOf(task);
                      return TaskTile(
                        task: task,
                        onToggle: () => _toggleTask(actualIndex),
                        onDelete: () => _deleteTask(actualIndex),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              }).toList(),
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
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white), // ✅ Your icon
            const SizedBox(width: 8), // spacing between icon and text
            const Text(
              "My Day To Day",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendarDialog,
          ),
        ],
      ),

      body: Column(
        children: [
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

                // Expired Tasks
                if (_expiredTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: _showExpiredTasksDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Expired Tasks",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                // 🔴 Count Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _expiredTasks.length.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.red.shade400, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

// Completed Tasks
                if (_completedTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: _showCompletedTasksDialog,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Completed Tasks",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                // 🟢 Count Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _completedTasks.length.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.green.shade400, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_todayTasks.isEmpty &&
                    _tomorrowTasks.isEmpty &&
                    _upcomingTasks.isEmpty &&
                    _expiredTasks.isEmpty &&
                    _completedTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.task_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No tasks available",
                              style:
                              TextStyle(color: Colors.grey.shade600)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
