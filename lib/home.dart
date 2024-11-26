import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:personal/dialogue.dart';
import 'package:personal/functions.dart';
import 'package:pwamaker/item.dart';
import 'package:pwamaker/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late List data;
  int globalMode = 1;
  List items = [];

  List actions = [
    {
      "title": "New",
      "desc": "Add a new item.",
      "id": "new",
      "icon": Icons.add,
    },
    {
      "title": "Import",
      "desc": "Import an existing item.",
      "id": "import",
      "icon": Icons.download,
    },
  ];


  void refresh(data) {
    print("refreshing");
    setData(data);
    setState(() {});
  }

  Future<void> setData(data) async {
    print("setting data");
    final prefs = await SharedPreferences.getInstance();

    for (var item in items) {
      var icon = await encodeOutput(3, item["icon"]);
      item["icon"] = icon["output"];
    }

    String? string = jsonEncode(data);
    await prefs.setString("data", string);
  }

  List deleteItem(data, index) {
    data.removeAt(index - actions.length);
    return data;
  }

  Future<List> itemAction(data, Map item, String? id, int index) async {
    print("editing item");
    if (id == "new") {
      print("new");
      Map newItem = await editItem({"title": "", "desc": "", "url": "", "valid": false}, 1);
      if (newItem["valid"]) {
        data.add(newItem);
      }
    } else if (id == "import") {
      print("import");
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ["json", "txt"],
        );

        if (result != null) {
          File file = File(result.files.single.path!);
          String content = await file.readAsString();

          dynamic jsonData = jsonDecode(content);
          if (jsonData is Map<String, dynamic>) {
            if (jsonData.containsKey("title") && jsonData.containsKey("desc") && jsonData.containsKey("url")) {
              data.add(jsonData);
              showSnackBar(context, "New item imported");
              refresh(data);
            } else {
              print("jsonData failed check 3: contains(title,desc,url): ${jsonData.containsKey("title")}${jsonData.containsKey("desc")}${jsonData.containsKey("url")}");
              showSnackBar(context, "Unsupported file type");
            }
          } else {
            print("jsonData failed check 2: jsonData is ${jsonData.runtimeType}");
            showSnackBar(context, "Unsupported file type");
          }
        } else {
          print("jsonData failed check 1: file selection cancelled");
        }
      } catch (e) {
        print('jsonData failed with error: $e');
        showSnackBar(context, "Unsupported file type");
      }
    } else {
      print("other: $id");
      if (globalMode == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemPage(item: item)),
        );
      } else {
        items[index - actions.length] = await editItem(item, 2);
      }
    }

    refresh(data);
    return data;
  }

  Future<List?> getLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("data");

    if (data != null) {
      try {
        print("data found: setting");
        items = json.decode(data);
      } catch (e) {
        print("corrupt data: cleared");
        prefs.setString("data", "");
      }
    } else {
      print("no data found");
    }

    return items;
  }

  void initState() {
    init();
    showFirstTimeDialogue(context, "Welcome to PWAmaker!", "PWAmaker is an app that lets you create, share, and install websites, but as apps. You will input a title, like YouTube, a description (which is optional), and a URL (which can be something like youtube.com). You can then input an optional icon, and now you have your website. Simply press the install button, and follow the next steps to see your new app.", false);
    super.initState();
  }

  bool verifyInputLength(String input, int length) {
    return input.length <= length;
  }

  Future<void> init() async {
    var data = await getLocalData();
    refresh(data);
  }

  Future<Map> editItem(item, int mode) async {
    print("edit item: initializing");
    print("item: $item (${item.runtimeType})");

    String? selectedIconType;
    bool useValues = false;
    dynamic icon;

    final TextEditingController stringController = TextEditingController(text: item["title"]);
    final TextEditingController descController = TextEditingController(text: item["desc"]);
    final TextEditingController urlController = TextEditingController(text: item["url"]);

    bool validOptions() {
      bool valuesNotEmpty = stringController.text != "" && urlController.text != "";
      bool lengthCorrect = verifyInputLength(stringController.text, 12) && verifyInputLength(descController.text, 32) && verifyInputLength(urlController.text, 20);
      return valuesNotEmpty && lengthCorrect;
    }

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
                    decoration: const InputDecoration(labelText: 'Name*'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: 'URL*'),
                  ),
                  PopupMenuButton<String>(
                    icon: Row(
                      children: [
                        Icon(
                          Icons.more_horiz,
                        ),
                        Text(
                          selectedIconType != null ? "Icon - selected" : "Icon",
                        ),
                      ],
                    ),
                    onSelected: (value) async {
                      print("selected: $value");
                      selectedIconType = value;

                      switch (value) {
                        case "Built-in icon":
                          icon = await selectIcon(context);
                        case "Custom icon":
                          icon = await selectImage(context);
                        case "No icon":
                          icon = null;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return ['Built-in icon', 'Custom icon', 'No icon', 'Cancel']
                          .map((String action) {
                        return PopupMenuItem<String>(
                          value: action,
                          child: Text(action),
                        );
                      }).toList();
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (validOptions()) {
                  useValues = true;
                  Navigator.of(context).pop();
                } else {
                  showSnackBar(context, "Invalid input");
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (useValues && validOptions()) {
      print("edit item: using values");
      
      String desc;
      var iconS = await encodeOutput(3, icon ?? item["icon"] ?? Icons.question_mark);

      String name = stringController.text == '' ? item["title"] : stringController.text;
      String url = urlController.text == '' ? item["url"] : urlController.text;

      if (descController.text == '') {
        desc = 'My $name PWA';
      } else {
        desc = descController.text == '' ? item["desc"] : descController.text;
      }

      print("desc: $desc");

      item["title"] = name;
      item["desc"] = desc;
      item["url"] = addHttpPrefix(url);
      item["icon"] = iconS["output"];
      item["valid"] = true;
    } else {
      print("edit item: not using values");
      item["valid"] = false;
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
    int crossAxisCount = (screenWidth / 220).floor();
    crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
    int? draggedIndex;
    data = actions + items;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("PWAmaker"),
        actions: [
          IconButton(
            icon: Icon(globalMode == 1 ? Icons.edit : Icons.home),
            onPressed: () {
              globalMode == 1 ? globalMode = 2 : globalMode = 1;
              refresh(data);
            },
          ),
        ],
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
                        refresh(items);
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
      child: Stack(
        children: [
          Card(
            elevation: 3,
            child: InkWell(
              onTap: () async {
                items = await itemAction(items, item, item["id"], index);
                refresh(items);
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: mode == 2 ? 12 : 0),
                    circleAvatar2(getIconFromInput(item["icon"] ?? Icons.question_mark, 48), 24),
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
                      Column(
                        children: [
                          if (item.containsKey("url"))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                item["url"],
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              item["desc"],
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (mode != 2 && index >= actions.length && globalMode == 2)
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                onTap: () {
                  items = deleteItem(items, index);
                  refresh(items);
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}