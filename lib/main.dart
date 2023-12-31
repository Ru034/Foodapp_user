import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'dart:io';
import 'main2.dart';
import 'sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for utf8
import 'dart:async'; // for Stream
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'SQL.dart';
//FoodSql shoplink = FoodSql("shoplink","storeName TEXT, storeAddress TEXT, storePhone TEXT, storeWallet TEXT, currentID TEXT, storeTag TEXT, latitudeAndLongitude TEXT, menuLink TEXT, storeEmail TEXT "); //建立資料庫

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized(); // 確保

}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  final TextEditingController Wallet = TextEditingController();
  final TextEditingController Password = TextEditingController();
  String result = "";
 //這邊要確定
  Future<http.Response> Checkacc(TextEditingController Wallet, TextEditingController Password) async {
    final Map<String, String> data = {
      'wallet': Wallet.text,
      'password': Password.text,
    };
    print(data);
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = Uri(queryParameters: data).query;
    final response = await http.post(
      Uri.parse('http://192.168.1.102:15000/checkUser'),
      headers: headers,
      body: body,
    );

    // 解析伺服器回應
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseMap = json.decode(responseBody);
      if (responseMap['result'] != null) {
        result = responseMap['result'].toString();
      }
    } else {
      result = ""; // 處理錯誤情況，將 result 設為空字串或其他值
    }
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image or Color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white],
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                  ),
                ],
              ),
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '登入',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: Wallet,
                    decoration: InputDecoration(
                      labelText: '錢包/帳號',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: Password,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Checkacc(Wallet, Password);
                      print(result);
                      if (result == "true") {
                        //await userdata.initializeDatabase(); //初始化資料庫 並且創建資料庫
                        //await shopdata.deleteallsql("shopdata");
                        final dbHelper = DBHelper();
                        await dbHelper.insertuserdata({
                          "Wallet": Wallet.text,
                          "Password": Password.text,
                        });

                        print(await dbHelper.queryalluserdata());
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>
                                main2()));
                      }
                      else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("登入失敗"),
                              content: Text("請檢查輸入是否正確"),
                            );
                          },
                        );
                      }
                    },
                    child: Text('登入'),
                  ),
                  ElevatedButton(
                    onPressed: () async{
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => sign_in()));
                      //Navigator.push(context , MaterialPageRoute(builder: (context) =>sign_in()));

                    },
                    child: Text('註冊帳號'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
