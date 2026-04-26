import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../faculty/faculty_classes_view.dart';
import '../incharge/incharge_overview_view.dart';

class ProfessorDashboard extends ConsumerStatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  ConsumerState<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends ConsumerState<ProfessorDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    if (user == null) return const Scaffold();

    final bool isBoth = user.isFaculty && user.isIncharge;
    
    // Connect both completed views
    final List<Widget> screens = [
      if (user.isFaculty) const FacultyClassesView(),
      if (user.isIncharge) const InchargeOverviewView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name.split(" ").last}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: isBoth ? screens[_currentIndex] : screens[0],
      bottomNavigationBar: isBoth ? BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Teaching',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Incharge',
          ),
        ],
      ) : null,
    );
  }
}
