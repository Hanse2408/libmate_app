import 'package:flutter/widgets.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/manager_repository.dart';

class ManagerScope extends InheritedWidget {
  const ManagerScope({
    super.key,
    required this.repository,
    required this.authProvider,
    required super.child,
  });

  final ManagerRepository repository;
  final AuthProvider authProvider;

  static ManagerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ManagerScope>();
    assert(scope != null, 'ManagerScope not found above this context.');
    return scope!;
  }

  static ManagerScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ManagerScope>();
    assert(scope != null, 'ManagerScope not found above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ManagerScope oldWidget) {
    return repository != oldWidget.repository ||
        authProvider != oldWidget.authProvider;
  }
}
