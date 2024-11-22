import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void itemAction(String id) {
    if (id == "new") {
      print("new");
    } else if (id == "import") {
      print("import");
    } else {
      print("other: $id");
    }
  }

  List<Map> items = [
    {
      "title": "YouTube",
      "desc": "YouTube",
      "id": "youtube",
      "icon": Icons.youtube_searched_for
    }
  ];

  void initState() {
    items.insertAll(0, [
      {
        "title": "New",
        "desc": "Add a new item",
        "id": "new",
        "icon": Icons.add,
      },
      {
        "title": "Import",
        "desc": "Import a new item",
        "id": "import",
        "icon": Icons.download,
      },
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 150).floor();
    crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("PWAmaker"),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  Map item = items[index];
                  return Container(
                    width: 120, // Set width for horizontal items
                    margin: const EdgeInsets.symmetric(horizontal: 8), // Add spacing between items
                    child: Card(
                      elevation: 3,
                      child: InkWell(
                        onTap: () {
                          itemAction(item["id"]);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                child: Icon(item["icon"]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item["title"],
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item["desc"],
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}