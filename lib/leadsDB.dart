import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LeadsDB {
  static final _databaseName = "LeadsDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'leads';
  static final id = 'id';
  static final date = 'date';
  static final number = 'number';

  LeadsDB._privateConstructor();
  static final LeadsDB instance = LeadsDB._privateConstructor();
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
            $date TEXT,
            $number TEXT
          )
          ''');
  }
}
