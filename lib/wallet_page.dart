
import 'package:googleapis/appengine/v1.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:http/http.dart' as http;
import 'dart:async'; // for Stream
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert';
import 'main.dart';
import 'main2.dart';
import 'SQL.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //返回一個 MaterialApp Widget，該Widget定義了應用程式的主題和首頁
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  //const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
  late String user_Wallet;
  late String user_Password;
  Future<void> getdata() async {
    //取得shopdata最後一筆資料
    final dbHelper = DBHelper(); // 建立 DBHelper 物件
    Map<String, dynamic>? lastShopData = await dbHelper.querylastuserdata(); // 使用 Map<String, dynamic>? 接收返回值
    if (lastShopData != null) {
      // 檢查是否返回了資料
      user_Wallet = lastShopData['Wallet'].toString();
      user_Password = lastShopData['Password'].toString();
    } else {
      // 處理沒有資料的情況，例如給予預設值或者處理其他邏輯
    }
    // print(await shopdata.querytsql("shopdata"));
    // print("000000000000000000000000000000000000000000000");
    // print("shop_storeWallet: $shop_storeWallet");
    // print("shop_contractAddress: $shop_contractAddress");
  }


  String money ="0"; //計算餘額
  Future<void> getmoney(String Wallet) async {
    final Map<String, String> data = {
      'account': Wallet,
    };
    print(data);
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = Uri(queryParameters: data).query;
    final response = await http.post(
      Uri.parse('http://192.168.1.102:15000/getBalance'),
      headers: headers,
      body: body,
    );
    late String money2;
    if (response.statusCode == 200) {
      money2 = response.body; // 將整個 API 回傳的內容直接賦值給 storeName
      Map<String, dynamic> jsonData = jsonDecode(money2);
      money = jsonData['balance'] ?? '';
      print("money: $money");
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }
  Future<void> _initializeData() async {
    await getdata();
    await getmoney(user_Wallet);
    setState(() {
      money;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "錢包:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user_Wallet,
                style: TextStyle(fontSize: 15),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "餘額:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    //Todo 從API抓值
                    money,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(width: 5),
                  Text(
                    "wei",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "交易明細",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 這裡可以加入交易明細的部分，顯示交易紀錄等等
          ],
        ),
      ),
    );
  }
}
