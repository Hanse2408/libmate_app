import 'package:flutter/widgets.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/librarian_repository.dart';

/// Makes the Librarian's shared state available to every Librarian screen.
///
/// The project does not use the `provider` package, so this small
/// InheritedWidget plays that role: LibrarianShell creates the objects once
/// and screens read them with `LibrarianScope.of(context)`. Screens rebuild
/// on changes by wrapping their UI in a ListenableBuilder.
class LibrarianScope extends InheritedWidget {
  const LibrarianScope({
    super.key,
    required this.repository,
    required this.authProvider,
    required super.child,
  });

  final LibrarianRepository repository;

  /// Existing app-wide auth state, used for the librarian's name and sign out.
  final AuthProvider authProvider;

  static LibrarianScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LibrarianScope>();
    assert(scope != null, 'LibrarianScope not found above this context.');
    return scope!;
  }

  /// Like [of] but without subscribing to changes, for use in button
  /// callbacks (outside build).
  static LibrarianScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LibrarianScope>();
    assert(scope != null, 'LibrarianScope not found above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(LibrarianScope oldWidget) {
    return repository != oldWidget.repository ||
        authProvider != oldWidget.authProvider;
  }
}
