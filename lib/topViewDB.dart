import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class TopViewDB {
  static final _databaseName = "TopViewDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'topview';
  static final id = 'id';
  static final name = 'name';
  static final status = 'status';
  static final channel = 'channel';
  static final views = 'views';
  
  TopViewDB._privateConstructor();
  static final TopViewDB instance = TopViewDB._privateConstructor();
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
            $name TEXT,
            $status TEXT,
            $channel TEXT,
            $views TEXT
          )
          ''');
  }
}
