import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/librarian_routes.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/librarian_repository.dart';
import '../models/librarian_notification.dart';
import '../providers/ebook_provider.dart';
import '../providers/librarian_toast_controller.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/librarian_bottom_nav.dart';
import '../widgets/librarian_notification_toast.dart';

/// Wraps every Librarian page (built by the ShellRoute in librarian_routes.dart).
///
/// - Creates the shared repository once (Firestore in the real app), so data
///   survives navigation between Librarian pages and listeners stop after
///   sign out.
/// - Applies the Librarian light or dark theme (Settings > Dark Mode) without
///   changing the app-wide theme, so Student / Manager screens are unaffected.
/// - Shows the bottom navigation on every Librarian page (as in the Figma),
///   highlighting the section the page belongs to.
/// - Shows a banner when demo data is used or data could not be loaded.
class LibrarianShell extends StatefulWidget {
  const LibrarianShell({
    super.key,
    required this.authProvider,
    required this.createRepository,
    required this.createEbooks,
    required this.currentPath,
    required this.child,
  });

  final AuthProvider authProvider;
  final LibrarianRepository Function() createRepository;
  final EbookProvider Function() createEbooks;
  final String currentPath;
  final Widget child;

  @override
  State<LibrarianShell> createState() => _LibrarianShellState();
}

class _LibrarianShellState extends State<LibrarianShell> {
  late final LibrarianRepository _repository = widget.createRepository();

  /// Shows a toast for each new notification on every Librarian page. One
  /// per signed-in session: created with the repository, disposed with it.
  late final LibrarianToastController _toasts = LibrarianToastController(
    notifications: _repository.incomingNotifications,
  );

  /// Created the first time an e-book screen asks for it.
  EbookProvider? _ebooks;
  EbookProvider _ebookProvider() => _ebooks ??= widget.createEbooks();

  // Built once; the Theme widget then only notifies when the mode changes.
  static final ThemeData _lightTheme = LibrarianTheme.light;
  static final ThemeData _darkTheme = LibrarianTheme.dark;

  @override
  void dispose() {
    _toasts.dispose();
    _repository.dispose();
    _ebooks?.dispose();
    // Leave the default palette for the next sign-in.
    LibrarianColors.palette = LibrarianPalette.light;
    super.dispose();
  }

  /// Librarian widgets read their colours from LibrarianColors while they
  /// build, so after a mode change every one of them is rebuilt once (the
  /// same thing hot reload does). Screens keep their state and scroll.
  void _rebuildAllLibrarianWidgets() {
    if (!mounted) return;
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  /// Same as tapping it on the Notifications screen: marks it read and opens
  /// its reservation (or the Notifications screen).
  Future<void> _openToast(LibrarianNotification notification) async {
    _toasts.dismiss();
    final router = GoRouter.of(context);
    await _repository.markNotificationRead(notification.id);
    final reservationId = notification.reservationId;
    if (!mounted) return;
    router.go(
      reservationId == null
          ? LibrarianRoutes.notifications
          : Uri(
              path: LibrarianRoutes.reservationDetails(reservationId),
              queryParameters: {'from': LibrarianRoutes.notifications},
            ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final palette = _repository.darkMode ? LibrarianPalette.dark : LibrarianPalette.light;
        if (!identical(LibrarianColors.palette, palette)) {
          LibrarianColors.palette = palette;
          WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAllLibrarianWidgets());
        }

        return Theme(
          data: palette.isDark ? _darkTheme : _lightTheme,
          child: LibrarianScope(
            repository: _repository,
            authProvider: widget.authProvider,
            ebooks: _ebookProvider,
            child: Stack(
              children: [
                Scaffold(
                  body: Column(
                    children: [
                      _DataStatusBanner(repository: _repository),
                      Expanded(child: widget.child),
                    ],
                  ),
                  bottomNavigationBar: LibrarianBottomNav(
                    currentPath: widget.currentPath,
                  ),
                ),
                // New-notification toast, above every Librarian page.
                LibrarianNotificationToast(controller: _toasts, onTap: _openToast),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Thin strip above the page: demo-data warning or a load error.
class _DataStatusBanner extends StatelessWidget {
  const _DataStatusBanner({required this.repository});

  final LibrarianRepository repository;

  @override
  Widget build(BuildContext context) {
    final error = repository.loadError;
    if (error == null && !repository.isDemoData) return const SizedBox.shrink();

    final isError = error != null;
    final color = isError ? LibrarianColors.unavailable : LibrarianColors.gold;
    return Material(
      color: color.withValues(alpha: 0.15),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LibrarianSpacing.md,
            vertical: LibrarianSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.cloud_off : Icons.science_outlined,
                size: 18,
                color: LibrarianColors.text,
              ),
              const SizedBox(width: LibrarianSpacing.sm),
              Expanded(
                child: Text(
                  error ?? 'Demo data: changes are not saved to Firebase.',
                  style: TextStyle(color: LibrarianColors.text, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
