import 'package:flutter/material.dart';

import '../models/member_record.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import 'librarian_accent_card.dart';
import 'status_chip.dart';

/// One member row: initials, name, ID, email, loan / reservation counts and
/// account status. Members with overdue books get a red outline.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.loanCount,
    required this.reservationCount,
    required this.overdueCount,
    required this.onTap,
  });

  final MemberRecord member;
  final int loanCount;
  final int reservationCount;
  final int overdueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = overdueCount > 0
        ? LibrarianColors.unavailable
        : member.isActive
        ? LibrarianColors.primary
        : LibrarianColors.secondaryText;

    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

    return LibrarianAccentCard(
      accentColor: accent,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: LibrarianColors.text,
            child: Text(
              LibrarianFormatters.initials(member.name),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: LibrarianSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${member.id} · ${member.email}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: LibrarianColors.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${plural(loanCount, 'book')} borrowed · '
                  '${plural(reservationCount, 'reservation')}'
                  '${overdueCount > 0 ? ' · $overdueCount overdue' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    color: overdueCount > 0 ? LibrarianColors.unavailable : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LibrarianSpacing.sm),
          StatusChip.member(member.status),
        ],
      ),
    );
  }
}
