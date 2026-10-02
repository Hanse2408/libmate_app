import 'package:flutter/material.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/librarian_mock_repository.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../widgets/librarian_bottom_nav.dart';

/// Wraps every Librarian page (built by the ShellRoute in librarian_routes.dart).
///
/// - Creates the shared mock repository once, so data survives navigation
///   between Librarian pages and is reset after sign out.
/// - Applies the Librarian theme without changing the app-wide theme.
/// - Shows the bottom navigation on every Librarian page (as in the Figma),
///   highlighting the section the page belongs to.
class LibrarianShell extends StatefulWidget {
  const LibrarianShell({
    super.key,
    required this.authProvider,
    required this.currentPath,
    required this.child,
  });

  final AuthProvider authProvider;
  final String currentPath;
  final Widget child;

  @override
  State<LibrarianShell> createState() => _LibrarianShellState();
}

class _LibrarianShellState extends State<LibrarianShell> {
  final LibrarianMockRepository _repository = LibrarianMockRepository();

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
          body: widget.child,
          bottomNavigationBar: LibrarianBottomNav(
            currentPath: widget.currentPath,
          ),
        ),
      ),
    );
  }
}
