import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class ReminderDB {
  static final _databaseName = "ReminderDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'reminder';
  static final id = 'id';
  static final datetime = 'datetime';
  static final name = 'name';
  static final phone = 'phone';
  static final remark = 'remark';
  static final status = 'status';
  static final time = 'time';
  
  ReminderDB._privateConstructor();
  static final ReminderDB instance = ReminderDB._privateConstructor();
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $id INTEGER PRIMARY KEY,
            $datetime TEXT,
            $name TEXT,
            $phone TEXT,
            $remark TEXT,
            $status TEXT,
            $time TEXT
          )
          ''');
  }
}
