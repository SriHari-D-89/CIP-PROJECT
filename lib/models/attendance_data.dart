import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class SubjectAttendance {
  final String subjectCode;
  final String subjectName;
  final String facultyName;
  final int hoursPresent;
  final int hoursAbsent;

  SubjectAttendance({
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.hoursPresent,
    required this.hoursAbsent,
  });

  int get totalHours => hoursPresent + hoursAbsent;
  double get percentage => totalHours == 0 ? 0 : (hoursPresent / totalHours) * 100;
}

class HourAttendance {
  final int dayIndex;
  final int hourIndex;
  final String status; // 'P', 'A', or ''
  final String? subjectName;
  final String? facultyName;

  HourAttendance({
    required this.dayIndex,
    required this.hourIndex,
    required this.status,
    this.subjectName,
    this.facultyName,
  });
}

// Live Data Provider
final studentAttendanceProvider = FutureProvider<StudentAttendanceData>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) {
    return StudentAttendanceData(subjects: [], dailyMatrix: [], totalPercentage: 0.0);
  }

  final supabase = Supabase.instance.client;

  // 1. Fetch subjects the student is enrolled in
  final enrollmentsResp = await supabase
      .from('class_enrollments')
      .select('subject_id, subjects(subject_code, subject_name)')
      .eq('user_id', user.id)
      .eq('role', 'student');

  // 2. Fetch all attendance records for this student
  final recordsResp = await supabase
      .from('attendance_records')
      .select('*, subjects(subject_code, subject_name), users!recorded_by_faculty_id(name)')
      .eq('student_id', user.id);

  // 3. Process Subject Stats
  int grandTotalPresent = 0;
  int grandTotalHours = 0;
  
  List<SubjectAttendance> subjectsList = [];
  Map<String, dynamic> subjectMap = {}; // subject_id -> data

  for (var enroll in enrollmentsResp) {
    final subId = enroll['subject_id'];
    final subData = enroll['subjects'];
    subjectMap[subId] = {
      'code': subData['subject_code'],
      'name': subData['subject_name'],
      'present': 0,
      'absent': 0,
    };
  }

  for (var rec in recordsResp) {
    final subId = rec['subject_id'];
    final status = rec['status']; // 'P' or 'A'
    if (subjectMap.containsKey(subId)) {
      if (status == 'P') {
        subjectMap[subId]['present'] += 1;
        grandTotalPresent += 1;
      } else if (status == 'A') {
        subjectMap[subId]['absent'] += 1;
      }
      grandTotalHours += 1;
    }
  }

  for (var sub in subjectMap.values) {
    subjectsList.add(SubjectAttendance(
      subjectCode: sub['code'],
      subjectName: sub['name'],
      facultyName: 'Assigned Faculty', // Requires mapping faculty to subject if needed
      hoursPresent: sub['present'],
      hoursAbsent: sub['absent'],
    ));
  }

  double totalPct = grandTotalHours == 0 ? 0 : (grandTotalPresent / grandTotalHours) * 100;

  // 4. Process Daily Matrix (Only for dates present in records, excluding weekends)
  List<DailyAttendance> dailyMatrix = [];

  // Create a fast lookup map for records: "YYYY-MM-DD" -> { hour_index: rec }
  // And keep track of unique valid dates
  Map<String, Map<int, dynamic>> recordLookup = {};
  Set<String> uniqueDateStrings = {};

  for (var rec in recordsResp) {
    String d = rec['date']; // YYYY-MM-DD format
    
    // Parse to check if it's a weekend
    DateTime parsedDate = DateTime.parse(d);
    if (parsedDate.weekday == DateTime.saturday || parsedDate.weekday == DateTime.sunday) {
      continue; // Skip weekends entirely
    }

    uniqueDateStrings.add(d);
    
    int hr = rec['hour_index'];
    if (recordLookup[d] == null) recordLookup[d] = {};
    recordLookup[d]![hr] = rec;
  }

  // Sort dates descending (newest first)
  List<String> sortedDates = uniqueDateStrings.toList()
    ..sort((a, b) => b.compareTo(a));

  for (int i = 0; i < sortedDates.length; i++) {
    String dStr = sortedDates[i];
    DateTime current = DateTime.parse(dStr);
    
    List<HourAttendance> hoursList = [];
    for (int h = 1; h <= 8; h++) {
      String status = '';
      String? subName;
      String? facName;

      if (recordLookup[dStr] != null && recordLookup[dStr]![h] != null) {
        var r = recordLookup[dStr]![h];
        status = r['status'];
        subName = r['subjects']['subject_name'];
        facName = r['users']?['name']; // using foreign key to users
      }

      hoursList.add(HourAttendance(
        dayIndex: i, // index in the list
        hourIndex: h,
        status: status,
        subjectName: subName,
        facultyName: facName,
      ));
    }

    dailyMatrix.add(DailyAttendance(
      dayIndex: i,
      date: current,
      hours: hoursList,
    ));
  }

  // Ensure matrix is sorted newest first if desired, or leave chronological
  return StudentAttendanceData(
    subjects: subjectsList,
    dailyMatrix: dailyMatrix,
    totalPercentage: totalPct,
  );
});

class StudentAttendanceData {
  final double totalPercentage;
  final List<SubjectAttendance> subjects;
  final List<DailyAttendance> dailyMatrix;

  StudentAttendanceData({
    required this.totalPercentage,
    required this.subjects,
    required this.dailyMatrix,
  });
}

class DailyAttendance {
  final int dayIndex;
  final DateTime date;
  final List<HourAttendance> hours; // 8 items

  DailyAttendance({required this.dayIndex, required this.date, required this.hours});
}
