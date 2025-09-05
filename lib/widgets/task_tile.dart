import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
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
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!, style: const TextStyle(color: Colors.black54)),
            Text(
              "${task.date.toLocal()}".split(' ')[0],
              style: const TextStyle(color: Colors.grey),
            ),
            if (task.link != null && task.link!.isNotEmpty)
              GestureDetector(
                onTap: () => _launchURL(task.link!),
                child: Text(
                  task.link!,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
