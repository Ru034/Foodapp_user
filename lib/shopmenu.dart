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

  //List<List<int>> _data4 = [];  //單點
  //List<List<int>> _data3 = [];  //套餐
  List<List<List<String>>> _data4 = [];
  List<List<List<String>>> _data3 = [];
  int counte = 1;
  int sum1 = 0;
  int sum2 = 0;

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
    //_data2 = List.generate(_data.length, (index) => [0, 0]);
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

  void showAlertDialog(String listData, String listData2, int fir) {
    Map<String, bool> selectedItemsMap = {(fir + 1).toString(): true};
    counte = 1;
    setState(() {
      sum1 = _data[fir][5];
      sum2 = sum1 * counte;
    });
    showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _data.length; index++)
                    if (_data[index][3] == listData && index != fir)
                      Row(
                        children: [
                          if ((index > 0 &&
                                  _data[index][3] != _data[index - 1][3]) ||
                              index == 0)
                            Text(
                              listData + '      ' + listData2,
                              style: TextStyle(
                                fontSize:
                                    100.0, // Adjust the font size as needed
                                // You can also add other styles if desired, e.g., fontWeight, color, etc.
                              ),
                            ),
                          if ((index > 0 &&
                              _data[index][3] == _data[index - 1][3]))
                            Row(
                              children: [
                                Text(
                                  _data[index][4].toString(),
                                  style: TextStyle(
                                    fontSize:
                                        15.0, // Adjust the font size as needed
                                    // You can also add other styles if desired, e.g., fontWeight, color, etc.
                                  ),
                                ),
                                Text(
                                  '      \$${_data[index][5].toString()}',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          TextButton(
                            onPressed: () {
                              toggleAlertDialogSelection(
                                index + 1,
                                selectedItemsMap,
                                updateUI: () {
                                  setState(() {});
                                },
                              );
                            },
                            child: Icon(
                              selectedItemsMap
                                      .containsKey((index + 1).toString())
                                  ? Icons.check_circle
                                  : Icons.circle,
                              color: selectedItemsMap
                                      .containsKey((index + 1).toString())
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 1, // Adjust the width as needed
                        height: 1,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(
                              20.0), // Adjust the radius as needed
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (counte > 1) counte--;
                                  print(counte);
                                  sum2 = sum1 * counte;
                                  print(counte);
                                });
                              },
                              child: Container(
                                width: 30.0, // Adjust the width as needed
                                height: 30.0, // Adjust the height as needed
                                child: const Icon(Icons.remove,
                                    color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.0),
                              child: Text(
                                counte.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  counte++;
                                  print(counte);
                                  sum2 = sum1 * counte;
                                  print(counte);
                                });
                              },
                              child: Container(
                                width: 30.0, // Adjust the width as needed
                                height: 30.0, // Adjust the height as needed
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '總金額為$sum2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(15),
                      ),
                      ElevatedButton(
                        child: Text("新增至購物車"),
                        onPressed: () {
                          try {
                            List<int> selectedIndices = selectedItemsMap.keys
                                .map((key) => int.parse(key))
                                .toList();
                            List<String> selectedItems = selectedIndices
                                .map((index) => index.toString())
                                .toList();

                            // Check if a similar entry exists in _data4
                            bool found = false;
                            for (List<List<String>> entry in _data4) {
                              if (entry[0].toString() ==
                                  selectedItems.toString()) {
                                // Entry with similar selected items found, update the count and sum1
                                entry[1][0] = (int.parse(entry[1][0]) + counte)
                                    .toString();
                                entry[2] = [
                                  sum1.toString()
                                ]; // Add sum1 to the entry
                                found = true;
                                break;
                              }
                            }
                            if (!found) {
                              // No similar entry found, add a new entry to _data4
                              List<List<String>> result = [
                                selectedItems,
                                [counte.toString()],
                                [sum1.toString()] // Add sum1 to the new entry
                              ];
                              _data4.add(result);
                            }
                            print("_data4: $_data4");
                          } catch (e) {
                            print("Error in onPressed: $e");
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void toggleAlertDialogSelection(int index, Map<String, bool> selectedItemsMap,
      {required VoidCallback updateUI}) {
    if (selectedItemsMap.containsKey(index.toString())) {
      // Item is already selected, remove it and subtract the amount from sum
      selectedItemsMap.remove(index.toString());
      setState(() {
        sum1 -= (_data[index - 1][5] as int); // Adjust index for data
        print(sum1);
        sum2 = sum1 * counte;
      });
    } else {
      // Item is not selected, add it and add the amount to sum
      selectedItemsMap[index.toString()] = true;
      setState(() {
        sum1 += (_data[index - 1][5] as int); // Adjust index for data
        print(sum1);
        sum2 = sum1 * counte;
      });
    }
    // Trigger UI update
    updateUI();
  }

  void showAlertDialog2(String listData, String listData2, int fir) {
    Map<String, List<String>> selectedItemsMap = {
      '0': [_data[fir][2].toString()], // Initialize with the desired value
    };
    counte = 1;
    setState(() {
      sum1 = _data[fir][5];
      sum2 = sum1 * counte;
    });
    List<String> selectedItems = [];

    showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                for (int innerIndex = 0;
                    innerIndex < _data.length;
                    innerIndex++)
                  if (_data[innerIndex][3] == listData &&
                      _data[innerIndex][4] != '')
                    Column(
                      children: [
                        Text(
                          '${_data[innerIndex][4]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red, // 將文字顏色設為綠色
                          ),
                        ),
                        for (int index2 = 0; index2 < _data.length; index2++)
                          if (_data[index2][0] == 3)
                            if (_data[innerIndex][4] == _data[index2][3])
                              Row(
                                children: [
                                  Text(
                                    _data[index2][4],
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '       \$${_data[index2][5].toString()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green, // 將文字顏色設為綠色
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      //print("Before toggle: $selectedItemsMap");
                                      toggleAlertDialogSelection2(
                                        _data[index2][3],
                                        index2 + 1,
                                        selectedItemsMap,
                                        updateUI: () {
                                          setState(() {});
                                        },
                                      );
                                      //print( selectedItemsMap);
                                      List<int> selectedIndices =
                                          selectedItemsMap.values
                                              .expand((list) {
                                        // 在這裡進行轉換，將 String 轉為 int
                                        return list
                                            .map((item) => int.parse(item))
                                            .toList();
                                      }).toList();

                                      selectedItems = selectedIndices
                                          .map((intItem) => intItem.toString())
                                          .toList();
                                      print(selectedItems);
                                      setState(() {
                                        sum1 = 0;
                                        for (int i = 0;
                                            i < selectedItems.length;
                                            i++)
                                          //sum1 += _data[int.parse(selectedItems[i])][5] as int;
                                          sum1 += _data[
                                              int.parse(selectedItems[i]) -
                                                  1][5] as int;
                                        //sum1 += int.parse(selectedItems[i]);
                                        sum2 = sum1 * counte;
                                        print(counte);
                                      });
                                    },
                                    child: Icon(
                                      selectedItems
                                              .contains((index2 + 1).toString())
                                          ? Icons.check_circle
                                          : Icons.circle,
                                      color: selectedItems
                                              .contains((index2 + 1).toString())
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 1, // Adjust the width as needed
                      height: 1,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(
                            20.0), // Adjust the radius as needed
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (counte > 1) counte--;
                                print(counte);
                                sum2 = sum1 * counte;
                                print(counte);
                              });
                            },
                            child: Container(
                              width: 30.0, // Adjust the width as needed
                              height: 30.0, // Adjust the height as needed
                              child:
                                  const Icon(Icons.remove, color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 1.0),
                            child: Text(
                              counte.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                counte++;
                                print(counte);
                                sum2 = sum1 * counte;
                                print(counte);
                              });
                            },
                            child: Container(
                              width: 30.0, // Adjust the width as needed
                              height: 30.0, // Adjust the height as needed
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '總金額為$sum2',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(15),
                    ),
                    ElevatedButton(
                      child: Text("新增至購物車"),
                      onPressed: () {
                        try {
                          List<int> selectedIndices =
                              selectedItemsMap.values.expand((list) {
                            // 在這裡進行轉換，將 String 轉為 int
                            return list.map((item) => int.parse(item)).toList();
                          }).toList();

                          List<String> selectedItems = selectedIndices
                              .map((intItem) => intItem.toString())
                              .toList();
                          //_data3.add([selectedItems]);

                          // Check if a similar entry exists in _data3
                          bool found = false;
                          for (List<List<String>> entry in _data3) {
                            if (entry[0].toString() ==
                                selectedItems.toString()) {
                              // Entry with similar selected items found, update the count and sum1
                              entry[1][0] =
                                  (int.parse(entry[1][0]) + counte).toString();
                              entry[2] = [
                                sum1.toString()
                              ]; // Add sum1 to the entry
                              found = true;
                              break;
                            }
                          }
                          if (!found) {
                            // No similar entry found, add a new entry to _data3
                            List<List<String>> result = [
                              selectedItems,
                              [counte.toString()],
                              [sum1.toString()] // Add sum1 to the new entry
                            ];
                            _data3.add(result);
                          }
                          print("_data3: $_data3");
                        } catch (e) {
                          print("Error in onPressed: $e");
                        }
                      },
                    ),
                  ],
                ),
              ]);
            },
          ),
        );
      },
    );
  }

  void toggleAlertDialogSelection2(
      String category, int index, Map<String, List<String>> selectedItemsMap,
      {required VoidCallback updateUI}) {
    if (!selectedItemsMap.containsKey(category)) {
      selectedItemsMap[category] = [index.toString()];
    } else {
      if (selectedItemsMap[category]!.contains(index)) {
        // Item is already selected, remove it
        selectedItemsMap[category]!.remove(index);
      } else {
        // Item is not selected, add it and remove others in the same category
        selectedItemsMap[category] = [index.toString()];
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

        // Update the image paths in the loaded data
        for (int index = 0; index < listData.length; index++) {
          final imagePath = listData[index][6].toString();
          if (imagePath.isNotEmpty) {
            // Replace 'foodapp' with 'foodapp_user'
            listData[index][6] =
                imagePath.replaceAll('foodapp', 'foodapp_user');
          }
        }

        setState(() {
          _data = listData;
        });
      } else {
        // If the file doesn't exist in the app's data directory, copy it from assets
        final rawData = await rootBundle.loadString("assets/new_data.csv");
        List<List<dynamic>> listData =
            const CsvToListConverter().convert(rawData);

        // Update the image paths in the loaded data
        for (int index = 0; index < listData.length; index++) {
          final imagePath = listData[index][6].toString();
          if (imagePath.isNotEmpty) {
            // Replace 'foodapp' with 'foodapp_user'
            listData[index][6] =
                imagePath.replaceAll('foodapp', 'foodapp_user');
          }
        }

        setState(() {
          _data = listData;
        });
      }
    } catch (e) {
      print('Error loading CSV file: $e');
    }
  }

  Future<void> _showDialog(
      List<List<List<String>>> data3, List<List<List<String>>> data4) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('購物車內容'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                for (int i = 0; i < _data4.length; i++)
                  Card(
                    // 使用 Card 包装每个项目
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int j = 0; j < _data4[i][0].length; j++)
                                Row(
                                  children: [
                                    if (j == 0)
                                      Text(
                                          '${_data[int.parse(_data4[i][0][j]) - 1][3]}'),
                                    if (j > 0)
                                      Text(
                                          '${_data[int.parse(_data4[i][0][j]) - 1][4]}'),
                                  ],
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (int.parse(_data4[i][1][0]) > 1)
                                      _data4[i][1][0] =
                                          (int.parse(_data4[i][1][0]) - 1)
                                              .toString();
                                    else
                                      _data4.removeAt(i);
                                  });
                                },
                                child: Container(
                                  width: 30.0, // Adjust the width as needed
                                  height: 30.0, // Adjust the height as needed
                                  child: const Icon(Icons.remove,
                                      color: Colors.black),
                                ),
                              ),
                              Text(
                                _data4[i][1][0].toString(),
                                style: TextStyle(color: Colors.black),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _data4[i][1][0] =
                                        (int.parse(_data4[i][1][0]) + 1)
                                            .toString();
                                  });
                                },
                                child: Container(
                                  width: 30.0, // Adjust the width as needed
                                  height: 30.0, // Adjust the height as needed
                                  child: const Icon(Icons.add,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '\$${(int.parse(_data4[i][1][0]) * int.parse(_data4[i][2][0])).toString()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _data4.removeAt(i);
                                    });
                                  },
                                  child: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ]),
                        ],
                      ),
                    ),
                  ),
                for (int i = 0; i < _data3.length; i++)
                  Card(
                    // 使用 Card 包装每个项目
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int j = 0; j < _data3[i][0].length; j++)
                                Row(
                                  children: [
                                    if (j == 0)
                                      Text(
                                          '${_data[int.parse(_data3[i][0][j]) - 1][3]}'),
                                    if (j > 0)
                                      Text(
                                          '${_data[int.parse(_data3[i][0][j]) - 1][4]}'),
                                  ],
                                ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _data3.removeAt(i);
                              });
                            },
                            child: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
              ]);
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('關閉購物車'),
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
                    Card(
                      color: Colors.white70,
                      child: ListTile(
                        onTap: () {
                          // 將原本 TextButton 的功能移到這裡
                          showAlertDialog(
                            _data[index][3].toString(),
                            _data[index][5].toString(),
                            index,
                          );
                        },
                        subtitle: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
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
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ],
                                          ),
                                        ),
                                      /*
                                      if (index == 0 &&
                                              _data[index][6] == "" &&
                                              index == 0 ||
                                          (_data[index][3] !=
                                                  _data[index - 1][3] &&
                                              index > 0 &&
                                              _data[index][6] == ""))
                                        Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors
                                              .grey, // You can customize the color
                                          // You can also add a placeholder image here
                                          // child: Image.asset('assets/placeholder.png'),
                                        ),

                                       */
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _data[index][3].toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          top: 0, left: 20.0, bottom: 0),
                                    ),
                                    Text(
                                      '\$${_data[index][5].toString()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // 將文字顏色設為綠色
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          top: 0, left: 10.0, bottom: 0),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                const Padding(
                  padding: EdgeInsets.only(top: 15, left: 30.0, bottom: 15),
                  //const EdgeInsets.only(left: 40.0)
                  child: Text(
                    "套餐",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 套餐卡片
                for (int index = 0; index < _data.length; index++)
                  if (_data[index][0] == 2 &&
                      _data[index - 1][3] != _data[index][3])
                    Card(
                      color: Colors.white38,
                      child: ListTile(
                        onTap: () {
                          // 將原本 TextButton 的功能移到這裡
                          showAlertDialog2(
                            _data[index][3].toString(),
                            _data[index][5].toString(),
                            index,
                          );
                        },
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
                                        Text(
                                          _data[index][3].toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '\$${_data[index][5].toString()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 30.0),
                                      ),
                                      Column(children: [
                                        for (int test = index;
                                            test < _data.length;
                                            test++)
                                          if (_data[test][3] == _data[index][3])
                                            Text(
                                              _data[test][4].toString(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                      ])
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
              /*
              // 將 _data2 按照 _data 的順序進行排序
              List<List<dynamic>> sortedData2 = List.from(_data2);
              sortedData2.sort((a, b) {
                int indexA = _data.indexWhere((element) => element[2] == a[0]);
                int indexB = _data.indexWhere((element) => element[2] == b[0]);
                return indexA.compareTo(indexB);
              });
*/
              // Show the dialog with _data2
              await _showDialog(_data3, _data4);
              //await _showDialog(_data3);
            },
            child: const Text('打開購物車'),
          ),
        ),
      ]),
    );
  }
}
