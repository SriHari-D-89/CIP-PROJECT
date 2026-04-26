import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class TimetableManagementView extends StatefulWidget {
  const TimetableManagementView({super.key});

  @override
  State<TimetableManagementView> createState() => _TimetableManagementViewState();
}

class _TimetableManagementViewState extends State<TimetableManagementView> {
  final _adminService = AdminService();
  
  String _selectedSection = 'A';
  int _selectedDay = 1; // 1 = Monday
  int _selectedYear = 1;
  
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _faculty = [];
  
  // Mapping of hour (1-8) to {subjectId, facultyId}
  final Map<int, Map<String, String?>> _slots = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final subs = await _adminService.getSubjects();
      final facs = await _adminService.getFaculty();
      
      setState(() {
        _subjects = subs;
        _faculty = facs;
        _isLoading = false;
      });
      
      _fetchExistingTimetable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _fetchExistingTimetable() async {
    setState(() => _isLoading = true);
    // Clear slots first
    for (int i = 1; i <= 8; i++) {
      _slots[i] = {'subjectId': null, 'facultyId': null};
    }

    try {
      final response = await _adminService.client
          .from('timetables')
          .select()
          .eq('section', _selectedSection)
          .eq('year_of_study', _selectedYear)
          .eq('day_of_week', _selectedDay);

      for (var row in response) {
        int hr = row['hour_index'];
        _slots[hr] = {
          'subjectId': row['subject_id'],
          'facultyId': row['faculty_id'],
        };
      }
    } catch (e) {
      // Ignore if no records
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionDropdown() {
    return _buildDropdownContainer(
      label: 'Section',
      child: DropdownButton<String>(
        value: _selectedSection,
        isExpanded: true,
        underline: const SizedBox(),
        items: ['A', 'B', 'C', 'D'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
        onChanged: (v) {
          setState(() => _selectedSection = v!);
          _fetchExistingTimetable();
        },
      ),
    );
  }

  Widget _buildYearDropdown() {
    return _buildDropdownContainer(
      label: 'Year of Study',
      child: DropdownButton<int>(
        value: _selectedYear,
        isExpanded: true,
        underline: const SizedBox(),
        items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
        onChanged: (v) {
          setState(() => _selectedYear = v!);
          _fetchExistingTimetable();
        },
      ),
    );
  }

  Widget _buildDayDropdown(List<String> dayNames) {
    return _buildDropdownContainer(
      label: 'Day',
      child: DropdownButton<int>(
        value: _selectedDay,
        isExpanded: true,
        underline: const SizedBox(),
        items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(dayNames[i]))),
        onChanged: (v) {
          setState(() => _selectedDay = v!);
          _fetchExistingTimetable();
        },
      ),
    );
  }

  Widget _buildDropdownContainer({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown(int hour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String>(
        hint: const Text('Subject'),
        isExpanded: true,
        underline: const SizedBox(),
        value: _slots[hour]?['subjectId'],
        items: [
          const DropdownMenuItem(value: null, child: Text('No Class')),
          ..._subjects.map((s) => DropdownMenuItem(
            value: s['id'] as String,
            child: Text('${s['subject_code']} - ${s['subject_name']}', overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: (v) => setState(() => _slots[hour]!['subjectId'] = v),
      ),
    );
  }

  Widget _buildFacultyDropdown(int hour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String>(
        hint: const Text('Faculty'),
        isExpanded: true,
        underline: const SizedBox(),
        value: _slots[hour]?['facultyId'],
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Faculty')),
          ..._faculty.map((f) => DropdownMenuItem(
            value: f['id'] as String,
            child: Text(f['name'], overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: (v) => setState(() => _slots[hour]!['facultyId'] = v),
      ),
    );
  }

  void _save() async {
    setState(() => _isSaving = true);
    
    List<Map<String, dynamic>> slotsToSave = [];
    _slots.forEach((hour, data) {
      if (data['subjectId'] != null && data['facultyId'] != null) {
        slotsToSave.add({
          'hour_index': hour,
          'subject_id': data['subjectId'],
          'faculty_id': data['facultyId'],
        });
      }
    });

    try {
      await _adminService.saveTimetable(
        section: _selectedSection,
        yearOfStudy: _selectedYear,
        dayOfWeek: _selectedDay,
        slots: slotsToSave,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        _buildSectionDropdown(),
                        const SizedBox(height: 12),
                        _buildYearDropdown(),
                        const SizedBox(height: 12),
                        _buildDayDropdown(dayNames),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _buildSectionDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildYearDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDayDropdown(dayNames)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                int hour = index + 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 450;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(radius: 18, child: Text('$hour', style: const TextStyle(fontSize: 14))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: isSmall 
                                ? Column(
                                    children: [
                                      _buildSubjectDropdown(hour),
                                      const SizedBox(height: 8),
                                      _buildFacultyDropdown(hour),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: _buildSubjectDropdown(hour)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildFacultyDropdown(hour)),
                                    ],
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Timetable'),
            ),
          ),
        ],
      ),
    );
  }
}
