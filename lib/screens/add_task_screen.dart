import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _saveTask() {
    if (_titleController.text.trim().isNotEmpty) {
      Navigator.pop(
        context,
        Task(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          link: _linkController.text.trim().isNotEmpty
              ? _linkController.text.trim()
              : null,
          date: _selectedDate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Task")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Task Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Description input
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Task Description",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Link input
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: "Registration Link (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Date Picker as TextField
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Select Date",
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: "${_selectedDate.toLocal()}".split(' ')[0],
                    ),
                  ),
                ),
              ),

// 🔹 Add more space here
              const SizedBox(height: 100),

// 🔹 Save button
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save),
                label: const Text("Save Task"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
