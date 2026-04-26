import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class MappingManagementView extends StatefulWidget {
  const MappingManagementView({super.key});

  @override
  State<MappingManagementView> createState() => _MappingManagementViewState();
}

class _MappingManagementViewState extends State<MappingManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _faculty = [];
  List<Map<String, dynamic>> _subjects = [];
  
  bool _isLoading = true;

  // Enrollment Form State
  int _filterYear = 1;
  String _filterSection = 'A';
  String? _selectedStudent;
  String? _selectedSubject;
  bool _isEnrolling = false;

  // Incharge Form State
  int _selectedInchargeYear = 1;
  String _selectedInchargeSection = 'A';
  String? _selectedIncharge;
  bool _isSettingIncharge = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students = await _adminService.getStudents();
      final faculty = await _adminService.getFaculty();
      final subjects = await _adminService.getSubjects();
      
      setState(() {
        _students = students;
        _faculty = faculty;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) => 
      s['year_of_study'] == _filterYear && 
      s['section'] == _filterSection
    ).toList();
  }

  void _enrollStudent() async {
    if (_selectedStudent == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select student and subject')));
      return;
    }

    setState(() => _isEnrolling = true);
    try {
      await _adminService.enrollStudent(
        studentId: _selectedStudent!,
        subjectId: _selectedSubject!,
        section: _filterSection,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student enrolled successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrollment failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _setIncharge() async {
    if (_selectedIncharge == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a faculty member')));
      return;
    }

    setState(() => _isSettingIncharge = true);
    try {
      await _adminService.setClassIncharge(
        facultyId: _selectedIncharge!,
        section: _selectedInchargeSection,
        yearOfStudy: _selectedInchargeYear,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class incharge set successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSettingIncharge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.person_add), text: 'Enrollment'),
                Tab(icon: Icon(Icons.supervised_user_circle), text: 'Incharge'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentEnrollment(),
                _buildInchargeAssignment(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildStudentEnrollment() {
    final filtered = _filteredStudents;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownContainer(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            underline: const SizedBox(),
                            value: _filterYear,
                            items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                            onChanged: (v) => setState(() {
                              _filterYear = v!;
                              _selectedStudent = null;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownContainer(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            underline: const SizedBox(),
                            value: _filterSection,
                            items: ['A', 'B', 'C', 'D'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
                            onChanged: (v) => setState(() {
                              _filterSection = v!;
                              _selectedStudent = null;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildLabel('Select Student (${filtered.length} found)'),
                  const SizedBox(height: 8),
                  _buildDropdownContainer(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: _selectedStudent,
                      hint: const Text('Select Student'),
                      items: filtered.map((s) => DropdownMenuItem(
                        value: s['id'] as String, 
                        child: Text('${s['name']} (${s['identifier']})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedStudent = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Select Subject'),
                  const SizedBox(height: 8),
                  _buildDropdownContainer(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: _selectedSubject,
                      hint: const Text('Select Subject'),
                      items: _subjects.map((s) => DropdownMenuItem(
                        value: s['id'] as String, 
                        child: Text('${s['subject_code']} - ${s['subject_name']}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedSubject = v),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isEnrolling ? null : _enrollStudent,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: _isEnrolling ? const CircularProgressIndicator(color: Colors.white) : const Text('Enroll Student'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInchargeAssignment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('Select Faculty'),
                  const SizedBox(height: 8),
                  _buildDropdownContainer(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: _selectedIncharge,
                      hint: const Text('Select Faculty'),
                      items: _faculty.map((f) => DropdownMenuItem(
                        value: f['id'] as String, 
                        child: Text(f['name'], overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIncharge = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Year'),
                            const SizedBox(height: 8),
                            _buildDropdownContainer(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                underline: const SizedBox(),
                                value: _selectedInchargeYear,
                                items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                                onChanged: (v) => setState(() => _selectedInchargeYear = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Section'),
                            const SizedBox(height: 8),
                            _buildDropdownContainer(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                underline: const SizedBox(),
                                value: _selectedInchargeSection,
                                items: ['A', 'B', 'C', 'D'].map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))).toList(),
                                onChanged: (v) => setState(() => _selectedInchargeSection = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSettingIncharge ? null : _setIncharge,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: _isSettingIncharge ? const CircularProgressIndicator(color: Colors.white) : const Text('Set as Incharge'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
