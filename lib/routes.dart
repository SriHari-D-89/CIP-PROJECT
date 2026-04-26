import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/professor/professor_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/change_password_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentDashboard(),
    ),
    GoRoute(
      path: '/professor',
      builder: (context, state) => const ProfessorDashboard(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) {
        final mandatory = state.uri.queryParameters['mandatory'] == 'true';
        return ChangePasswordScreen(isMandatory: mandatory);
      },
    ),
  ],
);
