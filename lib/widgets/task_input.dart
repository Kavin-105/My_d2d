import 'package:flutter/material.dart';

class TaskInput extends StatefulWidget {
  final Function(String, DateTime) onAdd;

  const TaskInput({super.key, required this.onAdd});

  @override
  State<TaskInput> createState() => _TaskInputState();
}

class _TaskInputState extends State<TaskInput> {
  final TextEditingController _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _handleAdd() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAdd(_controller.text.trim(), _selectedDate);
      _controller.clear();
      setState(() {
        _selectedDate = DateTime.now(); // reset to today
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter new task...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2022),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          ElevatedButton(
            onPressed: _handleAdd,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
