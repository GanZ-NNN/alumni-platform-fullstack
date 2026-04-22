import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel user;
  const SettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // 1. Custom Header
          _buildHeader(context),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 2. Profile Summary Card
                  _buildProfileCard(),
                  const SizedBox(height: 25),

                  // 3. Settings Categories
                  _buildSection('Account', [
                    _buildSettingItem(
                      Icons.person_outline,
                      'Edit Profile',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      Icons.lock_outline,
                      'Change Password',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      Icons.notifications_none,
                      'Notifications',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 20),
                  _buildSection('Preferences', [
                    _buildSettingItem(
                      Icons.language,
                      'Language',
                      trailing: const Text(
                        'English',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 20),
                  _buildSection('Support', [
                    _buildSettingItem(
                      Icons.help_outline,
                      'Help Center',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      Icons.info_outline,
                      'About',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 40),
                  // 4. Logout Button
                  _buildLogoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56BE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Google Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                (user.profileImageUrl != null &&
                        user.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
            child:
                user.profileImageUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Google Sans',
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontFamily: 'Google Sans',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A56BE), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Google Sans',
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Google Sans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
