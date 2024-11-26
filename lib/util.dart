import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pwamaker/html.dart';

// had ChatGPT make this since I was too lazy lol
final List<Map<String, dynamic>> appIcons = [
  {"icon": Icons.home, "text": "Home"},
  {"icon": Icons.search, "text": "Search"},
  {"icon": Icons.settings, "text": "Settings"},
  {"icon": Icons.person, "text": "Profile"},
  {"icon": Icons.favorite, "text": "Favorites"},
  {"icon": Icons.notifications, "text": "Notifications"},
  {"icon": Icons.shopping_cart, "text": "Cart"},
  {"icon": Icons.chat, "text": "Chat"},
  {"icon": Icons.camera, "text": "Camera"},
  {"icon": Icons.map, "text": "Map"},
  {"icon": Icons.alarm, "text": "Alarm"},
  {"icon": Icons.book, "text": "Book"},
  {"icon": Icons.calendar_today, "text": "Calendar"},
  {"icon": Icons.call, "text": "Call"},
  {"icon": Icons.email, "text": "Email"},
  {"icon": Icons.folder, "text": "Folder"},
  {"icon": Icons.music_note, "text": "Music"},
  {"icon": Icons.video_library, "text": "Videos"},
  {"icon": Icons.file_copy, "text": "Files"},
  {"icon": Icons.lock, "text": "Lock"},
  {"icon": Icons.share, "text": "Share"},
  {"icon": Icons.wifi, "text": "Wi-Fi"},
  {"icon": Icons.bluetooth, "text": "Bluetooth"},
  {"icon": Icons.cloud, "text": "Cloud"},
  {"icon": Icons.sunny, "text": "Weather"},
  {"icon": Icons.battery_full, "text": "Battery"},
  {"icon": Icons.sports_soccer, "text": "Sports"},
  {"icon": Icons.directions_car, "text": "Car"},
  {"icon": Icons.train, "text": "Train"},
  {"icon": Icons.flight, "text": "Flight"},
  {"icon": Icons.pets, "text": "Pets"},
  {"icon": Icons.restaurant, "text": "Restaurant"},
  {"icon": Icons.coffee, "text": "Coffee"},
  {"icon": Icons.fitness_center, "text": "Fitness"},
  {"icon": Icons.local_hospital, "text": "Hospital"},
  {"icon": Icons.school, "text": "School"},
  {"icon": Icons.work, "text": "Work"},
  {"icon": Icons.lightbulb, "text": "Ideas"},
  {"icon": Icons.security, "text": "Security"},
  {"icon": Icons.shopping_bag, "text": "Shopping"},
  {"icon": Icons.code, "text": "Code"},
  {"icon": Icons.build, "text": "Tools"},
  {"icon": Icons.brush, "text": "Art"},
  {"icon": Icons.science, "text": "Science"},
  {"icon": Icons.gavel, "text": "Legal"},
  {"icon": Icons.park, "text": "Park"},
  {"icon": Icons.movie, "text": "Movies"},
  {"icon": Icons.headphones, "text": "Headphones"},
  {"icon": Icons.star, "text": "Star"},
  {"icon": Icons.emoji_emotions, "text": "Emojis"},
  {"icon": Icons.palette, "text": "Colors"},
  {"icon": Icons.light_mode, "text": "Light Mode"},
  {"icon": Icons.dark_mode, "text": "Dark Mode"},
  {"icon": Icons.account_balance, "text": "Bank"},
];

Future<bool> open(context, item) async {
  Map title = await encodeOutput(1, item["title"]);
  Map desc = await encodeOutput(1, item["desc"]);
  Map url = await encodeOutput(2, item["url"]);
  Map icon =
      await encodeOutput(3, item["icon"] ?? File('assets/app/icon/icon.png'));

  return await openPwa(
    context,
    {
      "name": title["output"],
      "desc": desc["output"],
      "url": url["output"], // REQUIRED: protocol included
    },
    icon["output"], 32, // REQUIRED: raw base64 string, no data URLs
  );
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
  final XFile? pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    print("No image selected");
    return null;
  }
}
