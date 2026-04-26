import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class InchargeClassSummary {
  final String department;
  final String semester;
  final String section;
  final int totalStudents;
  final double averageAttendance; // Percentage

  InchargeClassSummary({
    required this.department,
    required this.semester,
    required this.section,
    required this.totalStudents,
    required this.averageAttendance,
  });
}

class InchargeStudent {
  final String id;
  final String name;
  final String rollNumber;
  final double attendancePercentage;
  final String status; // 'Safe', 'Warning', 'Critical'

  InchargeStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.attendancePercentage,
    required this.status,
  });
}

class InchargeData {
  final InchargeClassSummary classSummary;
  final List<InchargeStudent> studentsList;

  InchargeData(this.classSummary, this.studentsList);
}

final inchargeDataProvider = FutureProvider<InchargeData?>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null || !user.isIncharge) return null;

  final client = Supabase.instance.client;

  // 1. Find the year and section the user is incharge of
  final inchargeClassResp = await client
      .from('class_enrollments')
      .select('section, year_of_study')
      .eq('user_id', user.id)
      .eq('role', 'incharge')
      .limit(1)
      .maybeSingle();

  if (inchargeClassResp == null) return null;

  final String section = inchargeClassResp['section']?.toString() ?? '';
  final int year = inchargeClassResp['year_of_study'] ?? 1;

  if (section.isEmpty) return null;

  // 2. Fetch all students in this section and year
  final studentsResp = await client
      .from('users')
      .select('id, name, identifier')
      .eq('section', section)
      .eq('year_of_study', year)
      .contains('roles', ['student']);

  if (studentsResp.isEmpty) {
    return InchargeData(
      InchargeClassSummary(
        department: "Computer Science",
        semester: "Year $year",
        section: section,
        totalStudents: 0,
        averageAttendance: 0.0,
      ),
      [],
    );
  }

  final List<String> studentIds = studentsResp.map((s) => s['id'].toString()).toList();

  // 3. Fetch all attendance records for these students
  final attendanceResp = await client
      .from('attendance_records')
      .select('student_id, status')
      .filter('student_id', 'in', studentIds);

  // Group attendance by student
  Map<String, int> studentTotalHours = {};
  Map<String, int> studentPresentHours = {};

  for (var rec in attendanceResp) {
    String sId = rec['student_id']?.toString() ?? '';
    String status = rec['status']?.toString() ?? '';

    studentTotalHours[sId] = (studentTotalHours[sId] ?? 0) + 1;
    if (status == 'P') {
      studentPresentHours[sId] = (studentPresentHours[sId] ?? 0) + 1;
    }
  }

  // 4. Calculate individual percentages and overall average
  List<InchargeStudent> studentList = [];
  double classTotalPercentSum = 0.0;
  int studentsWithData = 0;

  for (var userData in studentsResp) {
    final String sId = userData['id']?.toString() ?? '';
    
    int total = studentTotalHours[sId] ?? 0;
    int present = studentPresentHours[sId] ?? 0;
    
    double percent = total == 0 ? 0.0 : (present / total) * 100;
    if (total > 0) {
      classTotalPercentSum += percent;
      studentsWithData++;
    }

    String status = 'Safe';
    if (percent < 75.0) {
      status = 'Critical';
    } else if (percent < 85.0) {
      status = 'Warning';
    }

    studentList.add(InchargeStudent(
      id: sId,
      name: userData['name']?.toString() ?? 'Unknown',
      rollNumber: userData['identifier']?.toString() ?? 'Unknown',
      attendancePercentage: double.parse(percent.toStringAsFixed(1)),
      status: status,
    ));
  }

  // Sort list: Lowest attendance first
  studentList.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));

  double classAverage = studentsWithData == 0 ? 0.0 : (classTotalPercentSum / studentsWithData);

  final summary = InchargeClassSummary(
    department: "Computer Science",
    semester: "Year $year",
    section: section,
    totalStudents: studentsResp.length,
    averageAttendance: double.parse(classAverage.toStringAsFixed(1)),
  );

  return InchargeData(summary, studentList);
});
