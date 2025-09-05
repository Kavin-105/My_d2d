class Task {
  String title;
  String? description;
  String? link;
  bool isDone;
  DateTime date;

  Task({
    required this.title,
    required this.date,
    this.description,
    this.link,
    this.isDone = false,
  });

  void toggleDone() {
    isDone = !isDone;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'isDone': isDone,
      'date': date.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      link: json['link'],
      isDone: json['isDone'],
      date: DateTime.parse(json['date']),
    );
  }
}
