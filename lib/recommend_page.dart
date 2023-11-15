import 'package:flutter/material.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({Key? key}) : super(key: key);

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  List<String> storeNameList = [
    '餐廳1',
    '餐廳2',
    '餐廳1',
    '餐廳2',
    '餐廳1',
    '餐廳2',
    '餐廳1',
    '餐廳2',
    '餐廳1',
    '餐廳2',
    '餐廳1',
    '餐廳2'
  ];
  List<String> storePriceList = [
    '50~100 TWD',
    '100~200 TWD',
    '150~250 TWD',
    '200~300 TWD',
    '250~350 TWD',
    '300~400 TWD',
    '350~450 TWD',
    '400~500 TWD',
    '450~550 TWD',
    '500~600 TWD',
    '550~650 TWD',
    '600~700 TWD'
  ];
  List<String> storeDistanceList = [
    '0.1km',
    '0.2km',
    '0.3km',
    '0.4km',
    '0.5km',
    '0.6km',
    '0.7km',
    '0.8km',
    '0.9km',
    '1.0km',
    '1.1km',
    '1.2km'
  ];

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
