import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:to_do/dao/sql.dart';
import 'dart:io' as s;

class ConnectionSQLiteService {
  ConnectionSQLiteService._();

  static ConnectionSQLiteService? _instance;

  static ConnectionSQLiteService get instance {
    _instance ??= ConnectionSQLiteService._();
    return _instance!;
  }

  static const DATABASE_NAME = 'to_do.db';
  static const DATABASE_VERSION = 1;
  Database? _db;

  Future<Database> get db => openDatabase();

  Future<Database> openDatabase() async {
    sqfliteFfiInit();

    String databasePath = join(s.File(s.Platform.resolvedExecutable).parent.path, 'database'); //await databaseFactoryFfi.getDatabasesPath();
    String path = join(databasePath, DATABASE_NAME);
    DatabaseFactory databaseFactory = databaseFactoryFfi;

    _db ??= await databaseFactory.openDatabase(path, options: OpenDatabaseOptions(
        onCreate: _onCreate,
          version: DATABASE_VERSION,
      ));

    return _db!;
  }

  FutureOr<void> _onCreate(Database db, int version) {
    db.transaction((txn) async {
      txn.execute(ConnectionSQL.CREATE_TASK);
    });
  }
}