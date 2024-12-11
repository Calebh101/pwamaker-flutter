import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal/dialogue.dart';
import 'package:pwamaker/var.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

bool useHttps = false;
bool useHttpsUrl = false;
bool openIconUrlDebug = false;

Uri baseUrl = Uri.parse("https://calebh101studios.web.app/pwa.html");

Future<bool> open(context, item) async {
  Map title = await encodeOutput(1, item["title"]);
  Map desc = await encodeOutput(1, item["desc"]);
  Map url = await encodeOutput(2, item["url"]);
  Map icon =
      await encodeOutput(3, item["icon"] ?? File('assets/app/icon/icon.png'));

  String extension = "png";
  String fileName = "icon.$extension";
  int port = 8425;

  Map response = await hostFile(
      await writeStringToFile(
          resizeImage(icon["output"], {"width": 256, "height": 256}),
          extension),
      fileName,
      port);
  String path = "${response["url"]}$fileName";

  print(response);
  print("serving file at $path");
  _testUrl(path);

  if (response["status"]) {
    // ignore: dead_code
    if (!openIconUrlDebug) {
      return await openPwa(
        context,
        {
          "name": title["output"],
          "desc": desc["output"],
          "url": url["output"], // REQUIRED: protocol included
          "icon": path,
        },
      );
      // ignore: dead_code
    } else {
      await launchUrl(
        Uri.parse(path),
        mode: LaunchMode.externalApplication, // Ensures the browser is used
      );
      return true;
    }
  } else {
    showAlertDialogue(
        context,
        "There was an error opening your PWA.",
        "There was an error creating the http server: $response",
        false,
        {"show": true});
    return false;
  }
}

Future<bool> _testUrl(url) async {
  print("testing url: $url");
  bool test = await testUrl(url);
  print("tested url: $test");
  return test;
}

Future<File> writeStringToFile(String content, String extension) async {
  Uint8List imageBytes = base64Decode(content);

  String fileName = '${Uuid().v4()}.${extension}';
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';

  File file = File(filePath);
  return await file.writeAsBytes(imageBytes);
}

Future<Map> encodeOutput(int mode, dynamic input) async {
  if (input is IconData) {
    return await iconEncodeOutput(mode, input);
  } else if (input is File) {
    return imgEncodeOutput(mode, input);
  } else {
    return {"success": false, "output": input, "error": "unknown type"};
  }
}

Map imgEncodeOutput(int mode, dynamic input) {
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

Future<bool> testUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(
          "success with response: ${truncateWithEllipsis(response.body, 40)}");
      return true;
    } else {
      print("fail with status code: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("fail with error: $e");
    return false;
  }
}

String truncateWithEllipsis(String str, int maxLength) {
  if (str.length > maxLength) {
    return '${str.substring(0, maxLength)}...';
  } else {
    return str;
  }
}

Future<Map<String, dynamic>> iconEncodeOutput(int mode, dynamic input) async {
  print("encoding icon");

  if (input == null || input.codePoint == null || input.fontFamily == null) {
    return {"success": false, "error": "Invalid input properties"};
  }

  Color color = Colors.black;
  Color bg = Colors.white;
  double size = 64.0;

  final PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // Define the size of the canvas with padding
  const double canvasPadding = 16.0;
  final double canvasSize = size + canvasPadding;
  final Rect rect = Rect.fromLTWH(0, 0, canvasSize, canvasSize);

  // Paint the background color
  final Paint backgroundPaint = Paint()..color = bg;
  canvas.drawRect(rect, backgroundPaint);

  // Paint the icon text
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(input.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: input.fontFamily,
        color: color,
      ),
    ),
  );

  textPainter.layout();
  // Center the text within the canvas
  final Offset textOffset = Offset(
    (canvasSize - textPainter.width) / 2,
    (canvasSize - textPainter.height) / 2,
  );
  textPainter.paint(canvas, textOffset);

  // Convert canvas to an image
  final ui.Image image = await pictureRecorder.endRecording().toImage(
        canvasSize.toInt(),
        canvasSize.toInt(),
      );

  // Encode the image as PNG
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return {"success": false, "error": "Failed to encode image"};
  }

  final Uint8List pngBytes = byteData.buffer.asUint8List();

  return {"success": true, "output": base64Encode(pngBytes)};
}

Widget getIconFromInput(dynamic input, double? size) {
  if (input is IconData) {
    // Handle IconData
    return Icon(input, size: size);
  } else if (input is File) {
    // Handle File
    return Image.file(input, width: size, height: size, fit: BoxFit.cover);
  } else if (input is String) {
    // Handle Base64 String
    try {
      final decodedBytes = base64Decode(input);
      return Image.memory(
        Uint8List.fromList(decodedBytes),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Text(
        "Invalid Base64 String",
        style: TextStyle(color: Colors.red, fontSize: 10),
      );
    }
  } else {
    print("unsupported icon type: ${input.runtimeType}");
    return Text(
      "Unsupported Type",
      style: TextStyle(color: Colors.red, fontSize: 10),
    );
  }
}

Widget circleAvatar2(dynamic input, double size) {
  return CircleAvatar(
    radius: size,
    backgroundColor: Colors.transparent,
    child: ClipOval(
      child: FittedBox(
        fit: BoxFit.cover,
        child: input ?? Icons.question_mark,
      ),
    ),
  );
}

Future<IconData?> selectIcon(context) async {
  Map<String, dynamic>? selectedItem = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select an Option'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: appIcons.map((Map<String, dynamic> item) {
              return ListTile(
                leading: Icon(item["icon"]),
                title: Text(item["text"]),
                onTap: () {
                  Navigator.pop(context, item);
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );

  if (selectedItem != null) {
    return selectedItem["icon"];
  } else {
    return null;
  }
}

Future<File?> selectImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  File? pickedFile;
  try {
    XFile? xfile = await picker.pickImage(source: source);
    if (xfile != null) {
      pickedFile = File(xfile.path);
    }
  } catch (e) {
    pickedFile = await selectImageFile();
  }

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    print("No image selected");
    return null;
  }
}

Future<File?> selectImageFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );

  if (result != null) {
    File file = File(result.files.single.path!);
    return file;
  } else {
    return null;
  }
}

String resizeImage(String base64String, Map sizes) {
  Uint8List decodedBytes = base64Decode(base64String);
  img.Image? originalImage = img.decodeImage(decodedBytes);

  if (originalImage == null) {
    throw Exception('Failed to decode image.');
  }

  img.Image resizedImage = img.copyResize(originalImage,
      width: sizes["width"], height: sizes["height"]);
  Uint8List resizedImageBytes = Uint8List.fromList(img.encodePng(resizedImage));
  String resizedBase64String = base64Encode(resizedImageBytes);
  return resizedBase64String;
}

Future<bool> openPwa(BuildContext context, Map data) async {
  String url = "${baseUrl.toString()}?data=${jsonEncode(data)}";
  bool success = false;
  try {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    print("launched url: $url");
    success = true;
  } catch (e) {
    print("error with url: $e");
    showAlertDialogue(context, "Unable to launch URL",
        "Unable to launch URL: $url", false, {"show": true, "text": url});
    success = false;
  }

  print("$url: $success");
  return success;
}
