import 'package:to_do/models/task_model.dart';

class ConnectionSQL {
  static const CREATE_TASK = ''' 
  CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title text,
    description text,
    status char(1),
    audioDirectory text 
 );
 ''';

  static String getAll() {
    return 'SELECT * FROM tasks;';
  }

  static String updateTask(Task task) {
    return '''
      UPDATE tasks
      SET title = '${task.title}',
      description = '${task.description}',
      status = '${task.status}',
      audioDirectory = '${task.audioDirectory}'
      where id = ${task.id};
    ''';
  }

  static String updateTaskStatus(int id, String status) {
    return '''
      UPDATE tasks
      SET status = '$status'
      where id = $id;
    ''';
  }

  static String deleteTask(Task task) {
    return 'DELETE FROM tasks WHERE id = ${task.id};';
  }

  static String insert(Task task) {
    return '''
      INSERT INTO tasks (title, description, status, audioDirectory)
      VALUES ('${task.title}', '${task.description}', '${task.status}', '${task.audioDirectory}');
    ''';
  }
}