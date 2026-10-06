import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/ebook_service.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../repositories/ebook_repository.dart';
import '../providers/ebook_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'librarian_firestore_repository.dart';
import 'librarian_mock_repository.dart';
import 'librarian_repository.dart';

/// Chooses where Librarian data comes from.
///
/// By default the app uses Firebase (Firestore + Storage), so changes are
/// saved and shared with students. Demo data is only used when the app is
/// started with `flutter run --dart-define=LIBMATE_DEMO_DATA=true`; the
/// Librarian screens then show a "Demo data" banner. A failed Firebase write
/// never falls back to demo data.
class LibrarianDataSource {
  const LibrarianDataSource._();

  static const bool useDemoData = bool.fromEnvironment('LIBMATE_DEMO_DATA');

  static LibrarianRepository create(AuthProvider authProvider) {
    if (useDemoData) return LibrarianMockRepository();
    return LibrarianFirestoreRepository(
      firestore: FirebaseFirestore.instance,
      imageStorage: FirebaseImageStorage(),
      librarianUid: authProvider.user?.uid ?? '',
    );
  }

  /// E-books are always stored in Firebase (`ebooks` + Storage PDFs).
  static EbookProvider createEbooks(AuthProvider authProvider) {
    return EbookProvider(
      EbookRepository(
        service: EbookService(
          firestore: FirebaseFirestore.instance,
          files: FirebaseEbookFileStorage(),
        ),
        librarianUid: authProvider.user?.uid ?? '',
      ),
    );
  }
}
