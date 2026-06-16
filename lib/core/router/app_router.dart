import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/students/students_list_screen.dart';
import '../../presentation/screens/students/student_detail_screen.dart';
import '../../presentation/screens/students/add_student_screen.dart';
import '../../presentation/screens/sessions/add_session_screen.dart';
import '../../presentation/screens/attendance/attendance_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/share/share_screen.dart';
import '../../presentation/screens/parent/parent_report_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuth = loc == '/login' || loc == '/signup';
      final isPublicReport = loc.startsWith('/report/');
      if (isPublicReport) return null;
      if (!loggedIn) return isAuth ? null : '/login';
      if (isAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/students', builder: (_, __) => const StudentsListScreen()),
      GoRoute(
        path: '/students/add',
        builder: (_, __) => const AddStudentScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (_, s) => StudentDetailScreen(studentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id/session',
        builder: (_, s) => AddSessionScreen(studentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id/share',
        builder: (_, s) => ShareScreen(studentId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: '/report/:token',
        builder: (_, s) => ParentReportScreen(token: s.pathParameters['token']!),
      ),
    ],
  );
});
