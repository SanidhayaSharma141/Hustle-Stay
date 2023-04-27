import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:http/http.dart" as https;

String convertDate(DateTime dateTime) {
  return "${dateTime.year}-${dateTime.month}-${dateTime.day}";
}

class AttendanceSheet {
  Map<String, bool> sheet = {};

  setSheet(newSheet) {
    sheet = newSheet;
  }

  toggle(String id) {
    sheet[id] = !(sheet[id]!);
  }
}

addAttendancePage(Map<String, bool> present, DateTime dateTime) async {
  final String date = convertDate(dateTime);
  final url = Uri.https(
      "hustlestay-default-rtdb.firebaseio.com", "attendance/$date.json");
  final response = await https.post(url, body: json.encode(present));
  print(response.body);
}

class AttendanceNotifier extends StateNotifier<AttendanceSheet> {
  AttendanceNotifier() : super(AttendanceSheet());

  void setSheet(AttendanceSheet sheet) {
    state = sheet;
  }

  Future<void> downloadSheet(DateTime dateTime) async {
    final date = convertDate(dateTime);
    final url = Uri.https(
        "hustlestay-default-rtdb.firebaseio.com", "attendance/$date.json");
    final response = await https.get(url);
    if (response.body == 'null') {
      throw "Sheet not found";
    }
    print(response.body);
    state.setSheet(
        json.decode(response.body).values.firstWhere((element) => true));
  }

  uploadSheet(DateTime dateTime) async {
    final date = convertDate(dateTime);
    final url = Uri.https(
        "hustlestay-default-rtdb.firebaseio.com", "attendance/$date.json");
    final response = await https.post(url, body: json.encode(state.sheet));
    print(response);
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceSheet>((ref) {
  return AttendanceNotifier();
});
