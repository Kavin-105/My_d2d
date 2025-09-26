// lib/widgets/task_tile.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap; // 🚀 New callback for when the tile is tapped

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onTap, // 🚀 New required argument
  });

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        onTap: onTap, // 🚀 Trigger the onTap callback
        leading: IconButton(
          icon: Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isDone ? Colors.green : Colors.red,
          ),
          onPressed: onToggle,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
          overflow: TextOverflow.ellipsis, // ✂️ Add ellipsis for long titles
        ),
        subtitle: Text(
          // 📅 Only show the date in the subtitle
          "${task.date.toLocal()}".split(' ')[0],
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}