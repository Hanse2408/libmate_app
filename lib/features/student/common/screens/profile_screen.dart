import '../../book_reservation/screens/borrowed_books_screen.dart';
import '../widgets/student_palette.dart';
import '../../../../core/widgets/libmate_logo.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/student_avatar.dart';
import '../widgets/student_notification_button.dart';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../data/student_library_repository.dart';
import '../widgets/student_bottom_navigation.dart';
import '../../book_reservation/screens/find_books_screen.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.library});

  final StudentLibraryRepository library;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _darkMode => Theme.of(context).brightness == Brightness.dark;
  bool _notificationsEnabled = true;

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardColor => Theme.of(context).colorScheme.surface;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _secondaryTextColor =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _dividerColor => Theme.of(context).dividerColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.library,
      builder: (context, _) => Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeading(),
                      SizedBox(height: 22),
                      _buildUserCard(),
                      SizedBox(height: 20),
                      _buildSectionHeading('Library activity'),
                      SizedBox(height: 10),
                      _buildStatisticsCard(),
                      SizedBox(height: 24),
                      _buildSectionHeading('Preferences'),
                      SizedBox(height: 10),
                      _buildSettingsCard(),
                      SizedBox(height: 20),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildTopHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: Row(
      children: [
        _buildLibMateLogo(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LibMate',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'LEARN · RESERVE · BELONG',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 8.5,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: StudentPalette.of(context).border),
          ),
          child: StudentNotificationButton(
            library: widget.library,
            color: _textColor,
          ),
        ),
      ],
    ),
  );

  Widget _buildLibMateLogo() => const LibMateLogo(size: 36);

  Widget _buildProfileHeading() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MY ACCOUNT',
        style: TextStyle(
          color: _darkMode ? _textColor : const Color(0xFF334155),
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Profile',
        style: TextStyle(
          color: _darkMode ? _textColor : const Color(0xFF172033),
          fontSize: 36,
          height: 1.1,
          letterSpacing: -1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'A little space for everything you.',
        style: TextStyle(
          color: _darkMode ? _secondaryTextColor : const Color(0xFF475569),
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _buildSectionHeading(String title) => Text(
    title,
    style: TextStyle(
      color: _textColor,
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
  );

  Widget _buildUserCard() {
    final student = widget.library.student;
    const white = Colors.white;
    final quiet = white.withValues(alpha: .74);
    final gold = StudentPalette.of(context).gold;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _darkMode
              ? const [Color(0xFF172C4B), Color(0xFF0F1A2C)]
              : const [Color(0xFF1E3A8A), Color(0xFF172554)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _darkMode
              ? StudentPalette.of(context).border
              : const Color(0xFF1E3A8A),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _darkMode ? .18 : .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -48,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: white.withValues(alpha: .06),
                    width: 28,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: -65,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: white.withValues(alpha: .035),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_outlined, color: gold, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'YOUR LIBRARY CARD',
                        style: TextStyle(
                          color: quiet,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profile',
                      onPressed: _editProfile,
                      style: IconButton.styleFrom(
                        backgroundColor: white.withValues(alpha: .09),
                        foregroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: gold.withValues(alpha: .8),
                        width: 1.5,
                      ),
                    ),
                    child: StudentAvatar(
                      name: student.name,
                      photoUrl: student.photoUrl,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: white,
                    fontSize: 23,
                    height: 1.2,
                    letterSpacing: -.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: gold.withValues(alpha: .3)),
                    ),
                    child: Text(
                      'Student ID: ${student.studentId}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: white.withValues(alpha: .12)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.mail_outline_rounded, color: quiet, size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        student.email,
                        style: TextStyle(
                          color: quiet,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (student.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: quiet, size: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          student.phone,
                          style: TextStyle(color: quiet, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePanel({required Widget child, Color? borderColor}) => Material(
    color: _cardColor,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: (borderColor ?? _primaryColor).withValues(
          alpha: _darkMode ? .35 : .22,
        ),
      ),
    ),
    child: child,
  );

  Widget _buildSettingsCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _profilePanel(
        borderColor: StudentPalette.of(context).gold,
        child: _buildDarkModeRow(),
      ),
      const SizedBox(height: 10),
      _profilePanel(
        child: _buildSettingsRow(
          icon: Icons.notifications_none_rounded,
          iconBackground: StudentPalette.of(context).blueTint,
          iconColor: _primaryColor,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          showArrow: true,
          onTap: _openNotifications,
        ),
      ),
      const SizedBox(height: 24),
      _buildSectionHeading('Support & account'),
      const SizedBox(height: 10),
      _profilePanel(
        borderColor: StudentPalette.of(context).gold,
        child: Column(
          children: [
            _buildSettingsRow(
              icon: Icons.tune_rounded,
              iconBackground: StudentPalette.of(context).goldTint,
              iconColor: StudentPalette.of(context).goldText,
              title: 'Settings',
              subtitle: 'Make LibMate work for you',
              showArrow: true,
              onTap: _openSettings,
            ),
            _buildSettingsDivider(),
            _buildSettingsRow(
              icon: Icons.help_outline_rounded,
              iconBackground: StudentPalette.of(context).blueTint,
              iconColor: _primaryColor,
              title: 'Help & Support',
              subtitle: 'We are here to help',
              showArrow: true,
              onTap: _openHelp,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildDarkModeRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      child: Row(
        children: [
          _buildSettingIcon(
            icon: Icons.dark_mode_outlined,
            backgroundColor: StudentPalette.of(context).goldTint,
            iconColor: StudentPalette.of(context).gold,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Choose your preferred appearance',
                  style: TextStyle(color: _secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _darkMode,
            onChanged: (value) {
              AppThemeController.instance.setDarkMode(value);

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Dark mode enabled' : 'Dark mode disabled',
                    ),
                  ),
                );
            },
            activeThumbColor: _primaryColor,
            activeTrackColor: StudentPalette.of(context).blueBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showArrow,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        child: Row(
          children: [
            _buildSettingIcon(
              icon: icon,
              backgroundColor: iconBackground,
              iconColor: iconColor,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(color: _textColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (title == 'Notifications')
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeThumbColor: _primaryColor,
                activeTrackColor: StudentPalette.of(context).blueBorder,
              )
            else if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryTextColor,
                size: 23,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingIcon({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      indent: 65,
      endIndent: 16,
      color: _dividerColor.withValues(alpha: .55),
    );
  }

  Widget _buildStatisticsCard() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _buildStatistic(
          icon: Icons.menu_book_outlined,
          iconColor: _primaryColor,
          label: 'Books borrowed',
          value: '${widget.library.borrowedBooks.length}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BorrowedBooksScreen(library: widget.library),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _buildStatistic(
          icon: Icons.access_time_rounded,
          iconColor: _primaryColor,
          label: 'Member since',
          value: '2023',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _buildStatistic(
          icon: Icons.school_outlined,
          iconColor: StudentPalette.of(context).goldText,
          label: 'Account type',
          value: 'Student',
        ),
      ),
    ],
  );

  Widget _buildStatistic({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(alpha: _darkMode ? .35 : .22),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor,
              fontSize: value == 'Student' ? 16 : 22,
              height: 1.1,
              letterSpacing: -.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLogoutButton() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: StudentPalette.of(context).error,
            backgroundColor: StudentPalette.of(context).errorTint,
            side: BorderSide(
              color: StudentPalette.of(context).error,
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.logout_rounded, size: 20),
              ),
              Text(
                'Log Out',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 14,
            color: _secondaryTextColor,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Your library, within reach.',
              style: TextStyle(color: _secondaryTextColor, fontSize: 11),
            ),
          ),
        ],
      ),
    ],
  );

  Future<void> _editProfile() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditProfileDialog(library: widget.library),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification settings will be connected later.')),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings will be connected later.')),
    );
  }

  void _openHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: StudentPalette.of(context).border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Help & Support',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'For help with reservations, account issues, '
                'or library services, please contact the library.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Signs out with the existing AuthProvider (same as the Librarian). The
  /// router then replaces the Student pages with the Login screen, so Back
  /// cannot return to them.
  Future<void> _signOut() async {
    try {
      await widget.library.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Log Out?',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to log out of LibMate?',
            style: TextStyle(color: _secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _signOut();
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: StudentPalette.of(context).error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return StudentBottomNavigation(
      selectedIndex: 3,
      onHome: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      onSearch: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FindBooksScreen(library: widget.library),
          ),
        );
      },
      onReservations: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MyReservationsScreen(library: widget.library),
          ),
        );
      },
      onProfile: () {
        // Already on Profile.
      },
    );
  }
}
