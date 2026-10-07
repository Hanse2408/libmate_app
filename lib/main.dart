import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'app/routes/app_router.dart';
import 'app/startup/app_startup.dart';
import 'app/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/splash/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() {
  final sinceLaunch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  // The splash shows straight away; Firebase starts behind it.
  runApp(_LibMateStartup(sinceLaunch: sinceLaunch));
}

/// Shows the LibMate splash while Firebase initialises, then hands over to
/// [MyApp], whose router keeps the splash up until the sign-in state (and
/// role) is known, and then routes as before.
class _LibMateStartup extends StatefulWidget {
  const _LibMateStartup({required this.sinceLaunch});

  final Stopwatch sinceLaunch;

  @override
  State<_LibMateStartup> createState() => _LibMateStartupState();
}

class _LibMateStartupState extends State<_LibMateStartup> {
  GoRouter? _router;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'LibMate could not start. Check your internet connection and reopen the app.',
        );
      }
      return;
    }
    final authProvider = AuthProvider();
    final startup = AppStartup(
      auth: authProvider,
      sinceLaunch: widget.sinceLaunch,
    );
    final appRouter = AppRouter(
      authProvider,
      startup: startup,
      createManagerRepository: () => AppRouter.firestoreManagerRepository(authProvider),
    );
    if (mounted) setState(() => _router = appRouter.router);
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router != null) return MyApp(router: router);
    return MaterialApp(
      title: 'LibMate',
      theme: AppTheme.light, // the splash is always light
      home: SplashScreen(errorMessage: _error),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LibMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
