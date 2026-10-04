import 'package:flutter/material.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/librarian_repository.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/librarian_bottom_nav.dart';

/// Wraps every Librarian page (built by the ShellRoute in librarian_routes.dart).
///
/// - Creates the shared repository once (Firestore in the real app), so data
///   survives navigation between Librarian pages and listeners stop after
///   sign out.
/// - Applies the Librarian theme without changing the app-wide theme.
/// - Shows the bottom navigation on every Librarian page (as in the Figma),
///   highlighting the section the page belongs to.
/// - Shows a banner when demo data is used or data could not be loaded.
class LibrarianShell extends StatefulWidget {
  const LibrarianShell({
    super.key,
    required this.authProvider,
    required this.createRepository,
    required this.currentPath,
    required this.child,
  });

  final AuthProvider authProvider;
  final LibrarianRepository Function() createRepository;
  final String currentPath;
  final Widget child;

  @override
  State<LibrarianShell> createState() => _LibrarianShellState();
}

class _LibrarianShellState extends State<LibrarianShell> {
  late final LibrarianRepository _repository = widget.createRepository();

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LibrarianTheme.light,
      child: LibrarianScope(
        repository: _repository,
        authProvider: widget.authProvider,
        child: Scaffold(
          body: Column(
            children: [
              ListenableBuilder(
                listenable: _repository,
                builder: (context, _) => _DataStatusBanner(repository: _repository),
              ),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: LibrarianBottomNav(
            currentPath: widget.currentPath,
          ),
        ),
      ),
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
                  style: const TextStyle(color: LibrarianColors.text, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
