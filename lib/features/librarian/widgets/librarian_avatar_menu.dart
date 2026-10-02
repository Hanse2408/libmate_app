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
  });

  final String name;
  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 56),
      onSelected: (value) {
        if (value == 'signOut') onSignOut();
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
