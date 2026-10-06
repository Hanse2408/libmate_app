import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:libmate_app/app/routes/librarian_routes.dart';
import 'package:libmate_app/core/services/auth_service.dart';
import 'package:libmate_app/core/services/ebook_service.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/core/services/cloudinary_upload_service.dart';
import 'package:libmate_app/core/services/user_service.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/features/librarian/data/librarian_mock_repository.dart';
import 'package:libmate_app/features/librarian/data/librarian_repository.dart';
import 'package:libmate_app/features/librarian/providers/ebook_provider.dart';
import 'package:libmate_app/features/librarian/providers/librarian_scope.dart';
import 'package:libmate_app/repositories/auth_repository.dart';
import 'package:libmate_app/repositories/ebook_repository.dart';
import 'package:libmate_app/repositories/user_repository.dart';

/// Stand-ins so AuthProvider can be built without initialising Firebase.
class _FakeAuthService implements AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthProvider buildFakeAuthProvider() {
  return AuthProvider(
    authRepository: AuthRepository(authService: _FakeAuthService()),
    userRepository: UserRepository(userService: _FakeUserService()),
  );
}

/// Keeps e-book PDFs in memory instead of uploading to Cloudinary.
class FakePdfStorage implements EbookFileStorage {
  final Map<String, Uint8List> files = {};
  var _nextId = 0;

  /// When set, uploads throw this message.
  String? failWith;

  @override
  Future<CloudMediaAsset> upload(
    PdfFile pdf, {
    void Function(double progress)? onProgress,
  }) async {
    if (failWith != null) throw ImageStorageException(failWith!);
    final publicId = 'ebooks/test-${_nextId++}';
    files[publicId] = pdf.bytes;
    onProgress?.call(1);
    return CloudMediaAsset(
      secureUrl: 'https://res.cloudinary.com/test/image/upload/$publicId.pdf',
      publicId: publicId,
      resourceType: 'image',
      format: 'pdf',
      sizeBytes: pdf.sizeBytes,
      fileName: pdf.fileName,
    );
  }
}

/// E-book state on an in-memory Firestore (no Firebase needed).
EbookProvider buildFakeEbookProvider({
  FakeFirebaseFirestore? firestore,
  FakePdfStorage? files,
  ImageStorage? images,
}) {
  return EbookProvider(
    EbookRepository(
      service: EbookService(
        firestore: firestore ?? FakeFirebaseFirestore(),
        files: files ?? FakePdfStorage(),
        images: images,
      ),
      librarianUid: 'librarian-1',
    ),
  );
}

/// A router containing only the Librarian area, starting at [initialLocation].
/// Uses the in-memory sample data unless [createRepository] is given.
GoRouter buildLibrarianRouter(
  String initialLocation, {
  LibrarianRepository Function()? createRepository,
  EbookProvider Function()? createEbooks,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      LibrarianRoutes.shellRoute(
        buildFakeAuthProvider(),
        createRepository: createRepository ?? LibrarianMockRepository.new,
        createEbooks: createEbooks ?? buildFakeEbookProvider,
      ),
    ],
  );
}

/// Opens the Librarian area at [location] on a screen of [size].
Future<GoRouter> pumpLibrarian(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 900),
  LibrarianRepository Function()? createRepository,
  EbookProvider Function()? createEbooks,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = buildLibrarianRouter(
    location,
    createRepository: createRepository,
    createEbooks: createEbooks,
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

/// The live repository used by the pumped Librarian screens.
LibrarianRepository repositoryOf(WidgetTester tester) {
  return LibrarianScope.read(tester.element(find.byType(NavigationBar)))
      .repository;
}

/// Scrolls the page (up or down) until [finder] is on screen and tappable.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.hitTestable().evaluate().isEmpty; i++) {
    if (finder.evaluate().isNotEmpty) {
      // Already built (above or below the screen): bring it into view.
      await tester.ensureVisible(finder.first);
    } else {
      // Not built yet by the lazy list: scroll further down.
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    }
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsWidgets);
}

/// Scrolls to [finder] and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder.hitTestable().first);
  await tester.pumpAndSettle();
}

extension CurrentPath on GoRouter {
  String get currentPath => routerDelegate.currentConfiguration.uri.path;
}
