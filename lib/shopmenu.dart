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

//增加從雲端抓資料與輸出資料
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = new http.Client();

  GoogleAuthClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/*
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const shopmenu());
}
*/
class shopmenu extends StatelessWidget {
  const shopmenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //返回一個 MaterialApp Widget，該Widget定義了應用程式的主題和首頁
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

Future<String> loadAsset() async {
  //這是一個用來非同步讀取資源的方法，返回一個表示CSV檔案內容的字串
  return await rootBundle.loadString('assets/file.csv');
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //HomePage 的狀態類別，用於管理狀態變化
  List<List<dynamic>> _data = [];

  get auth2 => null;

  Future<void> saveCsvToNewDirectory() async {
    try {
      final String csvContent = const ListToCsvConverter().convert(_data);

      final Directory newDirectory =
          Directory('/data/user/0/com.example.foodapp_user/new');
      final file = File('${newDirectory.path}/new_data.csv');

      // Write the CSV content to the new directory
      await file.writeAsString(csvContent);

      print('CSV data saved to new directory: ${file.path}');
    } catch (e) {
      print('Error saving CSV data: $e');
    }
  }

  @override
  void initState() {
    //初始化狀態，然後調用 _loadCSV() 方法
    super.initState();
    _loadCSV();
  }

  String? _imagePath;

  void deleteDataAtIndex(int index) {
    setState(() {
      _data.removeAt(index);
    });
  }

  void addNewDataAtIndex(
      String listData, String newOption, String newPrice, int ord, int index) {
    List<dynamic> newData = [ord, "", "", listData, newOption, newPrice, ""];
    setState(() {
      _data.insert(index, newData);
    });
  }

  Future<void> saveCsvToLocalDirectory() async {
    try {
      final String csvContent = const ListToCsvConverter().convert(_data);
      final directory = Directory(
          '/data/user/0/com.example.foodapp_user/new'); // Update the path to your desired directory
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}/new_data.csv');

      // Write the CSV content to the new directory
      await file.writeAsString(csvContent);

      print('CSV data saved to new directory: ${file.path}');
    } catch (e) {
      print('Error saving CSV data: $e');
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery, // Choose from the gallery
    );

    if (pickedImage != null) {
      final imagePath = pickedImage.path;

      try {
        final newImagePath =
            '/data/user/0/com.example.foodapp_user/new/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File newImageFile = await File(imagePath).copy(newImagePath);
        setState(() {
          _imagePath = newImagePath;
          _data[index][6] =
              newImagePath; // Update _data[index][6] to include the new image path
        });
      } catch (e) {
        print('Error copying image: $e');
      }
    }
  }

  Future<void> createNewDirectory() async {
    final Directory newDirectory =
        Directory('/data/user/0/com.example.foodapp_user/new');
    if (!await newDirectory.exists()) {
      await newDirectory.create(recursive: true);
    }
  }

  Future<void> movePhotosToNewDirectory() async {
    final Directory cacheDirectory = await getTemporaryDirectory();
    final Directory newDirectory =
        Directory('/data/user/0/com.example.foodapp_user/new');

    for (final file in await cacheDirectory.list().toList()) {
      if (file is File) {
        final newFilePath =
            '${newDirectory.path}/${file.uri.pathSegments.last}';
        await file.copy(newFilePath);
      }
    }
  }

  Future<void> _incrementCounter() async {
    final googleSignIn =
        signIn.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
    final signIn.GoogleSignInAccount? account = await googleSignIn.signIn();
    print("User account $account");

    if (account != null) {
      final authHeaders = await account
          .authHeaders; //從登錄的帳戶中獲取身份驗證標頭（auth headers）。這些標頭將用於進行 Google Drive API 的身份驗證。
      if (authHeaders != null) {
        //檢查身份驗證標頭是否成功獲取。如果 authHeaders 不是 null，表示已經成功獲取身份驗證標頭。
        final authenticateClient = GoogleAuthClient(
            authHeaders); //創建一個 GoogleAuthClient，這是一個用於進行 Google API 請求的客戶端，使用先前獲取的身份驗證標頭進行身份驗證。
        final driveApi = drive.DriveApi(
            authenticateClient); //創建一個 Google Drive API 客戶端，使用 GoogleAuthClient 進行身份驗證。

        // 在 Google Drive 上建立 "flutter_menu" 資料夾
        final folderMetadata = drive
            .File() //創建一個表示 Google Drive 上資料夾的元數據（metadata）。這個資料夾的名稱是 "flutter_menu"，並設定了 MIME 類型為 Google Drive 資料夾。
          ..name = "flutter_menu"
          ..mimeType = "application/vnd.google-apps.folder";

        final folder = await driveApi.files.create(
            folderMetadata); //使用 Google Drive API 創建一個名為 "flutter_menu" 的資料夾，並獲取創建後的資料夾對象。
        if (folder.id != null) {
          //檢查創建資料夾操作是否成功，如果成功，則繼續執行後續操作。
          // 指定本地文件夾路徑
          final localFolderPath =
              '/data/user/0/com.example.foodapp_user/new'; //定義了本地文件夾的路徑，這個文件夾中的內容將被上傳到 Google Drive 的
          // 上傳文件夾中的內容到 "flutter_menu" 資料夾
          await _uploadFolderContents(driveApi, localFolderPath,
              parentFolderId: folder
                  .id); //調用 _uploadFolderContents 函數，該函數似乎用於上傳本地文件夾的內容到 Google Drive 的資料夾中，並將 Google Drive 資料夾的ID作為參數傳遞。

          final permission = drive.Permission()
            ..type = "anyone"
            ..role = "reader";
          await driveApi.permissions.create(permission, folder.id!);
          // 获取文件夹的 URL
          final folderUrl =
              "https://drive.google.com/drive/folders/${folder.id}";
          print("Folder URL: $folderUrl");
        }
      } else {
        print("Auth headers are null");
      }
    } else {
      print("Account is null");
    }
  }

  Future<void> _uploadFolderContents(
      drive.DriveApi driveApi, String localFolderPath,
      {String? parentFolderId}) async {
    final dir = Directory(localFolderPath);

    if (dir.existsSync()) {
      for (final fileSystemEntity in dir.listSync()) {
        if (fileSystemEntity is File) {
          // 上傳文件
          final driveFile = drive.File();
          driveFile.name = fileSystemEntity.uri.pathSegments.last;

          if (parentFolderId != null) {
            // Check if parentFolderId is not null
            driveFile.parents = [parentFolderId];
          }

          final media =
              Media(fileSystemEntity.openRead(), fileSystemEntity.lengthSync());
          final result =
              await driveApi.files.create(driveFile, uploadMedia: media);
          print("Uploaded ${driveFile.name}: ${result.toJson()}");
        } else if (fileSystemEntity is Directory) {
          // 上傳子文件夾
          final driveFolder = drive.File();
          driveFolder.name = fileSystemEntity.uri.pathSegments.last;

          if (parentFolderId != null) {
            // Check if parentFolderId is not null
            driveFolder.parents = [parentFolderId];
          }

          driveFolder.mimeType = 'application/vnd.google-apps.folder';

          final result = await driveApi.files.create(driveFolder);
          print("Created folder ${driveFolder.name}: ${result.toJson()}");

          // 遞迴上傳子文件夾的內容
          await _uploadFolderContents(driveApi, fileSystemEntity.path,
              parentFolderId: result.id);
        }
      }
    }
  }

  Future<void> _download() async {
    final googleSignIn =
        signIn.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
    final signIn.GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account != null) {
      final authHeaders = await account.authHeaders;
      if (authHeaders != null) {
        final authenticateClient = GoogleAuthClient(authHeaders);
        final driveApi = drive.DriveApi(authenticateClient);
        final googleDriveFolderId =
            '1cOKclriMA8y4dnvbqgRr3szq8NZUiYEX'; //Todo 解決取得google drive裡檔案id的問題
        //https://drive.google.com/drive/folders/1cOKclriMA8y4dnvbqgRr3szq8NZUiYEX?usp=drive_link
        //11JVW4Y1LkucKj3g9ATvspEBfcgoBibL3
        final localFolderPath = '/data/user/0/com.example.foodapp_user/new';
        final directory = Directory(localFolderPath);
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
        directory.createSync(recursive: true);
        final fileList =
            await driveApi.files.list(q: "'$googleDriveFolderId' in parents");
        for (final file in fileList.files!) {
          final drive.Media fileData = await driveApi.files.get(file.id!,
              downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
          final Stream<List<int>> stream = fileData.stream;
          final localFile = File('$localFolderPath/${file.name}');
          final IOSink sink = localFile.openWrite();
          await for (final chunk in stream) {
            sink.add(chunk);
          }
          await sink.close();
        }
      } else {
        print("Auth headers are null");
      }
    } else {
      print("Account is null");
    }
  }

/*
  void _loadCSV() async {
    final rawData = await rootBundle.loadString("assets/M1.csv");
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    setState(() {
      _data = listData;
    });
  }

*/

  Future<void> _loadCSV() async {
    await _download();
    try {
      final File file =
          File('/data/user/0/com.example.foodapp_user/new/new_data.csv');

      // Check if the file exists in the app's data directory
      if (await file.exists()) {
        final String rawData = await file.readAsString();
        final List<List<dynamic>> listData =
            const CsvToListConverter().convert(rawData);

        setState(() {
          _data = listData;
        });
      } else {
        // If the file doesn't exist in the app's data directory, copy it from assets
        final rawData = await rootBundle.loadString("assets/new_data.csv");
        List<List<dynamic>> listData =
            const CsvToListConverter().convert(rawData);
        setState(() {
          _data = listData;
        });
      }
    } catch (e) {
      print('Error loading CSV file: $e');
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

      body: Column(children: [
        Expanded(
            child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 將子元素靠左對齊
              children: [
                const Padding(
                  padding: EdgeInsets.all(15),
                ),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "店家菜單",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 15, left: 30.0, bottom: 15),
                  //const EdgeInsets.only(left: 40.0)
                  child: Text(
                    "單點",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (int index = 0; index < _data.length; index++)
                  if (_data[index][0] == 1 && (index > 0 && _data[index][3] != _data[index - 1][3]))
                    ListTile(
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                //新增圖片
                                child: Row(
                                  children: [
                                    if (index == 0 && _data[index][6] != "" && index == 0 || (_data[index][3] != _data[index - 1][3] && index > 0 && _data[index][6] != ""))
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Image.file(
                                              File(_data[index][6]),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_data[index][3].toString()),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 0, left: 20.0, bottom: 0),
                                  ),
                                  Text(_data[index][5].toString()),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 0, left: 10.0, bottom: 0),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      //todo
                                    },
                                    child: const Icon(
                                        Icons.add_circle_outline_sharp,
                                        color: Colors.blue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                const Padding(
                  padding: EdgeInsets.only(left: 30.0),
                  //const EdgeInsets.only(left: 40.0)
                  child: Text(
                    "套餐",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (int index = 0; index < _data.length; index++)
                  if (_data[index][0] == 2)
                    ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 30.0),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    if (index == 0 ||(index > 0&&_data[index][3] != _data[index - 1][3]))
                                      Text(_data[index][3].toString()),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(_data[index][5].toString()),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 30.0),
                                    ),
                                    Text(_data[index][4].toString()),
                                    if (_data.length - 1 == index||(_data[index][3] !=_data[index + 1][3]&&_data.length - 1 > index))
                                        TextButton(
                                          onPressed: () {
                                            //todo
                                          },
                                          child: const Icon(
                                              Icons.add_circle_outline_sharp,
                                              color: Colors.blue),
                                        ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        )),
        SizedBox(
          height: 75,
          width: 250,
          child: FilledButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(16.0),
              textStyle: const TextStyle(fontSize: 20),
            ),
            onPressed: () async {
              // Your onPressed logic for the FilledButton
            },
            child: const Text('打開購物車'),
          ),
        ),
      ]),
    );
  }
}
