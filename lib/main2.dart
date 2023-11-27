import 'package:flutter/material.dart';
import 'recommend_page.dart';
import 'order_page.dart';
import 'wallet_page.dart';
import 'setting_page.dart';
import 'shopmenu.dart';



class main2 extends StatelessWidget {
  const main2({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blofood',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Blofood HomePage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int index = 0; //選擇NavigationBar的項目
  final screens = [
    const RecommendPage(),
    const OrderPage(),
    const WalletPage(),
    const SettingPage(),
  ]; //傳送至頁面的陣列
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: index,
        onDestinationSelected: (index) {
          setState(() {
            this.index = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.recommend), label: "推薦"),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: "訂單"),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: "錢包"),
          NavigationDestination(icon: Icon(Icons.settings), label: "設定"),
        ],
      ),
    );
  }
}
