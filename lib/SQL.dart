import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
//final dbHelper = DBHelper(); // 建立 DBHelper 物件

class DBHelper {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'foodsql.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 建立 stores 表格
        /*
        await db.execute(
        'CREATE TABLE userdata(Wallet TEXT, Password TEXT )',
          );

         */
        await db.execute('''
          CREATE TABLE IF NOT EXISTS storedata(storeName TEXT, storeAddress TEXT, storePhone TEXT, storeWallet TEXT, currentID TEXT, storeTag TEXT, latitudeAndLongitude TEXT, menuLink TEXT, storeEmail TEXT,shopcontractAddress TEXT)
        ''');
        // 建立 consumers 表格
        await db.execute('''
          CREATE TABLE IF NOT EXISTS userdata(Wallet TEXT, Password TEXT )
        ''');
      },
    );
  }

  // 表格中插入資料
  Future<void> insertstoredata(Map<String, dynamic> storedata) async {
    final db = await database;
    await db.insert('storedata', storedata);
  }
  Future<void> insertuserdata(Map<String, dynamic> userdata) async {
    final db = await database;
    await db.insert('userdata', userdata);
  }


  // 更新資料
  Future<void> updatestoredata(String updateparameter,String updatevalute,String updateparameter2,String updatevalute2) async {
    final db = await database;
    await db.update(
      'storedata',
      {updateparameter: updatevalute,updateparameter2: updatevalute2},
      where: '$updateparameter = ?',
      whereArgs: [updatevalute],
    );
  }
  Future<void> updateuserdata(String updateparameter,String updatevalute,String updateparameter2,String updatevalute2) async {
    final db = await database;
    await db.update(
      'userdata',
      {updateparameter: updatevalute,updateparameter2: updatevalute2},
      where: '$updateparameter = ?',
      whereArgs: [updatevalute],
    );
  }


  // 刪除資料
  Future<void> deletestoredata(String deleteparameter,String deletevalute) async {
    final db = await database;
    await db.delete(
      'storedata',
      where: '$deleteparameter = ?',
      whereArgs: [deletevalute],
    );
  }
  Future<void> deleteuserdata(String deleteparameter,String deletevalute) async {
    final db = await database;
    await db.delete(
      'userdata',
      where: '$deleteparameter = ?',
      whereArgs: [deletevalute],
    );
  }

  // 查詢資料
  Future<List<Map<String, dynamic>>> querystoredata(String queryparameter,String queryvalute) async {
    final db = await database;
    return await db.query(
      'storedata',
      where: '$queryparameter = ?',
      whereArgs: [queryvalute],
    );
  }
  Future<List<Map<String, dynamic>>> queryuserdata(String queryparameter,String queryvalute) async {
    final db = await database;
    return await db.query(
      'userdata',
      where: '$queryparameter = ?',
      whereArgs: [queryvalute],
    );
  }


  // 查詢所有資料
  Future<List<Map<String, dynamic>>> queryallstoredata() async {
    final db = await database;
    return await db.query('storedata');
  }
  Future<List<Map<String, dynamic>>> queryalluserdata() async {
    final db = await database;
    return await db.query('userdata');
  }


  // 讀取最後一筆資料
  Future<Map<String, dynamic>> querylaststoredata() async {
    final db = await database;
    var maps = await db.query(
      'storedata', // 修改資料庫表的名稱為 'storedata'
      orderBy: "ROWID DESC", // 使用 ROWID 或其他合適的欄位進行降序排序
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first; // 返回最後一筆資料，如果有的話
    } else {
      return {}; // 如果資料為空，返回一個空的 Map
    }
  }
  Future<Map<String, dynamic>> querylastuserdata() async {
    final db = await database;
    var maps = await db.query(
      'userdata', // 修改資料庫表的名稱為 'storedata'
      orderBy: "ROWID DESC", // 使用 ROWID 或其他合適的欄位進行降序排序
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first; // 返回最後一筆資料，如果有的話
    } else {
      return {}; // 如果資料為空，返回一個空的 Map
    }
  }



  // 刪除資料表
  Future<void> deletestoredatatable() async {
    final db = await database;
    await db.delete('storedata');
  }
  Future<void> deleteuserdatatable() async {
    final db = await database;
    await db.delete('userdata');
  }

  // 關閉資料庫
  Future<void> closedatabase() async {
    final db = await database;
    await db.close();
  }



}

