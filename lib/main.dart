import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/drive/v3.dart' show Media;
import 'package:file_picker/file_picker.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert'; // for utf8
import 'dart:async'; // for Stream
import 'shopmenu.dart';
import 'main2.dart';

/*
app:foodapp
package:com.example.foodapp
Launcher:com.example.foodapp.MainActivity
SHA1: 83:4D:3C:8A:4C:BB:10:13:48:81:E5:F3:EA:8D:E9:19:1B:0F:CC:B1
 */
//增加從雲端抓資料與輸出資料


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
  //HomePage 的狀態類別，用於管理狀態變化
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //HomePage 的狀態類別，用於管理狀態變化
  List<List<dynamic>> _data = [];

  get auth2 => null;


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
              crossAxisAlignment: CrossAxisAlignment.start, // 將子元素靠左對齊
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(context , MaterialPageRoute(builder: (context) =>main2()));
                  },
                  child: Text("打開店家"),
                ),
                /*
                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(context , MaterialPageRoute(builder: (context) =>sign_in()));
                  },
                  child: Text("註冊"),
                ),
                 */
              ],
            ),
          ],
        ));
  }
}
