import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hostel/rooms/room.dart';

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}

class RoommateInfo {
  final RoommateData roommateData;
  final String roomName;

  RoommateInfo({
    required this.roomName,
    required this.roommateData,
  });
}

Future<String> getAttendanceData(RoommateData roommateData, String hostelName,
    String roomName, DateTime date) async {
  final storage = FirebaseFirestore.instance;
  final documentRef = storage
      .collection('hostels')
      .doc(hostelName)
      .collection('Roommates')
      .doc(roommateData.email)
      .collection('Attendance')
      .doc(DateFormat('yyyy-MM-dd').format(date));
  if (roommateData.onLeave != null &&
      roommateData.onLeave! &&
      roommateData.leaveStartDate != null &&
      (roommateData.leaveStartDate!.isBefore(date)) &&
      roommateData.leaveEndDate != null &&
      (roommateData.leaveEndDate!.isAfter(date))) {
    await documentRef.set({'status': 'onLeave'}, SetOptions(merge: false));
    return 'onLeave';
  }

  final documentSnapshot = await documentRef.get();
  if (documentSnapshot.exists) {
    return documentSnapshot['status'];
  } else {
    await documentRef.set({'status': 'absent'});
    return 'absent';
  }
}

Future<bool> setAttendanceData(String email, String hostelName, String roomName,
    DateTime date, bool status) async {
  try {
    final storage = FirebaseFirestore.instance;
    final docRef = storage
        .collection('hostels')
        .doc(hostelName)
        .collection('Roommates')
        .doc(email)
        .collection('Attendance')
        .doc(DateFormat('yyyy-MM-dd').format(date));

    await storage.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        transaction.set(docRef, {'status': status ? 'absent' : 'present'});
      } else {
        transaction.update(docRef, {'status': status ? 'absent' : 'present'});
      }
    });

    return true;
  } catch (e) {
    debugPrint('Error while setting attendance data: $e');
    return false;
  }
}

Future<bool> markAllAttendance(
    String hostelName, bool status, DateTime selectedDate) async {
  try {
    final statusVal = status ? 'present' : 'absent';
    final storage = FirebaseFirestore.instance;

    final QuerySnapshot<Map<String, dynamic>> roommatesQuery = await storage
        .collection('hostels')
        .doc(hostelName)
        .collection('Roommates')
        .get();

    final batch = storage.batch();
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> attendanceFutures =
        [];

    for (final x in roommatesQuery.docs) {
      final attendanceQuery = x.reference
          .collection('Attendance')
          .where(FieldPath.documentId,
              isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate))
          .where('status',
              isEqualTo: statusVal == 'present' ? 'absent' : 'present')
          .get();

      attendanceFutures.add(attendanceQuery);
    }

    final List<QuerySnapshot<Map<String, dynamic>>> attendanceSnapshots =
        await Future.wait(attendanceFutures);

    for (int i = 0; i < attendanceSnapshots.length; i++) {
      final QuerySnapshot<Map<String, dynamic>> attendanceSnapshot =
          attendanceSnapshots[i];
      if (attendanceSnapshot.size > 0) {
        final QueryDocumentSnapshot<Map<String, dynamic>> attendanceDoc =
            attendanceSnapshot.docs.first;

        if (attendanceDoc.exists) {
          batch.set(
            attendanceDoc.reference,
            {'status': statusVal},
            SetOptions(merge: true),
          );
        }
      }
    }

    await batch.commit();
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> markAllRoommateAttendance(String hostelName, String roomName,
    bool status, DateTime selectedDate) async {
  try {
    String statusVal = status ? 'present' : 'absent';
    final storage = FirebaseFirestore.instance;
    final docsRoommatesRef = await storage
        .collection('hostels')
        .doc(hostelName)
        .collection('Rooms')
        .doc(roomName)
        .collection('Roommates')
        .get();
    final batch = storage.batch();
    for (final roommateDoc in docsRoommatesRef.docs) {
      final attendanceRef = await roommateDoc.reference
          .collection('Attendance')
          .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
          .get();
      if (attendanceRef.exists &&
          attendanceRef.data()!['status'] != 'onLeave' &&
          attendanceRef.data()!['status'] != 'internship') {
        batch.set(
          attendanceRef.reference,
          {'status': statusVal},
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
    return true;
  } catch (e) {
    return false;
  }
}

Future<Map<String, double>> getAttendanceStatistics(
    String email, String hostelName,
    {DateTimeRange? range, Source? source}) async {
  double presentData = 0;
  double absentData = 0;
  double leaveData = 0;
  double internshipData = 0;

  final storage = FirebaseFirestore.instance;
  final docsAttendanceRef = await storage
      .collection('hostels')
      .doc(hostelName)
      .collection('Roommates')
      .doc(email)
      .collection('Attendance')
      .get();
  for (final docs in docsAttendanceRef.docs) {
    if (range == null ||
        (DateFormat('yyyy-MM-dd')
                    .format(range.start)
                    .compareTo(docs.id.toString()) <=
                0 &&
            DateFormat('yyyy-MM-dd')
                    .format(range.end)
                    .compareTo(docs.id.toString()) >=
                0)) {
      switch (docs['status']) {
        case 'present':
          presentData += 1;
          break;
        case 'absent':
          absentData += 1;
          break;
        case 'onLeave':
          leaveData += 1;
          break;
        default:
          internshipData += 1;
      }
    }
  }
  Map<String, double> attendanceStats = {
    'present': presentData,
    'absent': absentData,
    'leave': leaveData,
    'internship': internshipData
  };

  return attendanceStats;
}

Future<Map<String, double>> getHostelAttendanceStatistics(
    String hostelName, DateTime date,
    {Source? source}) async {
  final storage = FirebaseFirestore.instance;

  final roommatesQuery = await storage
      .collection('hostels')
      .doc(hostelName)
      .collection('Roommates')
      .get(source == null ? null : GetOptions(source: source));

  final List<Future<DocumentSnapshot<Map<String, dynamic>>>> attendanceFutures =
      [];

  for (final x in roommatesQuery.docs) {
    final attendanceRef = x.reference
        .collection('Attendance')
        .doc(DateFormat('yyyy-MM-dd').format(date));

    attendanceFutures.add(attendanceRef.get());
  }

  final List<DocumentSnapshot<Map<String, dynamic>>> attendanceSnapshots =
      await Future.wait(attendanceFutures);

  double present = 0;
  double absent = 0;
  double leave = 0;
  double internship = 0;

  for (final attendanceSnapshot in attendanceSnapshots) {
    if (attendanceSnapshot.exists) {
      switch (attendanceSnapshot['status']) {
        case 'present':
          present += 1;
          break;
        case 'absent':
          absent += 1;
          break;
        case 'onLeave':
          leave += 1;
          break;
        default:
          internship += 1;
      }
    }
  }

  final attendanceStats = {
    'present': present,
    'absent': absent,
    'leave': leave,
    'internship': internship,
  };

  return attendanceStats;
}

Future<List<RoommateInfo>> getFilteredStudents(
    String statusVal, DateTime date, String hostelName,
    {Source? source}) async {
  final storage = FirebaseFirestore.instance;

  final QuerySnapshot<Map<String, dynamic>> roommatesQuery = await storage
      .collection('hostels')
      .doc(hostelName)
      .collection('Roommates')
      .get(source == null ? null : GetOptions(source: source));

  final List<Future<QuerySnapshot<Map<String, dynamic>>>> attendanceFutures =
      [];

  for (final x in roommatesQuery.docs) {
    final attendanceQuery = x.reference
        .collection('Attendance')
        .where(FieldPath.documentId,
            isEqualTo: DateFormat('yyyy-MM-dd').format(date))
        .where('status', isEqualTo: statusVal)
        .get();

    attendanceFutures.add(attendanceQuery);
  }

  final List<QuerySnapshot<Map<String, dynamic>>> attendanceSnapshots =
      await Future.wait(attendanceFutures);

  final List<RoommateInfo> list = [];

  for (int i = 0; i < attendanceSnapshots.length; i++) {
    final QuerySnapshot<Map<String, dynamic>> attendanceSnapshot =
        attendanceSnapshots[i];
    if (attendanceSnapshot.size > 0) {
      final QueryDocumentSnapshot<Map<String, dynamic>> attendanceDoc =
          attendanceSnapshot.docs.first;

      if (attendanceDoc.exists) {
        final data = attendanceDoc.data();
        final onLeave = data['onLeave'] ?? false;
        final leaveStartDate = data['leaveStartDate'] as Timestamp?;
        final leaveEndDate = data['leaveEndDate'] as Timestamp?;

        list.add(RoommateInfo(
          roomName: roommatesQuery.docs[i].data()['roomName'],
          roommateData: RoommateData(
            email: roommatesQuery.docs[i].id,
            onLeave: onLeave,
            leaveStartDate: leaveStartDate?.toDate(),
            leaveEndDate: leaveEndDate?.toDate(),
          ),
        ));
      }
    }
  }

  return list;
}
