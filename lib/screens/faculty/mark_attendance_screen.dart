import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/faculty_data.dart';
import '../../services/auth_service.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final ScheduledClass assignedClass;
  final DateTime attendanceDate;

  const MarkAttendanceScreen({
    super.key, 
    required this.assignedClass,
    required this.attendanceDate,
  });

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  // Map of studentId -> isPresent
  final Map<String, bool> _attendanceList = {};
  
  // Block period selections (Hours 1 through 8)
  late Set<int> _selectedHours;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedHours = {widget.assignedClass.hourIndex};
  }

  void _submitAttendance(String facultyId) async {
    if (_selectedHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one hour block.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AttendanceSubmissionService.submit(
        subjectId: widget.assignedClass.subjectId,
        facultyId: facultyId,
        attendanceList: _attendanceList,
        hours: _selectedHours,
        date: widget.attendanceDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Submitted Successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use the new classStudentsProvider with the formatted identifier: subjectId|section|year
    final asyncStudents = ref.watch(classStudentsProvider(
      '${widget.assignedClass.subjectId}|${widget.assignedClass.section}|${widget.assignedClass.yearOfStudy}'
    ));
    final authUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.assignedClass.subjectName, style: const TextStyle(fontSize: 16)),
            Text(
              'Date: ${widget.attendanceDate.day}/${widget.attendanceDate.month}/${widget.attendanceDate.year}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: asyncStudents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (students) {
          // Initialize map if it's empty
          if (_attendanceList.isEmpty && students.isNotEmpty) {
            for (var s in students) {
              _attendanceList[s.id] = true;
            }
          }

          return Column(
            children: [
              // Header with Hour Info
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text('${widget.assignedClass.hourIndex}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Period: Hour ${widget.assignedClass.hourIndex}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Section ${widget.assignedClass.section} • Year ${widget.assignedClass.yearOfStudy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Header for list
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${students.length} Students', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Present?', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Student List
              Expanded(
                child: students.isEmpty 
                  ? const Center(child: Text("No students enrolled in this class section."))
                  : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final isPresent = _attendanceList[s.id] ?? true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(s.name.isNotEmpty ? s.name[0] : '?', style: const TextStyle(color: Colors.black)),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s.rollNumber),
                      trailing: Switch(
                        value: isPresent,
                        activeThumbColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.shade100,
                        onChanged: (val) {
                          setState(() {
                            _attendanceList[s.id] = val;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitAttendance(authUser?.id ?? ''),
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('Submit Attendance'),
          ),
        ),
      ),
    );
  }
}
