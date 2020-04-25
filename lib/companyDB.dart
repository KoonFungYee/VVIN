import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class CompanyDB {
  static final _databaseName = "CompanyDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'details';
  static final id = 'id';
  static final name = 'name';
  static final phone = 'phone';
  static final email = 'email';
  static final website = 'website';
  static final address = 'address';

  CompanyDB._privateConstructor();
  static final CompanyDB instance = CompanyDB._privateConstructor();
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
            $phone TEXT,
            $email TEXT,
            $website TEXT,
            $address TEXT
          )
          ''');
  }
}
