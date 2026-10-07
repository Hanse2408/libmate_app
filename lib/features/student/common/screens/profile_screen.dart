import '../widgets/student_palette.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../data/student_library_repository.dart';
import '../widgets/student_bottom_navigation.dart';
import '../../book_reservation/screens/find_books_screen.dart';
import '../../book_reservation/screens/my_reservations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.library,
  });

  final StudentLibraryRepository library;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeading(),
                    SizedBox(height: 18),
                    _buildUserCard(),
                    SizedBox(height: 20),
                    _buildSettingsCard(),
                    SizedBox(height: 20),
                    _buildStatisticsCard(),
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
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 18, 20, 8),
      child: Row(
        children: [
          Row(
            children: [
              _buildLibMateLogo(),
              SizedBox(width: 8),
              Text(
                'LibMate',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _textColor,
                size: 25,
              ),
              Positioned(
                right: -5,
                top: -7,
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudentPalette.of(context).error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              'ND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibMateLogo() {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 1,
            top: 5,
            child: Container(
              width: 12,
              height: 21,
              decoration: BoxDecoration(
                color: StudentPalette.of(context).primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            top: 5,
            child: Container(
              width: 12,
              height: 21,
              decoration: BoxDecoration(
                color: StudentPalette.of(context).primary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 5,
            child: Container(
              width: 2,
              height: 21,
              color: StudentPalette.of(context).gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Manage your account and preferences.',
          style: TextStyle(
            color: _textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(15, 17, 15, 17),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: StudentPalette.of(context).gold,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudentPalette.of(context).primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nilumi Dakshika',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Student ID: IT23514658',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'it23514658@my.sliit.lk',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: StudentPalette.of(context).blueTint,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _editProfile,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.edit_outlined,
                color: _primaryColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: StudentPalette.of(context).gold,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          _buildDarkModeRow(),
          _buildSettingsDivider(),
          _buildSettingsRow(
            icon: Icons.notifications_none_rounded,
            iconBackground: StudentPalette.of(context).blueTint,
            iconColor: _primaryColor,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            showArrow: true,
            onTap: _openNotifications,
          ),
          _buildSettingsDivider(),
          _buildSettingsRow(
            icon: Icons.tune_rounded,
            iconBackground: StudentPalette.of(context).goldTint,
            iconColor: StudentPalette.of(context).gold,
            title: 'Settings',
            subtitle: 'Update your preferences',
            showArrow: true,
            onTap: _openSettings,
          ),
          _buildSettingsDivider(),
          _buildSettingsRow(
            icon: Icons.help_outline_rounded,
            iconBackground: StudentPalette.of(context).blueTint,
            iconColor: _primaryColor,
            title: 'Help & Support',
            subtitle: 'Get help or contact us',
            showArrow: true,
            onTap: _openHelp,
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeRow() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
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
                  'Switch between light and dark theme',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              AppThemeController.instance.setDarkMode(value);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Dark Mode enabled'
                        : 'Dark Mode disabled',
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
        padding: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
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
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 10,
                    ),
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
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 18,
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      color: _dividerColor,
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StudentPalette.of(context).blueBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatistic(
              icon: Icons.menu_book_outlined,
              iconColor: StudentPalette.of(context).primary,
              label: 'Books borrowed',
              value: '2',
            ),
          ),
          _buildStatisticDivider(),
          Expanded(
            child: _buildStatistic(
              icon: Icons.access_time_rounded,
              iconColor: StudentPalette.of(context).primary,
              label: 'Member since',
              value: '2023',
            ),
          ),
          _buildStatisticDivider(),
          Expanded(
            child: _buildStatistic(
              icon: Icons.star_border_rounded,
              iconColor: StudentPalette.of(context).primary,
              label: 'Account type',
              value: 'Student',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 21,
        ),
        SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 11,
          ),
        ),
        SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticDivider() {
    return Container(
      width: 1,
      height: 38,
      color: _dividerColor,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: Icon(
          Icons.logout_rounded,
          size: 19,
        ),
        label: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: StudentPalette.of(context).error,
          backgroundColor: _cardColor,
          side: BorderSide(
            color: StudentPalette.of(context).error,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit Profile will be connected later.',
        ),
      ),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification settings will be connected later.',
        ),
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settings will be connected later.',
        ),
      ),
    );
  }

  void _openHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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
          title:           Text(
            'Log Out?',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content:           Text(
            'Are you sure you want to log out of LibMate?',
            style: TextStyle(
              color: _secondaryTextColor,
            ),
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