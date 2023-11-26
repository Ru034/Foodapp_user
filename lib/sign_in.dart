
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

class sign_in extends StatelessWidget {
  const sign_in ({Key? key}) : super(key: key);


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
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = new http.Client();

  GoogleAuthClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}


class HomePage extends StatefulWidget {
  //const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //HomePage 的狀態類別，用於管理狀態變化

  TextEditingController Password = TextEditingController(); //密碼
  String account  = ""; //店家錢包
  String Wallet  =""; //店家錢包



  Future<void> showWalletDialog(BuildContext context, String wallet) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('申請成功'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('帳號為: $wallet'),
                // You can add more content as needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<http.Response> createAlbum1(String title, TextEditingController passwordController) {
    final Map<String, String> data = {
      'title': title,
      'password': passwordController.text,
    };
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = Uri(queryParameters: data).query;
    return http.post(
      Uri.parse('http://192.168.1.102:15000/createAccount'),
      headers: headers,
      body: body,
    );
  }
  Future<void> getaccout() async {
    try {
      final response = await createAlbum1("My Album Title", Password);
      if (response.statusCode == 200) {
        print("Response data: ${response.body}");
        // 將回應的值設置到 _storeWallet 控制器中
        account = response.body;
      } else {
        // 請求失敗，處理錯誤
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (error) {
      // 處理錯誤
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text("Blofood"),
      ),
      */

        body: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(context , MaterialPageRoute(builder: (context) => MyApp()));
                  },
                  child: Text("回登入頁面"),
                ),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "註冊帳號",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "密碼:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: Password,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    ElevatedButton(
                      onPressed: () async {
                        await getaccout();
                        Map<String, dynamic> data = json.decode(account);
                        Wallet= data["account"];
                        showWalletDialog(context, Wallet);
                        //FoodSql userdata = FoodSql("userdata","Wallet TEXT, Password TEXT "); //建立資料庫
                        final dbHelper = DBHelper();
                        await dbHelper.insertuserdata({
                          "Wallet": Wallet,
                          "Password": Password.text
                        });

                        print(await dbHelper.queryalluserdata());
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>
                                main2()));
                        //_storeWallet
                      },
                      child: Text("取得錢包並登入"),
                    ),
                  ],
                ),
                /*
                ElevatedButton(
                  onPressed: () async {
                    if(Wallet!=""&& Password.text!=""){
                      FoodSql userdata = FoodSql("userdata","Wallet TEXT, Password TEXT "); //建立資料庫
                      await userdata.initializeDatabase(); //初始化資料庫 並且創建資料庫
                      //await shopdata.deleteallsql("shopdata");
                      await userdata.insertsql("userdata",{"Wallet": Wallet,"Password":Password.text});
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) =>
                              main2()));
                      //showRegistrationSuccessDialog(context, contractAddress2);
                    }
                    else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("註冊失敗"),
                            content: Text("請記得填寫所有資訊"),
                          );
                        },
                      );

                    }
                  },
                  child: Text("快速登入"),
                ),

                 */
              ],
            ),
          ],
        ));
  }
}

