import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/incharge_data.dart';
import 'student_detail_screen.dart';

class InchargeOverviewView extends ConsumerWidget {
  const InchargeOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(inchargeDataProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        return Center(child: Text('Error: $err'));
      },
      data: (data) {
        if (data == null) {
          return const Center(child: Text('No assigned incharge classes found.'));
        }

        final summary = data.classSummary;
        final students = data.studentsList;

        return Column(
          children: [
            // Summary Dashboard Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.department} - ${summary.semester} (${summary.section})',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatBox(label: 'Total Students', value: '${summary.totalStudents}'),
                      _StatBox(label: 'Avg. Attendance', value: '${summary.averageAttendance}%'),
                    ],
                  ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  
                  Color statusColor = Colors.green;
                  if (student.status == 'Warning') statusColor = Colors.orange;
                  if (student.status == 'Critical') statusColor = Colors.red;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentDetailScreen(student: student),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(student.name.isNotEmpty ? student.name[0] : '?', style: const TextStyle(color: Colors.black)),
                      ),
                      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(student.rollNumber),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${student.attendancePercentage}%', 
                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                          Text(student.status, style: TextStyle(fontSize: 12, color: statusColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}
