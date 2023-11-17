import 'package:flutter/material.dart';
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
import 'SQL.dart';
class RecommendPage extends StatefulWidget {
  const RecommendPage({Key? key}) : super(key: key);

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late String user_Wallet;
  late String user_Password;
  Future<void> getdata() async {
    //取得shopdata最後一筆資料
    FoodSql userdata = FoodSql("userdata", "Wallet TEXT, Password TEXT");
    await userdata.initializeDatabase();
    Map<String, dynamic>? lastShopData = await userdata
        .querylastsql("userdata"); // 使用 Map<String, dynamic>? 接收返回值
    if (lastShopData != null) {
      // 檢查是否返回了資料
      user_Wallet = lastShopData['Wallet'].toString();
      user_Password = lastShopData['Password'].toString();
    }
  }
  late String menuVersion  ; //取得menu版本
  Future<void> menuid(String shop_storeWallet, String shop_contractAddress) async {
    final Map<String, String> data = {
      'contractAddress': shop_contractAddress,
      'wallet': shop_storeWallet,
    };
    print(data);
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = Uri(queryParameters: data).query;
    final response = await http.post(
      Uri.parse('http://192.168.1.102:15000/contract/getMenuVersion'),
      headers: headers,
      body: body,
    );
    late String menuid;
    if (response.statusCode == 200) {
      menuid = response.body; // 將整個 API 回傳的內容直接賦值給 storeName
      Map<String, dynamic> jsonData = jsonDecode(menuid);
      menuVersion = jsonData['menuVersion'] ?? '';
      print("menuVersion: $menuVersion");
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }
  List<String> storeNameList = [
  ];
  List<String> storePriceList = [
  ];
  List<String> storeDistanceList = [
  ];
  _RecommendPageState() {
    storeNameList.add("麥當勞");
  }
  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(

        body: Stack(
          children: [
            ListView(
              children: [
                Padding(padding: EdgeInsets.only(
                    left: 30, top: 30, right: 30, bottom: 120), child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Blo",
                            style: titleStyle.copyWith(
                                color: Colors.red[900])),
                        Text("food",
                            style: titleStyle.copyWith(
                                color: Colors.black87)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await getdata();
                        print(user_Wallet);
                        print(user_Password);
                      },
                      child: Text("測試"),
                    ),
                    SizedBox(height: 30),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: 2.0,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        return SizedBox(
                            height: 100,
                            width: 200,
                            child: Card(
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  splashColor: Colors.brown.withAlpha(75),
                                  onTap: () {},
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        storeNameList[index],
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      Text(
                                        storePriceList[index],
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        storeDistanceList[index],
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                )));

                      },
                    ),
                  ],
                ),)
              ],
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child:
              Padding(
                  padding: EdgeInsets.only(
                      left: 30, top: 0, right: 30, bottom: 15),
                  child: SearchBar(
                    padding: const MaterialStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 16.0)),
                    leading: const Icon(Icons.search),
                    hintText: '搜尋店家',
                  )
              ),

            )
          ],
        )


    );
  }
}
