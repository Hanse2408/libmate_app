import '../data/librarian_mock_repository.dart';
import '../models/member_record.dart';

enum MemberFilterOption {
  all('All'),
  active('Active'),
  suspended('Suspended'),
  overdue('Has Overdue');

  const MemberFilterOption(this.label);
  final String label;
}

/// Search text + status filter on the Member Management screen.
class MemberFilter {
  const MemberFilter({this.query = '', this.option = MemberFilterOption.all});

  final String query;
  final MemberFilterOption option;

  List<MemberRecord> apply(LibrarianMockRepository repository) {
    final text = query.trim().toLowerCase();
    return repository.members.where((member) {
      final optionOk = switch (option) {
        MemberFilterOption.all => true,
        MemberFilterOption.active => member.isActive,
        MemberFilterOption.suspended => !member.isActive,
        MemberFilterOption.overdue => repository.overdueLoanCount(member.id) > 0,
      };
      if (!optionOk) return false;
      if (text.isEmpty) return true;
      return member.name.toLowerCase().contains(text) ||
          member.id.toLowerCase().contains(text) ||
          member.email.toLowerCase().contains(text);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
