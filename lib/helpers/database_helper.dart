import 'dart:io' show Directory;
import 'package:dailycollection/models/customers_model.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

class DatabaseHelper {
  static final _databaseName = "TecAppDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'customers';

  static final columnId = 'customer_id';
  static final columnName = 'name';
  static final columnAddress = 'address';
  static final columnPhone = 'phone';
  static final columnMobile = 'mobile';
  static final columnCode = 'code';
  static final columnCompany_id = 'company_id';
  static final columnCreated_at = 'created_at';

  // make this a singleton class
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnId TEXT NOT NULL,
            $columnName TEXT NOT NULL,
            $columnAddress TEXT,
            $columnPhone TEXT,
            $columnMobile TEXT,
            $columnCode TEXT,
            $columnCompany_id TEXT,
            $columnCreated_at TEXT
          )
          ''');
  }

  Future<void> insertCustomer(Customer customer) async {
    updateCustomer(customer).then((value) {
      if (value != null && value != 1) {
        insert(customer);
      }
    });
  }

  Future<int> updateCustomer(Customer customer) async {
    final Database db = await database;
    var res = await db.update(table, customer.toMap(),
        where: "$columnCompany_id = ? AND $columnId = ?",
        whereArgs: [customer.company_id, customer.customer_id]);
    return res;
  }

  Future<int> insert(Customer customer) async {
    final Database db = await database;
    return await db.insert(
      table,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Customer>> getCustomers(company_id) async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM $table WHERE $columnCompany_id = \'$company_id\' ORDER BY $columnName ASC');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return Customer(
          customer_id: maps[i]['customer_id'],
          name: maps[i]['name'],
          address: maps[i]['address'],
          phone: maps[i]['phone'],
          mobile: maps[i]['mobile'],
          code: maps[i]['code'],
          company_id: maps[i]['company_id'],
          created_at: maps[i]['created_at']);
    });
  }

  Future<dynamic> getLatestCustomer(company_id) async {
    // Get a reference to the database.
    final Database db = await database;
    var result;
    result = await db.rawQuery(
        'SELECT $columnCreated_at FROM $table WHERE $columnCompany_id = \'$company_id\' ORDER BY $columnCreated_at DESC LIMIT 1');
    return result;
  }

  Future<dynamic> deleteAllFromTable() async {
    // Get a reference to the database.
    final Database db = await database;
    var result;
    result = await db.rawQuery('DELETE FROM $table');
    return result;
  }
}
