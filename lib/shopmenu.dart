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
  List<List<dynamic>> _data2 = [];


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
    //_data2 = List.generate(_data.length, (index) => [0]);
    _data2 = List.generate(_data.length, (index) => [0, 0]);
  }

  String? _imagePath;

  void deleteDataAtIndex(int index) {
    setState(() {
      _data.removeAt(index);
    });
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
  List<List<int>> _data4 = [];
  void showAlertDialog(String listData, String listData2, int fir) {
    // Initialize selected items with the first item
    Map<int, bool> selectedItemsMap = {fir+1: true};

    AlertDialog dialog = AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < _data.length; index++)
            if (_data[index][3] == listData && index != fir) // Exclude the first item
              Row(
                children: [
                  if ((index > 0 && _data[index][3] != _data[index - 1][3]) ||
                      index == 0)
                    Text(listData + '      ' + listData2),
                  if ((index > 0 && _data[index][3] == _data[index - 1][3]))
                    Text(
                      _data[index][4].toString() +
                          '      ' +
                          _data[index][5].toString(),
                    ),
                  TextButton(
                    onPressed: () {
                      // Handle the toggle logic
                      toggleAlertDialogSelection2(
                        index+1,
                        selectedItemsMap,
                        updateUI: () {
                          // Force the UI to rebuild when selection changes
                          setState(() {});
                        },
                      );
                    },
                    child: Icon(
                      Icons.add_circle_outline_sharp,
                      color: selectedItemsMap.containsKey(index) &&
                          selectedItemsMap[index]!
                          ? Colors.blue // Selected color
                          : Colors.grey, // Deselected color
                    ),
                  ),
                ],
              ),
        ],
      ),
      actions: [
        ElevatedButton(
          child: Text("更新"),
          onPressed: () {
            try {
              // Convert selected items to a list of indices
              List<int> selectedIndices = selectedItemsMap.keys.toList();

              // Append selected items to _data4
              _data4.add([...selectedIndices]);

              // Access selected items using the 'selectedIndices' list
              print("Selected items indices: $selectedIndices");

              // Print _data4
              print("_data4: $_data4");

              // Add your logic to handle the selected items, e.g., add to a temporary list
              // addNewDataAtIndex(listData);

              // You can use 'selectedIndices' directly for further processing
            } catch (e) {
              print("Error in onPressed: $e");
            }
          },
        ),
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }
  void toggleAlertDialogSelection2(int index, Map<int, bool> selectedItemsMap,
      {required VoidCallback updateUI}) {
    if (selectedItemsMap.containsKey(index)) {
      // Item is already selected, remove it
      selectedItemsMap.remove(index);
    } else {
      // Item is not selected, add it
      selectedItemsMap[index] = true;
    }
    // Trigger UI update
    updateUI();
  }


  List<List<int>> _data3 = [];

  showAlertDialog2(String listData, String listData2, int index) {
    //Map<String, List<int>> selectedItemsMap = {};
    Map<String, List<int>> selectedItemsMap = {
      '0': [_data[index][2]], // Initialize with the desired value
    };

    AlertDialog dialog = AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(listData + '      ' + listData2),
          for (int innerIndex = 0; innerIndex < _data.length; innerIndex++)
            if (_data[innerIndex][3] == listData && _data[innerIndex][4] != '')
              Column(
                children: [
                  Text(_data[innerIndex][4]),
                  for (int index2 = 0; index2 < _data.length; index2++)
                    if (_data[index2][0] == 3)
                      if (_data[innerIndex][4] == _data[index2][3])
                        Row(
                          children: [
                            Text(
                              _data[index2][4] +
                                  '    ' +
                                  _data[index2][5].toString(),
                              style: TextStyle(
                                color: selectedItemsMap
                                            .containsKey(_data[index2][3]) &&
                                        selectedItemsMap[_data[index2][3]]!
                                            .contains(index2)
                                    ? Colors.blue // Selected color
                                    : Colors.black, // Default color
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Handle the toggle logic
                                toggleAlertDialogSelection(
                                  _data[index2][3],
                                  index2 + 1,
                                  selectedItemsMap,
                                  updateUI: () {
                                    // Force the UI to rebuild when selection changes
                                    setState(() {});
                                  },
                                );
                              },
                              child: Icon(
                                Icons.add,
                                color: selectedItemsMap
                                            .containsKey(_data[index2][3]) &&
                                        selectedItemsMap[_data[index2][3]]!
                                            .contains(index2)
                                    ? Colors.blue // Selected color
                                    : Colors.grey, // Deselected color
                              ),
                            ),
                          ],
                        ),
                ],
              )
        ],
      ),
      actions: [
        ElevatedButton(
          child: Text("更新"),
          onPressed: () {
            // Access selected items using the selectedItemsMap
            print(selectedItemsMap);

            // Convert the selected items to a flat list and add it to _data3
            List<int> flattenedSelectedItems =
                selectedItemsMap.values.expand((list) => list).toList();
            _data3.add(flattenedSelectedItems);

            // Add your logic to handle the selected items, e.g., add to a temporary list
            // addNewDataAtIndex(listData);

            // Print _data3
            print(_data3);
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  void toggleAlertDialogSelection(
      String category, int index, Map<String, List<int>> selectedItemsMap,
      {required VoidCallback updateUI}) {
    if (!selectedItemsMap.containsKey(category)) {
      selectedItemsMap[category] = [index];
    } else {
      if (selectedItemsMap[category]!.contains(index)) {
        // Item is already selected, remove it
        selectedItemsMap[category]!.remove(index);
      } else {
        // Item is not selected, add it and remove others in the same category
        selectedItemsMap[category] = [index];
      }
    }
    // Trigger UI update
    updateUI();
  }

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

  Future<void> _showDialog(
      List<List<dynamic>> data2, List<List<int>> data3,List<List<int>> data4) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('購物車內容'),
          content: Column(
            children: [
              // Display content of data2

              for (int i = 0; i < _data4.length; i++)
                Row(
                    mainAxisAlignment:MainAxisAlignment.center,
                    children: [
                      for (int j = 0; j < _data4[i].length; j++)
                        Row(children: [

                          if (j==0)
                            Text('${_data[_data4[i][j] - 1][3]}'),
                          Padding(
                            padding: EdgeInsets.only(top: 15, left: 10.0, bottom: 15),
                          ),
                          if (j>0)
                            Text('${_data[_data4[i][j] - 1][4]}'),
                        ]),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _data4.removeAt(i);
                          });
                        },
                        child: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                      ),
                    ]
                ),

              for (int i = 0; i < _data3.length; i++)
                Row(
                    mainAxisAlignment:MainAxisAlignment.center,
                    children: [
                  for (int j = 0; j < _data3[i].length; j++)
                    Row(children: [

                      if (_data[_data3[i][j]][0] == 2)
                        Text('${_data[_data3[i][j] - 1][3]}'),
                      Padding(
                          padding: EdgeInsets.only(top: 15, left: 10.0, bottom: 15),
                      ),
                      if (_data[_data3[i][j]][0] == 3)
                        Text('${_data[_data3[i][j] - 1][4]}'),
                    ]),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _data3.removeAt(i);
                          });
                        },
                        child: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                      ),
                ]
                )
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('關閉購物車'),
            ),
            ElevatedButton(
              onPressed: () {

                try {
                  for (int i = 0; i < _data3.length; i++) {
                    for (int j = 0; j < _data3[i].length; j++) {
                      var valueToCheck = _data3[i][j];

                      int dataIndex = _data2.indexWhere(
                        (element) => element[0] == valueToCheck,
                      );

                      if (dataIndex != -1) {
                        _data2[dataIndex][1] += 1;
                      } else {
                        _data2.add([
                          valueToCheck,
                          1
                        ]); // Add the value to _data2 with a count of 1
                      }
                    }
                  }
                  for (int i = 0; i < _data4.length; i++) {
                    for (int j = 0; j < _data4[i].length; j++) {
                      var valueToCheck = _data4[i][j];

                      int dataIndex = _data2.indexWhere(
                            (element) => element[0] == valueToCheck,
                      );

                      if (dataIndex != -1) {
                        _data2[dataIndex][1] += 1;
                      } else {
                        _data2.add([
                          valueToCheck,
                          1
                        ]); // Add the value to _data2 with a count of 1
                      }
                    }
                  }

                  print("_data2 after update: $_data2");
                } catch (e) {
                  print("Error in onPressed: $e");
                }
                for (int k = 0; k < _data2.length; k++) {
                  print("${_data2[k][0]}     ${_data2[k][1]}  ");
                  //todo API
                }

                Navigator.pop(context);
              },
              child: Text('送出訂單'),
            ),
          ],
        );
      },
    );
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
                  if (_data[index][0] == 1 &&
                          (index > 0 &&
                              _data[index][3] != _data[index - 1][3]) ||
                      index == 0)
                    ListTile(
                      subtitle: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                //新增圖片
                                child: Row(
                                  children: [
                                    if (index == 0 &&
                                            _data[index][6] != "" &&
                                            index == 0 ||
                                        (_data[index][3] !=
                                                _data[index - 1][3] &&
                                            index > 0 &&
                                            _data[index][6] != ""))
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
                                    padding: EdgeInsets.only(
                                        top: 0, left: 20.0, bottom: 0),
                                  ),
                                  Text(_data[index][5].toString()),
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        top: 0, left: 10.0, bottom: 0),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      showAlertDialog(
                                        _data[index][3].toString(),
                                        _data[index][5].toString(),
                                        index,
                                      );
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
                                    if (index == 0 ||
                                        (index > 0 &&
                                            _data[index][3] !=
                                                _data[index - 1][3]))
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
                                    if (index == 0 ||
                                        (index > 0 &&
                                            _data[index][3] !=
                                                _data[index - 1][3]))
                                      TextButton(
                                        onPressed: () {
                                          showAlertDialog2(
                                              _data[index][3].toString(),
                                              _data[index][5].toString(),
                                              index);
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
              // 將 _data2 按照 _data 的順序進行排序
              List<List<dynamic>> sortedData2 = List.from(_data2);
              sortedData2.sort((a, b) {
                int indexA = _data.indexWhere((element) => element[2] == a[0]);
                int indexB = _data.indexWhere((element) => element[2] == b[0]);
                return indexA.compareTo(indexB);
              });

              // Show the dialog with _data2
              await _showDialog(sortedData2, _data3,_data4);
              //await _showDialog(_data3);
            },
            child: const Text('打開購物車'),
          ),
        ),
      ]),
    );
  }
}
