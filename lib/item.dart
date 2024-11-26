import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal/dialogue.dart';
import 'package:personal/functions.dart';
import 'package:pwamaker/util.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ItemPage extends StatefulWidget {
  final Map item;

  const ItemPage({
    super.key,
    required this.item,
  });

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.item["title"],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                circleAvatar2(getIconFromInput(widget.item["icon"] ?? Icons.question_mark, 96), 48),
                SizedBox(width: 12),
                Text(
                  widget.item["title"],
                  style: TextStyle(
                    fontSize: 32,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () {
                      openUrlConf(context, Uri.parse(widget.item["url"]));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Text(
                        removeHttpPrefix(widget.item["url"]),
                        style: TextStyle(
                          fontSize: 20,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Text(
                    widget.item["desc"],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final directory = await getApplicationDocumentsDirectory();
                        final file = File('${directory.path}/data.json');
                        File file2 = await file.writeAsString(jsonEncode(widget.item));
                
                        try {
                          await Share.shareXFiles([XFile(file2.path)], text: '${widget.item["name"]}');
                        } catch (e) {
                          try {
                            print("Unable to Share.shareXFiles: falling back on Share.share: $e");
                            await Share.share(jsonEncode(widget.item), subject: "CarbCalc foods");
                          } catch (e2) {
                            print("Unable to Share.share: $e2");
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.share,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Share",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    TextButton(
                      onPressed: () {
                        open(context, widget.item);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.open_in_new,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Install",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}