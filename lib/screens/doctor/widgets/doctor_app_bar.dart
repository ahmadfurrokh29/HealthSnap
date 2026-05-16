import 'package:flutter/material.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';

class DoctorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogout;
  final bool confirmLogout;

  const DoctorAppBar({
    super.key,
    this.title,
    this.showLogout = true,
    this.confirmLogout = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleLogoutPressed(BuildContext context) async {
    if (!confirmLogout) {
      await _logout(context);
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFE53E3E)),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: const HealthsnapLogoTitle(),
      actions: showLogout
          ? [
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFE53E3E)),
                onPressed: () => _handleLogoutPressed(context),
              ),
            ]
          : null,
    );
  }
}
