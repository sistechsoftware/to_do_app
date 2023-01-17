class Task {

  int? id;
  String title;
  String description;
  String status;
  String audioDirectory;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.audioDirectory,
  });

  factory Task.fromSQLite(Map map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      audioDirectory: map['audioDirectory'],
    );
  }

  static List<Task> fromSQLiteList(List<Map> listMap) {
    List<Task> tasks = [];

    for (Map item in listMap) {
      tasks.add(Task.fromSQLite(item));
    }

    return tasks;
  }

  // Task.fromMap(Map<String, dynamic> map) {
  //   id = map['id'];
  //   title = map['title'];
  //   description = map['description'];
  // }

  // Map<String, dynamic> toMap() {
  //   return {
  //     DB.columnId: id,
  //     DB.columnTitle: title,
  //     DB.columnDescription: description,
  //   };
  // }

}