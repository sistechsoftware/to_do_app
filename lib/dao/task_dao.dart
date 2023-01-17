import 'package:sqflite/sqflite.dart';
import 'package:to_do/dao/sql.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/services/connection_sqlite_service.dart';

class TaskDao {
  ConnectionSQLiteService _connection = ConnectionSQLiteService.instance;

  Future<Database> _getDatabase() async {
    return await _connection.db;
  }

  Future<Task> addNewTask(Task task) async {
    try {
      Database db = await _getDatabase();
      String description = task.description.replaceAll("'", "");
      task.description = description;
      String sql = ConnectionSQL.insert(task);
      int id = await db.rawInsert(sql);
      task.id = id;

      return task;
    } catch(error) {
      throw Exception();
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      Database db = await _getDatabase();
      String description = task.description.replaceAll("'", "");
      task.description = description;
      int lines = await db.rawUpdate(ConnectionSQL.updateTask(task));

      return lines > 0;
    } catch(error) {
      throw Exception();
    }
  }

  Future<List<Task>> getAll() async {
    try {
      Database db = await _getDatabase();
      List<Map> data = await db.rawQuery(ConnectionSQL.getAll());

      List<Task> tasks = Task.fromSQLiteList(data);

      return tasks;
    } catch(error) {
      throw Exception();
    }
  }

  Future<bool> delete(Task task) async {
    try {
      Database db = await _getDatabase();
      int lines = await db.rawDelete(ConnectionSQL.deleteTask(task));

      return lines > 0;
    } catch(error) {
      throw Exception();
    }
  }
}