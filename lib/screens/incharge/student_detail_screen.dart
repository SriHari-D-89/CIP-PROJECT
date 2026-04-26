import 'package:flutter/material.dart';
import '../../models/incharge_data.dart';

class StudentDetailScreen extends StatelessWidget {
  final InchargeStudent student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    if (student.status == 'Warning') statusColor = Colors.orange;
    if (student.status == 'Critical') statusColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(student.name[0], style: const TextStyle(fontSize: 24, color: Colors.black)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Roll No: ${student.rollNumber}', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _DetailStatBox(
                  label: 'Overall Attendance',
                  value: '${student.attendancePercentage}%',
                  valueColor: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DetailStatBox(
                  label: 'Status',
                  value: student.status,
                  valueColor: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Subject-wise Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Mock Breakdown list
          _SubjectTile(subject: 'Data Structures', present: 34, total: 40),
          _SubjectTile(subject: 'Operating Systems', present: 28, total: 40),
          _SubjectTile(subject: 'Discrete Mathematics', present: 40, total: 42),
        ],
      ),
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailStatBox({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String subject;
  final int present;
  final int total;

  const _SubjectTile({required this.subject, required this.present, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (present / total) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: present / total,
            backgroundColor: Colors.grey.shade200,
            color: percentage >= 75 ? Colors.green : Colors.red,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('$present / $total Hours Present', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
