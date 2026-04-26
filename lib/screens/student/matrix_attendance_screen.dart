import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance_data.dart';

class MatrixAttendanceScreen extends ConsumerWidget {
  const MatrixAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(studentAttendanceProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final dailyMatrix = data.dailyMatrix;

        if (dailyMatrix.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classes you attend will appear here.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.primary,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance History',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _LegendItem(color: Colors.green, label: 'P'),
                      SizedBox(width: 12),
                      _LegendItem(color: Colors.red, label: 'A'),
                    ],
                  ),
                ],
              ),
            ),
            // Header Row for Hours 1-8
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const SizedBox(width: 80), // Space for Day/Date
                  const SizedBox(width: 8), // Divider spacing
                  Expanded(
                    child: Row(
                      children: List.generate(
                        8,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: dailyMatrix.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final dayInfo = dailyMatrix[index];
                  return _DailyRow(dayInfo: dayInfo);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyAttendance dayInfo;

  const _DailyRow({required this.dayInfo});

  @override
  Widget build(BuildContext context) {
    // Formatting date to e.g., "Oct 12"
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    
    final dateStr = '${months[dayInfo.date.month - 1]} ${dayInfo.date.day}';
    final dayName = weekdays[dayInfo.date.weekday - 1];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Day and Date
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        
        // Vertical Divider Look
        Container(
          width: 2,
          height: 30,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),

        // Right Column: The 8 Hour Boxes
        Expanded(
          child: Row(
            children: dayInfo.hours.map((hourItem) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _MatrixCell(item: hourItem),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final HourAttendance item;

  const _MatrixCell({required this.item});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.grey.shade200;
    Color textColor = Colors.black;

    if (item.status == 'P') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else if (item.status == 'A') {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    }

    return InkWell(
      onTap: () {
        if (item.status.isNotEmpty) {
          _showDetails(context);
        }
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Center(
            child: Text(
              item.status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hour ${item.hourIndex} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${item.status == 'P' ? 'Present' : 'Absent'}', 
                 style: TextStyle(fontWeight: FontWeight.bold, 
                                  color: item.status == 'P' ? Colors.green : Colors.red)),
            const SizedBox(height: 12),
            Text('Subject: ${item.subjectName ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Faculty: ${item.facultyName ?? "N/A"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
