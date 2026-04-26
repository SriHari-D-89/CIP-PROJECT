import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class ScheduledClass {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String section;
  final int yearOfStudy;
  final int hourIndex;
  final int totalStudents;

  ScheduledClass({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.section,
    required this.yearOfStudy,
    required this.hourIndex,
    required this.totalStudents,
  });
}

class StudentBasic {
  final String id;
  final String rollNumber;
  final String name;

  StudentBasic({
    required this.id,
    required this.rollNumber,
    required this.name,
  });
}

// 1. Fetch the classes assigned to the logged-in Faculty for a SPECIFIC date
final facultyClassesProvider = FutureProvider.family<List<ScheduledClass>, DateTime>((ref, date) async {
  final user = ref.watch(authProvider);
  if (user == null || !user.isFaculty) return [];

  final client = Supabase.instance.client;
  int dayOfWeek = date.weekday; // 1=Mon, 7=Sun

  // Get timetable slots for this faculty on this day
  final timetableResp = await client
      .from('timetables')
      .select('''
        hour_index,
        section,
        year_of_study,
        subject_id,
        subjects (
          subject_name,
          subject_code
        )
      ''')
      .eq('faculty_id', user.id)
      .eq('day_of_week', dayOfWeek);

  List<ScheduledClass> scheduled = [];

  for (var row in timetableResp) {
    final String subjectId = row['subject_id']?.toString() ?? '';
    final String section = row['section']?.toString() ?? '';
    final int year = row['year_of_study'] ?? 1;
    final subjectData = row['subjects'];

    // Get the total number of students in this section/year
    final countResp = await client
        .from('users')
        .select('id')
        .eq('section', section)
        .eq('year_of_study', year)
        .contains('roles', ['student']);
        
    scheduled.add(ScheduledClass(
      subjectId: subjectId,
      subjectName: subjectData['subject_name'] ?? 'Unknown',
      subjectCode: subjectData['subject_code'] ?? 'N/A',
      section: section,
      yearOfStudy: year,
      hourIndex: row['hour_index'],
      totalStudents: countResp.length,
    ));
  }

  // Sort by hour
  scheduled.sort((a, b) => a.hourIndex.compareTo(b.hourIndex));
  return scheduled;
});

// 2. Fetch the specific students in a class (Identified by "subject_id|section|year")
final classStudentsProvider = FutureProvider.family<List<StudentBasic>, String>((ref, classIdentifier) async {
  final parts = classIdentifier.split('|');
  if (parts.length != 3) return [];

  final section = parts[1];
  final year = int.parse(parts[2]);

  final response = await Supabase.instance.client
      .from('users')
      .select('id, name, identifier')
      .eq('section', section)
      .eq('year_of_study', year)
      .contains('roles', ['student']);

  return response.map<StudentBasic>((userData) {
    return StudentBasic(
      id: userData['id']?.toString() ?? '',
      rollNumber: userData['identifier']?.toString() ?? 'Unknown',
      name: userData['name']?.toString() ?? 'Unknown',
    );
  }).toList()
    ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
});

// 3. Service to submit attendance
class AttendanceSubmissionService {
  static Future<void> submit({
    required String subjectId,
    required String facultyId,
    required Map<String, bool> attendanceList, // studentId -> isPresent
    required Set<int> hours,
    required DateTime date,
  }) async {
    final client = Supabase.instance.client;
    
    // Build multiple insert rows
    List<Map<String, dynamic>> recordsToInsert = [];
    
    for (int hour in hours) {
      attendanceList.forEach((studentId, isPresent) {
        recordsToInsert.add({
          'subject_id': subjectId,
          'student_id': studentId,
          'recorded_by_faculty_id': facultyId,
          'date': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
          'hour_index': hour,
          'status': isPresent ? 'P' : 'A'
        });
      });
    }

    // Insert all records in one batch. 
    // Uses upsert so if a professor "re-submits" it safely overwrites.
    await client
        .from('attendance_records')
        .upsert(recordsToInsert, onConflict: 'subject_id, student_id, date, hour_index');
  }
}
