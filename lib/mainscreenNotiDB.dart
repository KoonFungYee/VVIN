import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class MainScreenNotiDB {
  static final _databaseName = "MainScreenNotiDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'mainnoti';
  static final id = 'id';
  static final number = 'number';

  MainScreenNotiDB._privateConstructor();
  static final MainScreenNotiDB instance = MainScreenNotiDB._privateConstructor();
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
            $number TEXT
          )
          ''');
  }
}
