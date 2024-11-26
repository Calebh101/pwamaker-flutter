import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal/widgets.dart';
import 'package:personal/dialogue.dart';
import 'package:pwamaker/var.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingTitle(title: "Import/Export"),
            Setting(
              title: "Import",
              desc: "Import a JSON file as your PWAs.",
              text: "",
              action: () async {
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
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString('data', jsonEncode(jsonData));
    
                      showConstantDialogue(context, "Changes Saved", "Your data has been imported. You will need to close and reopen the app for your changes to take effect.");
                    } else {
                      showSnackBar(context, "Unsupported file type");
                    }
                  } else {
                    print('File selection was canceled');
                  }
                } catch (e) {
                  print('An error occurred: $e');
                  showSnackBar(context, "Unsupported file type");
                }
              },
            ),
            Setting(
              title: "Export",
              desc: "Export your PWAs as a JSON file.",
              text: "",
              action: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String json = jsonEncode(prefs.get("data"));
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/data.json');
                File file2 = await file.writeAsString(json);
        
                try {
                  await Share.shareXFiles([XFile(file2.path)], text: 'My custom PWAs');
                } catch (e) {
                  try {
                    print("Unable to Share.shareXFiles: falling back on Share.share: $e");
                    await Share.share(json, subject: "CarbCalc foods");
                  } catch (e2) {
                    print("Unable to Share.share: $e2");
                  }
                }
              },
            ),
            SettingTitle(title: "About"),
            Setting(
              title: "About",
              desc: "PWAmaker is an application designed to let users create, share, and install websites as if they were native apps. Ever wanted to have your local library's website as an app? What about that one business that uses the web? This app allows you to do everything, with support for names, descriptions, and included or custom icons.",
              text: "",
              action: () {},
            ),
            Setting(
              title: "Version",
              desc: "Version and channel info.",
              text: "Version $version\nChannel: ${beta ? "Beta" : "Stable"}",
              action: () {},
            ),
            Setting(
              title: "Author",
              desc: "Author and owner information.",
              text: "Author: Calebh101",
              action: () {},
            ),
            SettingTitle(title: "Reset"),
            Setting(
              title: "Reset Saved Items",
              desc: "Resets all your saved PWAs. This cannot be undone.",
              text: "",
              action: () async {
                bool? response = await showConfirmDialogue(context, "Confirm Action", "Are you sure you want to erase foods data? All modes and foods will be erased. This cannot be undone.");
                if (response != null) {
                  if (response) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString("data", "");
                    print("SharedPreferences.data cleared");
                    showConstantDialogue(context, "Changes Saved", "Your foods data has been reset. You will need to close and reopen the app for your changes to take effect.");
                    setState(() {});
                  }
                }
              },
            ),
            Setting(
              title: "Reset All Data",
              desc: "Resets all data and settings. This cannot be undone.",
              text: "",
              action: () async {
                bool? response = await showConfirmDialogue(context, "Confirm Action", "Are you sure you want to erase all data? This will delete your foods, modes, and settings. This cannot be undone.");
                if (response != null) {
                  if (response) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    print("SharedPreferences cleared");
                    showConstantDialogue(context, "Changes Saved", "Your data has been reset. You will need to close and reopen the app for your changes to take effect.");
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openUrlConf(context, Uri.parse("mailto:calebh101dev@icloud.com"));
        },
        child: Icon(Icons.feedback_outlined),
      ),
    );
  }
}