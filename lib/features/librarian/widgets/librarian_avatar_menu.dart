import 'package:flutter/material.dart';

import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';

/// Librarian's initials avatar. Tapping it opens a small menu with the
/// librarian's details and a Sign out option.
class LibrarianAvatarMenu extends StatelessWidget {
  const LibrarianAvatarMenu({
    super.key,
    required this.name,
    required this.email,
    required this.onSignOut,
    this.links = const [],
  });

  final String name;
  final String email;
  final VoidCallback onSignOut;

  /// Extra menu entries (icon, label, action), e.g. Borrowing or Members.
  final List<(IconData, String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 56),
      onSelected: (value) {
        if (value == 'signOut') {
          onSignOut();
          return;
        }
        for (final (_, label, action) in links) {
          if (label == value) action();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text(email),
          ),
        ),
        if (links.isNotEmpty) const PopupMenuDivider(),
        for (final (icon, label, _) in links)
          PopupMenuItem<String>(
            value: label,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signOut',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 24,
        backgroundColor: LibrarianColors.text,
        child: Text(
          LibrarianFormatters.initials(name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
