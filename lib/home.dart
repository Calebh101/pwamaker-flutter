import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pwamaker/html.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late List data;


  List actions = [
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
  ];

  List items = [
    {
      "title": "YouTube",
      "desc": "YouTube videos and shorts",
      "url": "https://youtube.com",
      "id": "youtube",
      "icon": null,
    },
    {
      "title": "YouTube2",
      "desc": "YouTube videos and shorts",
      "url": "https://youtube.com",
      "id": "youtube",
      "icon": null,
    },
    {
      "title": "YouTube3",
      "desc": "YouTube videos and shorts",
      "url": "https://youtube.com",
      "id": "youtube",
      "icon": null,
    },
  ];

  void refresh() {
    setState(() {});
  }

  Future<void> itemAction(Map item, String id, int index) async {
    if (id == "new") {
      print("new");
      items.add(await editItem({"title": "", "desc": "", "url": ""}, 1));
      return;
    } else if (id == "import") {
      print("import");
      return;
    } else {
      print("other: $id");
      items[index - actions.length] = await editItem(item, 2);
    }

    //_openPWA(item);
    refresh();
  }

  Future<bool> _openPWA(item) async {
    return await openPwa(
      context,
      {
        "name": encodeOutput(1, item["title"])["output"],
        "desc": encodeOutput(1, item["desc"])["output"],
        "url": encodeOutput(2, item["url"])["output"], // REQUIRED: protocol included
      },
      encodeOutput(3, item["icon"] ?? File('assets/app/icon/icon.png'))["output"], // REQUIRED: raw base64 string, no data URLs
    );
  }

  Map encodeOutput(int mode, dynamic input) {
    if (mode == 1 || mode == 2) {
      return {"success": true, "output": input};
    } else if (mode == 3) {
      List<int> imageBytes = input.readAsBytesSync();
      String base64String = base64Encode(imageBytes);
      return {"success": true, "output": base64String};
    } else {
      return {"success": false, "output": input, "error": "unknown mode"};
    }
  }

  void initState() {
    super.initState();
  }

  Future<Map> editItem(item, int mode) async {
    print("edit item: initializing");

    bool useValues = false;

    final TextEditingController stringController = TextEditingController(text: item["title"]);

    print("edit item: starting");

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${mode == 1 ? "Edit" : "Add"} item'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stringController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                useValues = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                useValues = true;
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (useValues) {
      print("edit item: using values");

      String name = stringController.text == '' ? item["name"] : stringController.text;

      item["name"] = name;
    } else {
      print("edit item: not using values");
    }

    print("edit item: complete");
    return item;
  }

  List _onDragCompleted(int fromIndex, int toIndex, List items) {
    final draggedItem = items.removeAt(fromIndex);
    items.insert(toIndex, draggedItem);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 150).floor();
    crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
    int? draggedIndex;
    data = actions + items;

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
                itemCount: data.length,
                itemBuilder: (context, index) {
                  Map item = data[index];
                  return DragTarget<Map>(
                    onWillAcceptWithDetails: (dragData) {
                      return true;
                    },
                    onAcceptWithDetails: (dragData) {
                      int oldIndex = draggedIndex! - actions.length;
                      int newIndex = index - actions.length;
                      print("oldIndex,newIndex,draggedIndex: $oldIndex,$newIndex,$draggedIndex");

                      if (newIndex >= 0) {
                        items = _onDragCompleted(oldIndex, newIndex, items);
                        refresh();
                      }
                    },
                    builder: (context, candidateData, rejectedData) { 
                      return index >= actions.length ? Draggable<Map>(
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildGridTile(2, index, data, item),
                        ),
                        data: data[index],
                        onDragStarted: () {
                          draggedIndex = index; // Store the index of the dragged item
                        },
                        onDragCompleted: () {
                          draggedIndex = null; // Reset index after drag is completed
                        },
                        onDraggableCanceled: (_, __) {
                          draggedIndex = null; // Reset index if drag is canceled
                        },
                        child: GridTile(
                          child: _buildGridTile(1, index, data, item),
                        ),
                      ) : _buildGridTile(1, index, data, item);
                    }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile(int mode, int index, List data, Map item) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 3,
        child: InkWell(
          onTap: () {
            itemAction(data[index], item["id"], index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mode == 2)
                  SizedBox(height: 12),
                CircleAvatar(
                  child: Icon(item["icon"] ?? Icons.question_mark),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    item["title"],
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: mode == 2 ? 12 : 4),
                if (mode != 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      item["desc"],
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}