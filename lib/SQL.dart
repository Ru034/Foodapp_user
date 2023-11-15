import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class FoodSql {
  late String table_name;
  late String createsql_value;
  late Database database;
  Future<void> initializeDatabase() async { //初始化資料庫  並且創建資料庫
    database =await openDatabase(
      join(await getDatabasesPath(), 'foodsql.db'),
      onCreate: (db, version) {return db.execute('CREATE TABLE $table_name($createsql_value)');},
      version: 1,
    ) ;
  }

  //使用時要放這段程式碼
  //FoodSql shopdata = FoodSql("shopdata","storeWallet TEXT, contractAddress TEXT"); //建立資料庫
  //await shopdata.initializeDatabase(); //初始化資料庫 並且創建資料庫


  //FoodSql shopdata = FoodSql("shopdata","storeWallet TEXT, contractAddress TEXT"); //建立資料庫
  FoodSql(this.table_name,this.createsql_value) ; //建構子




  Future<void> insertsql(String table,Map<String, dynamic> mapvalue) async { //插入資料
      await database.insert(
        table, // 确保表名正确
        mapvalue,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    //await shopdata.insertsql("shopdata",{"storeWallet": storeWallet.text,"contractAddress":contractAddress.text}); //插入資料
  }


  Future<void> deletesql(String table,String deleteparameter,String deletevalute) async { //刪除資料
    print(deleteparameter) ;
    print(deletevalute) ;
    await database.delete(
      table, // 确保表名正确
      where: '$deleteparameter = ?',
      whereArgs: [deletevalute],
    );
    //await shopdata.deletesql("shopdata","contractAddress",contractAddress.text); //刪除資料
  }


  Future<void> updatesql(String table,String updateparameter,String updatevalute,String updateparameter2,String updatevalute2) async { //更新資料
    await database.update(
      table,
      {updateparameter: updatevalute,updateparameter2: updatevalute2},
      where: '$updateparameter = ?',
      whereArgs: [updatevalute],
    );
    //await shopdata.updatesql("shopdata", "contractAddress", contractAddress.text, "storeWallet", storeWallet.text); //更新資料
  }


  Future<List<Map<String, dynamic>>> querytosql(String table,String queryparameter,String queryvalute) async {   //查詢單筆資料
    var maps = await database.query(
      table,
      where: '$queryparameter = ?',
      whereArgs: [queryvalute],
    );
    return maps;
    //print(await shopdata.querytosql("shopdata","contractAddress",contractAddress.text)); //查詢單筆資料
  }


  dynamic querytsql(String table) async {   //查詢所有資料
    var maps = await database.query(table);
    return maps;
    //print(await shopdata.querytsql("shopdata")); //查詢所有資料
  }
  Future<void> deleteallsql(String table) async { //刪除資料
    await database.delete(
      table, // 确保表名正确
    );
    //await shopdata.deleteallsql("shopdata"); //刪除資料
  }
  //讀取最後一筆資料
  Future<Map<String, dynamic>> querylastsql(String table) async {
    var maps = await database.query(
      table, // 修改資料庫表的名稱為 'shopdata'
      orderBy: "ROWID DESC", // 使用 ROWID 或其他合適的欄位進行降序排序
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first; // 返回最後一筆資料，如果有的話
    } else {
      return {}; // 如果資料為空，返回一個空的 Map
    }
  }




}


