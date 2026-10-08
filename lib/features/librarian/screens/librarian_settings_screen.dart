import 'package:flutter/material.dart';

import '../models/librarian_settings.dart';
import '../providers/librarian_scope.dart';
import '../theme/librarian_theme.dart';
import '../utils/librarian_formatters.dart';
import '../widgets/info_section_card.dart';
import '../widgets/librarian_page.dart';
import '../widgets/librarian_page_header.dart';
import '../widgets/settings_dialogs.dart';
import '../widgets/settings_tile.dart';

/// Settings (layout follows the LibMate Profile design): account details,
/// library preferences, notification switches, appearance and sign out.
///
/// Values are stored in the mock repository for now; LibrarianSettings is a
/// single object so it can later be saved as one Firestore document.
class LibrarianSettingsScreen extends StatelessWidget {
  const LibrarianSettingsScreen({super.key});

  static const String _notConnected = 'Available when accounts are connected.';

  @override
  Widget build(BuildContext context) {
    final scope = LibrarianScope.of(context);
    final repository = scope.repository;

    return ListenableBuilder(
      listenable: Listenable.merge([repository, scope.authProvider]),
      builder: (context, _) {
        final settings = repository.settings;
        final profile = scope.authProvider.profile;
        final name = (profile?.name.isNotEmpty ?? false)
            ? profile!.name
            : 'Librarian';
        final email = profile?.email ?? '-';

        Future<void> save(LibrarianSettings updated) async {
          final result = await repository.updateSettings(updated);
          if (!context.mounted) return;
          _message(
            context,
            result.success ? 'Settings saved.' : result.message!,
          );
        }

        String hour(int h) => '${h.toString().padLeft(2, '0')}:00';

        return LibrarianPage(
          maxWidth: 760,
          children: [
            const LibrarianPageHeader(
              title: 'Settings',
              subtitle: 'Manage your account and preferences.',
            ),
            _ProfileCard(
              name: name,
              email: email,
              onEdit: () => _message(context, _notConnected),
            ),
            SettingsGroup(
              title: 'Account',
              tiles: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: name,
                ),
                SettingsTile(
                  icon: Icons.mail_outline,
                  title: 'Email',
                  subtitle: email,
                ),
                const SettingsTile(
                  icon: Icons.badge_outlined,
                  title: 'Role',
                  subtitle: 'Your access level in LibMate',
                  value: 'Librarian',
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your sign-in password',
                  onTap: () => _message(context, _notConnected),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Library Preferences',
              tiles: [
                SettingsTile(
                  icon: Icons.schedule,
                  iconColor: LibrarianColors.gold,
                  title: 'Opening Hours',
                  subtitle: 'When the library is open',
                  value:
                      '${hour(settings.openingHour)} – ${hour(settings.closingHour)}',
                  onTap: () async {
                    final hours = await showOpeningHoursDialog(
                      context,
                      opening: settings.openingHour,
                      closing: settings.closingHour,
                    );
                    if (hours != null) {
                      await save(
                        settings.copyWith(
                          openingHour: hours.$1,
                          closingHour: hours.$2,
                        ),
                      );
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.library_books_outlined,
                  iconColor: LibrarianColors.gold,
                  title: 'Maximum Borrowing Limit',
                  subtitle: 'Books one member can borrow',
                  value: '${settings.maxBorrowLimit} books',
                  onTap: () async {
                    final value = await showNumberSettingDialog(
                      context,
                      title: 'Maximum borrowing limit',
                      value: settings.maxBorrowLimit,
                      min: 1,
                      max: 20,
                      unit: 'books',
                    );
                    if (value != null)
                      await save(settings.copyWith(maxBorrowLimit: value));
                  },
                ),
                SettingsTile(
                  icon: Icons.event_outlined,
                  iconColor: LibrarianColors.gold,
                  title: 'Default Borrowing Period',
                  subtitle: 'Also used when a loan is renewed',
                  value: '${settings.loanPeriodDays} days',
                  onTap: () async {
                    final value = await showNumberSettingDialog(
                      context,
                      title: 'Default borrowing period',
                      value: settings.loanPeriodDays,
                      min: 1,
                      max: 60,
                      unit: 'days',
                    );
                    if (value != null)
                      await save(settings.copyWith(loanPeriodDays: value));
                  },
                ),
                SettingsTile(
                  icon: Icons.payments_outlined,
                  iconColor: LibrarianColors.gold,
                  title: 'Daily Overdue Fine',
                  subtitle: 'Rupees per day after the due date',
                  value: 'Rs. ${settings.dailyFineRate} / day',
                  onTap: () async {
                    final value = await showNumberSettingDialog(
                      context,
                      title: 'Daily overdue fine',
                      value: settings.dailyFineRate,
                      min: 0,
                      max: 1000,
                      unit: 'Rs. / day',
                    );
                    if (value != null)
                      await save(settings.copyWith(dailyFineRate: value));
                  },
                ),
                SettingsTile(
                  icon: Icons.chair_outlined,
                  iconColor: LibrarianColors.gold,
                  title: 'Seat Booking Duration',
                  subtitle: 'Longest reading-room booking',
                  value: '${settings.seatBookingHours} hours',
                  onTap: () async {
                    final value = await showNumberSettingDialog(
                      context,
                      title: 'Seat booking duration',
                      value: settings.seatBookingHours,
                      min: 1,
                      max: 8,
                      unit: 'hours',
                    );
                    if (value != null)
                      await save(settings.copyWith(seatBookingHours: value));
                  },
                ),
              ],
            ),
            SettingsGroup(
              title: 'Notifications',
              tiles: [
                SettingsTile(
                  icon: Icons.event_note_outlined,
                  title: 'Reservation Notifications',
                  subtitle: 'New and cancelled requests',
                  trailing: Switch(
                    value: settings.reservationNotifications,
                    onChanged: (v) =>
                        save(settings.copyWith(reservationNotifications: v)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.notifications_active_outlined,
                  iconColor: LibrarianColors.unavailable,
                  title: 'Overdue Reminders',
                  subtitle: 'When borrowed books are overdue',
                  trailing: Switch(
                    value: settings.overdueReminders,
                    onChanged: (v) =>
                        save(settings.copyWith(overdueReminders: v)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.menu_book_outlined,
                  iconColor: LibrarianColors.available,
                  title: 'Book Availability',
                  subtitle: 'When a reserved book is back in stock',
                  trailing: Switch(
                    value: settings.availabilityNotifications,
                    onChanged: (v) =>
                        save(settings.copyWith(availabilityNotifications: v)),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Appearance',
              tiles: [
                SettingsTile(
                  icon: repository.darkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  iconColor: LibrarianColors.gold,
                  title: 'Theme',
                  subtitle: repository.darkMode
                      ? 'LibMate dark theme'
                      : 'Default LibMate light theme',
                  value: repository.darkMode ? 'Dark' : 'Light',
                ),
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: LibrarianColors.primary,
                  title: 'Dark Mode',
                  subtitle: 'Use the dark theme on all Librarian screens',
                  // Switches every Librarian screen at once and is saved
                  // to your profile, so it is kept after a restart.
                  trailing: Switch(
                    value: repository.darkMode,
                    onChanged: (on) async {
                      final result = await repository.setDarkMode(on);
                      if (!result.success && context.mounted) {
                        _message(context, result.message!);
                      }
                    },
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Other',
              tiles: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About LibMate',
                  subtitle: 'Version and project information',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'LibMate',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.menu_book,
                      color: LibrarianColors.primary,
                      size: 40,
                    ),
                    children: const [
                      Text(
                        'Library book reservation and reading-room seat booking app. '
                        'IT3060 HCI project.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: scope.authProvider.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
                foregroundColor: LibrarianColors.unavailable,
                side: BorderSide(
                  color: LibrarianColors.unavailable,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _message(BuildContext context, String text) {
    // Replace any message already showing instead of queueing behind it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Avatar, name, role and email with an edit button (Profile design).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      borderColor: LibrarianColors.gold.withValues(alpha: 0.6),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: LibrarianColors.isDark
                  ? LibrarianColors.avatar
                  : LibrarianColors.navy,
              child: Text(
                LibrarianFormatters.initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: LibrarianSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: LibrarianColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Librarian',
                    style: TextStyle(
                      color: LibrarianColors.emphasis,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(color: LibrarianColors.secondaryText),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Edit profile',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
