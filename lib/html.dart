import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:personal/dialogue.dart';
import 'package:url_launcher/url_launcher.dart';

Uri baseUrl = Uri.parse("https://calebh101studios.web.app/pwa.html");

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
