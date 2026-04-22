import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/image_helper.dart';
import '../auth/login_screen.dart';
import 'notification_list_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final UserService _userService = UserService();
  List<UserModel> _alumniList = [];
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();
  String _selectedMajor = 'ທັງໝົດ';
  String _selectedYear = 'ທຸກປີ';

  // Sample data for filters (You can fetch these from backend if needed)
  final List<String> _majors = [
    'ທັງໝົດ',
    'Computer Science',
    'Mathematics',
    'Biology',
    'Chemistry',
    'Physics',
  ];
  final List<String> _years = [
    'ທຸກປີ',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  void _fetchAlumni() async {
    setState(() => _isLoading = true);

    // Convert 'ທັງໝົດ'/'ທຸກປີ' to empty string for backend filter
    final major = _selectedMajor == 'ທັງໝົດ' ? '' : _selectedMajor;
    final year = _selectedYear == 'ທຸກປີ' ? '' : _selectedYear;

    final data = await _userService.searchAlumni(
      name: _searchCtrl.text.trim(),
      major: major,
      year: year,
    );

    setState(() {
      _alumniList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),

          // --- Result Counter ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                const Text(
                  'ພົບ ',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 15),
                ),
                Text(
                  '${_alumniList.length}',
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A56BE),
                  ),
                ),
                const Text(
                  ' ຜົນໄດ້ຮັບ',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 15),
                ),
              ],
            ),
          ),

          // --- List Area ---
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: _alumniList.length,
                      itemBuilder: (context, index) {
                        final user = _alumniList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey[100]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: ImageHelper.networkImage(
                                    user.profileImageUrl,
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              '${user.firstName} ${user.lastName ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.major} • ລຸ້ນ ${user.graduationYear}',
                                  style: const TextStyle(
                                    fontFamily: 'Google Sans',
                                  ),
                                ),
                                Text(
                                  user.jobPosition ?? 'Alumni',
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 12,
                                    fontFamily: 'Google Sans',
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF1A56BE),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56BE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 20),

          // --- Search Bar ---
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => _fetchAlumni(), // Trigger on every keystroke
            decoration: InputDecoration(
              hintText: 'ຄົ້ນຫາຊື່, ພາກວິຊາ...',
              hintStyle: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- Filter Row ---
          Row(
            children: [
              Expanded(
                child: _buildDropdown('Major', _majors, _selectedMajor, (val) {
                  setState(() => _selectedMajor = val!);
                  _fetchAlumni();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('Year', _years, _selectedYear, (val) {
                  setState(() => _selectedYear = val!);
                  _fetchAlumni();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            'FNS',
            style: TextStyle(
              color: Color(0xFF1A56BE),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ບັນຊີສິດເກົ່າ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Google Sans',
                ),
              ),
              Text(
                'ຄົ້ນຫາ ແລະ ເຊື່ອມຕໍ່',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Google Sans',
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 28,
          ),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationListScreen(),
                ),
              ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.black87,
            fontSize: 13,
          ),
          onChanged: onChanged,
          items:
              items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }
}
