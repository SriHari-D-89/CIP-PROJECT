import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;

  late final SupabaseClient _adminClient;

  AdminService._internal() {
    // Initialize a separate client using the Service Role Key for Admin operations
    _adminClient = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
    );
  }

  SupabaseClient get client => _adminClient;

  Future<List<Map<String, dynamic>>> getSubjects() async {
    return await _adminClient
        .from('subjects')
        .select('id, subject_name, subject_code');
  }

  Future<List<Map<String, dynamic>>> getFaculty() async {
    return await _adminClient
        .from('users')
        .select('id, name, identifier')
        .contains('roles', ['faculty']);
  }

  Future<void> saveTimetable({
    required String section,
    required int yearOfStudy,
    required int dayOfWeek,
    required List<Map<String, dynamic>> slots,
  }) async {
    // slots is a list of { hour_index: int, subject_id: String, faculty_id: String }

    // First, clear existing slots for this section/year/day to avoid conflicts on upsert
    await _adminClient
        .from('timetables')
        .delete()
        .eq('section', section)
        .eq('year_of_study', yearOfStudy)
        .eq('day_of_week', dayOfWeek);

    // Insert new slots
    if (slots.isNotEmpty) {
      final toInsert =
          slots
              .map(
                (s) => {
                  'section': section,
                  'year_of_study': yearOfStudy,
                  'day_of_week': dayOfWeek,
                  'hour_index': s['hour_index'],
                  'subject_id': s['subject_id'],
                  'faculty_id': s['faculty_id'],
                },
              )
              .toList();

      await _adminClient.from('timetables').insert(toInsert);
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    return await _adminClient
        .from('users')
        .select('id, name, identifier, section, year_of_study')
        .contains('roles', ['student']);
  }

  Future<void> enrollStudent({
    required String studentId,
    required String subjectId,
    required String section,
  }) async {
    await _adminClient.from('class_enrollments').upsert({
      'user_id': studentId,
      'subject_id': subjectId,
      'section': section,
      'role': 'student',
    }, onConflict: 'user_id, subject_id, section');
  }

  Future<void> setClassIncharge({
    required String facultyId,
    required String section,
    required int yearOfStudy,
  }) async {
    // 1. Ensure the user has the 'incharge' role in their profile
    final userRes = await _adminClient.from('users').select('roles').eq('id', facultyId).single();
    List<String> currentRoles = List<String>.from(userRes['roles'] ?? []);
    
    if (!currentRoles.contains('incharge')) {
      currentRoles.add('incharge');
      await _adminClient.from('users').update({'roles': currentRoles}).eq('id', facultyId);
    }

    // 2. Map the faculty to the section in class_enrollments
    await _adminClient.from('class_enrollments').upsert({
      'user_id': facultyId,
      'section': section,
      'year_of_study': yearOfStudy,
      'role': 'incharge',
    }, onConflict: 'user_id, section, year_of_study, role');
  }

  /// Creates a new Supabase Auth user via the Admin API and inserts their record into `public.users`.
  /// Returns the newly created user's UUID on success.
  Future<String> createUser({
    required String email,
    required String password,
    required String name,
    required String identifier,
    required List<String> roles,
    String? section,
    int? yearOfStudy,
    String? courseGroup,
  }) async {
    // 1. Create the Auth user using the Admin API
    final res = await _adminClient.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm:
            true, // Automatically confirm email so they can log in immediately
      ),
    );

    if (res.user == null) {
      throw Exception('Failed to create Auth User');
    }

    final userId = res.user!.id;

    // 2. Insert the user details into public.users
    await _adminClient.from('users').insert({
      'id': userId,
      'email': email,
      'name': name,
      'identifier': identifier,
      'roles': roles,
      'must_change_password': true,
      'section': section,
      'year_of_study': yearOfStudy,
      'course_group': courseGroup,
    });

    return userId;
  }

  /// Settings management
  Future<String?> getSetting(String key) async {
    try {
      final res = await _adminClient.from('app_settings').select('value').eq('key', key).single();
      return res['value'];
    } catch (e) {
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    await _adminClient.from('app_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
