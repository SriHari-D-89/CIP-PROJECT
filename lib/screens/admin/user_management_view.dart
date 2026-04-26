import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();

  bool _isStudent = true;
  bool _isFaculty = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  String? _selectedSection;
  int? _selectedYear;
  String? _selectedCourseGroup;

  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _courseGroups = ['Engineering', 'Arts & Science'];

  List<int> get _availableYears {
    if (_selectedCourseGroup == 'Engineering') return [1, 2, 3, 4];
    if (_selectedCourseGroup == 'Arts & Science') return [1, 2, 3];
    return [1, 2, 3, 4]; // Default
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> roles = [];
    if (_isStudent) roles.add('student');
    if (_isFaculty) roles.add('faculty');
    if (_isAdmin) roles.add('admin');

    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one role.')),
      );
      return;
    }

    if (_isStudent &&
        (_selectedSection == null ||
            _selectedYear == null ||
            _selectedCourseGroup == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all academic details for the student.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AdminService().createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        identifier: _identifierController.text.trim(),
        roles: roles,
        section: _isStudent ? _selectedSection : null,
        yearOfStudy: _isStudent ? _selectedYear : null,
        courseGroup: _isStudent ? _selectedCourseGroup : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _identifierController.clear();
      setState(() {
        _isStudent = true;
        _isFaculty = false;
        _isAdmin = false;
        _selectedSection = null;
        _selectedYear = null;
        _selectedCourseGroup = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create New User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              v!.isEmpty || !v.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Temporary Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator:
                          (v) => v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _identifierController,
                      decoration: const InputDecoration(
                        labelText: 'Roll Number / Employee ID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Assign Roles:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Student'),
                      value: _isStudent,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _isStudent = true;
                            _isFaculty = false;
                            _isAdmin = false;
                          });
                        } else {
                          setState(() => _isStudent = false);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Faculty'),
                      value: _isFaculty,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _isFaculty = true;
                            _isStudent = false;
                            _isAdmin = false;
                          });
                        } else {
                          setState(() => _isFaculty = false);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Administrator'),
                      value: _isAdmin,
                      onChanged: (v) {
                        if (v == true) {
                          setState(() {
                            _isAdmin = true;
                            _isStudent = false;
                            _isFaculty = false;
                          });
                        } else {
                          setState(() => _isAdmin = false);
                        }
                      },
                    ),
                    if (_isStudent) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Academic Details (Student):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourseGroup,
                        decoration: const InputDecoration(
                          labelText: 'Course Group',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _courseGroups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCourseGroup = v;
                            // Reset year if invalid for new group
                            if (_selectedYear != null &&
                                !_availableYears.contains(_selectedYear)) {
                              _selectedYear = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year of Study',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _availableYears
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('Year $y'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedYear = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _sections
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text('Section $s'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedSection = v),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createUser,
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Create Account',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
