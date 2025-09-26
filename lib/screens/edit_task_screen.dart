// lib/screens/edit_task_screen.dart

import 'package:flutter/material.dart';
import '../models/task.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _linkController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _linkController = TextEditingController(text: widget.task.link);
    _selectedDate = widget.task.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.task.title = _titleController.text.trim();
      widget.task.description = _descController.text.trim().isNotEmpty ? _descController.text.trim() : null;
      widget.task.link = _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null;
      widget.task.date = _selectedDate;

      Navigator.pop(context, widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Task")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Task Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: "Registration Link (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
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
                child: AbsorbPointer(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Select Date",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: "${_selectedDate.toLocal()}".split(' ')[0],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}