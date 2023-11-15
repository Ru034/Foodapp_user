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
  TextEditingController storeName   = TextEditingController(); //店家名稱
  TextEditingController storePassword = TextEditingController(); //密碼
  TextEditingController storeAddress  = TextEditingController(); //店家地址
  TextEditingController storePhone  = TextEditingController(); //店家電話
  String account  = ""; //店家錢包
  TextEditingController storeTag = TextEditingController(); //店家標籤
  TextEditingController latitudeAndLongitude  = TextEditingController(); //店家經緯度
  TextEditingController menuLink  = TextEditingController(); //菜單連結
  TextEditingController storeEmail  = TextEditingController(); //菜單連結
  String storeWallet  =""; //店家錢包
  late String contractAddress  ; //上傳合約
  Map<String, double> latitudeAndLongitude_no = {
    "latitude": 0.0,
    "longitude": 0.0,
  };
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
  // Function to show the registration dialog
  Future<void> showRegistrationSuccessDialog(BuildContext context, String contractAddress) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('註冊成功'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                //Text('Your registration is successful!'),
                Text('位置為: $contractAddress'),
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
      final response = await createAlbum1("My Album Title", storePassword);
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


  Future<http.Response> createAlbum2(  TextEditingController storePasswordController  ,TextEditingController storeNameController, TextEditingController storeAddressController, TextEditingController storePhoneController,String storeWalletController
      ,TextEditingController storeTagController ,TextEditingController latitudeAndLongitudeController,TextEditingController menuLinkController,TextEditingController storeEmailController) {
    final Map<String, String> data = {
      'storePassword' : storePasswordController.text,
      'storeName' : storeNameController.text,
      'storeAddress' : storeAddressController.text,
      'storePhone' : storePhoneController.text,
      'storeWallet' : storeWalletController,
      'storeTag' : storeTagController.text,
      'latitudeAndLongitude' : latitudeAndLongitudeController.text,
      'menuLink' : menuLinkController.text,
      'storeEmail' : storeEmailController.text,
    };
    print(data);
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = Uri(queryParameters: data).query;
    return http.post(
      Uri.parse('http://192.168.1.102:15000/deploy'),
      headers: headers,
      body: body,
    );
  }
  Future<void> register() async { //todo
    try {
      final response = await createAlbum2( storePassword,storeName,storeAddress,storePhone,storeWallet,storeTag,latitudeAndLongitude,menuLink,storeEmail);
      if (response.statusCode == 200) {
        print("Response data: ${response.body}");
        // 將回應的值設置到 _storeWallet 控制器中
        contractAddress = response.body;
      } else {
        // 請求失敗，處理錯誤
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (error) {
      // 處理錯誤
      print("Error: $error");
    }
  }


  Future<void> getCoordinates() async {
    String address = storeAddress.text; // Get the address
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations != null && locations.length > 0) {
        Location location = locations.first;
        latitudeAndLongitude_no["latitude"] = location.latitude;
        latitudeAndLongitude_no["longitude"] = location.longitude;
        print('Latitude: ${location.latitude}, Longitude: ${location.longitude}');
        setState(() {
          latitudeAndLongitude.text = "${latitudeAndLongitude_no['latitude']} ${latitudeAndLongitude_no['longitude']}";
        });
      } else {
        print('No location found for this address.');
      }
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  Future<void> _incrementCounter() async {
    final googleSignIn = signIn.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
    final signIn.GoogleSignInAccount? account = await googleSignIn.signIn();

    if (account != null) {
      final authHeaders = await account.authHeaders;

      if (authHeaders != null) {
        final authenticateClient = GoogleAuthClient(authHeaders);
        final driveApi = drive.DriveApi(authenticateClient);

        final folderMetadata = drive.File()
          ..name = "flutter_menu"
          ..mimeType = "application/vnd.google-apps.folder";

        final folder = await driveApi.files.create(folderMetadata);

        if (folder.id != null) {
          // Get the temp directory of the app
          final Directory tempDir = await getTemporaryDirectory();

          // Load the CSV file from assets
          final ByteData data = await rootBundle.load('assets/菜單.csv');
          final List<int> bytes = data.buffer.asUint8List();


          final permission = drive.Permission()
            ..type = "anyone"
            ..role = "reader";

          await driveApi.permissions.create(permission, folder.id!);

          final folderUrl = "https://drive.google.com/drive/folders/${folder.id}";
          menuLink.text = folder.id!;
        }
      }
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
                    "店家資訊",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Store Name
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "店名:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: storeName,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Addres
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "地址:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: storeAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Phone Number
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "電話:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: storePhone,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Wallet
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
                        controller: storePassword,
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
                        storeWallet= data["account"];
                        showWalletDialog(context, storeWallet);
                        //_storeWallet
                      },
                      child: Text("取得錢包"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "信箱:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: storeEmail,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "標籤:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child: TextField(
                        controller: storeTag,
                        decoration: InputDecoration(
                          labelText: "每一項請用空格隔開",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, left: 20.0, bottom: 15),
                      child: Text(
                        "google連接:",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between text and input field
                    Expanded(
                      child:
                      ElevatedButton(
                        onPressed: () async {
                          _incrementCounter();
                        },
                        child: Text("連接雲端帳號"),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {

                    if(storeWallet!="" && storeName.text!="" && storePassword.text!="" && storeAddress.text!="" && storePhone.text!="" && storeTag.text!=""  && menuLink.text!=""&& storeEmail.text!=""){
                      await getCoordinates();
                      print(storeName.text); //店家名稱
                      print(storePassword.text); //店家密碼
                      print(menuLink.text); //菜單連結
                      print(storePhone.text); //店家電話
                      print(storeWallet); //店家錢包
                      print(storeTag.text); //店家標籤
                      print(latitudeAndLongitude.text);  //店家經緯度
                      print(menuLink.text); //菜單連結
                      print(storeEmail.text); //菜單連結
                      await register();
                      //print (contractAddress); //店家合約位置ㄈ
                      Map<String, dynamic> contractAddressdata = json.decode(contractAddress as String);
                      String contractAddress2 = contractAddressdata['contractAddress'];
                      bool addContractStatus = contractAddressdata['addContractStatus'];
                      print('contractAddress=$contractAddress2');
                      print('addContractStatus=$addContractStatus');
                      await shopdata.initializeDatabase(); //初始化資料庫 並且創建資料庫
                      //await shopdata.deleteallsql("shopdata");
                      await shopdata.insertsql("shopdata2",{"storeWallet": storeWallet,"contractAddress":contractAddress2,"storePassword":storePassword.text});
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
                  child: Text("送出 "),
                ),
              ],
            ),
          ],
        ));
  }
}

