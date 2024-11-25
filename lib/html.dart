import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> openPwa(BuildContext context, Map data) async {
  String htmlContent = await rootBundle.loadString("assets/html/pwa.html");
  String content = replacePlaceholders(htmlContent, data);
  String url = 'data:text/html;base64,${base64.encode(utf8.encode(content))}';

  print(url);
  return true;
}

String replacePlaceholders(String htmlContent, Map data) {
  data.forEach((key, value) {
    htmlContent = htmlContent.replaceAll("\${data[\"$key\"]}", value.toString());
  });
  return htmlContent;
}