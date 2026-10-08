import 'package:flutter/widgets.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/manager_repository.dart';

/// Shares the Manager's [repository] and [authProvider] with the Manager
/// screens. Extends [InheritedNotifier] (not a plain [InheritedWidget]) so
/// that every Firestore change the repository notifies about (new/updated
/// user, etc.) rebuilds the screens that called [ManagerScope.of] - e.g. the
/// Manage Users list updates live instead of only after a manual navigation.
class ManagerScope extends InheritedNotifier<ManagerRepository> {
  const ManagerScope({
    super.key,
    required ManagerRepository repository,
    required this.authProvider,
    required super.child,
  }) : super(notifier: repository);

  final AuthProvider authProvider;

  ManagerRepository get repository => notifier!;

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
}
