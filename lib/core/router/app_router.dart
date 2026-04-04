import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/events/presentation/pages/home_page.dart';
import '../../features/checkin/presentation/pages/my_tickets_page.dart';
import '../../features/checkin/presentation/pages/qr_scanner_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/events/presentation/pages/create_event_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../shared/widgets/main_shell.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';

      if (authState is AuthInitial) return null;
      
      if (authState is AuthLoading) {
        if (isAuthRoute) return null;
        return null;
      }

      final isAuthenticated = authState is AuthAuthenticated;

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';

      final isOrganizerRoute =
          path == '/scan' || path == '/scan-out' || path == '/create-event';
      if (isOrganizerRoute && isAuthenticated) {
        final user = (authState as AuthAuthenticated).user;
        if (user.isAttendee) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/tickets', builder: (_, __) => const MyTicketsPage()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),

      GoRoute(
        path: '/scan',
        builder: (_, __) => const QrScannerPage(isCheckOut: false),
      ),
      GoRoute(
        path: '/scan-out',
        builder: (_, __) => const QrScannerPage(isCheckOut: true),
      ),
      GoRoute(
        path: '/create-event',
        builder: (_, __) => const CreateEventPage(),
      ),
      GoRoute(
        path: '/my-ticket',
        builder: (context, state) {
          final qrData = state.extra as String?;
          return _QrDisplayPage(qrData: qrData ?? '');
        },
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final dynamic _sub;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _QrDisplayPage extends StatelessWidget {
  final String qrData;
  const _QrDisplayPage({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      appBar: AppBar(title: const Text('Your QR Ticket')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Registration Successful!',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Save or screenshot your QR ticket'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/tickets'),
              child: const Text('View All Tickets'),
            ),
          ],
        ),
      ),
    );
  }
}