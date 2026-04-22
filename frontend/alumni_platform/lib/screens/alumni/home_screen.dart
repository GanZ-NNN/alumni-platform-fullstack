import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'profile_screen.dart';
import 'directory_screen.dart';
import 'jobs_screen.dart';
import 'dashboard_page.dart';

class AlumniHomeScreen extends StatefulWidget {
  final UserModel currentUser;
  const AlumniHomeScreen({super.key, required this.currentUser});

  @override
  State<AlumniHomeScreen> createState() => _AlumniHomeScreenState();
}

class _AlumniHomeScreenState extends State<AlumniHomeScreen> {
  int _currentIndex = 0;
  late UserModel _displayUser;

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AlumniDashboardPage(user: _displayUser),
      const DirectoryScreen(),
      JobsScreen(currentUser: _displayUser),
      ProfileScreen(
        user: _displayUser,
        onUserUpdated: (u) => setState(() => _displayUser = u),
      ),
    ];

    return Scaffold(
      // 🛑 Removed the conditional AppBar entirely to fix the "double header" issue 🛑
      // Each page (Dashboard, Directory, Jobs, Profile) now handles its own header area.
      appBar: null,
      body: pages[_currentIndex],

      // ✅ Custom Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Stack(
            children: [
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF1A56BE),
                unselectedItemColor: Colors.grey[400],
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 12,
                ),
                items: [
                  _buildNavItem(Icons.home_outlined, Icons.home, 'ໜ້າຫຼັກ', 0),
                  _buildNavItem(
                    Icons.people_outline,
                    Icons.people,
                    'ບັນຊີລາຍຊື່',
                    1,
                  ),
                  _buildNavItem(Icons.work_outline, Icons.work, 'ວຽກງານ', 2),
                  _buildNavItem(
                    Icons.person_outline,
                    Icons.person,
                    'ໂປຣໄຟລ໌',
                    3,
                  ),
                ],
              ),

              // Blue Indicator Line
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left:
                    (MediaQuery.of(context).size.width / 4) * _currentIndex +
                    (MediaQuery.of(context).size.width / 8) -
                    25,
                top: 0,
                child: Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56BE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Icon(icon),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
}
