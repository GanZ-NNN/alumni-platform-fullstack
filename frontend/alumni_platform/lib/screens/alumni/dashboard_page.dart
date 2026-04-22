import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/admin_service.dart';
import '../../services/post_service.dart';
import '../../services/image_helper.dart'; // ✅ Import ImageHelper
import '../auth/login_screen.dart';
import 'notification_list_screen.dart';

class AlumniDashboardPage extends StatefulWidget {
  final UserModel user;
  const AlumniDashboardPage({super.key, required this.user});

  @override
  State<AlumniDashboardPage> createState() => _AlumniDashboardPageState();
}

class _AlumniDashboardPageState extends State<AlumniDashboardPage> {
  final AdminService _adminService = AdminService();
  final PostService _postService = PostService();

  Map<String, dynamic> _stats = {
    'totalAlumni': 0,
    'totalJobs': 0,
    'totalPosts': 0,
  };
  List<dynamic> _majorStats = [];
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final statsData = await _adminService.getDashboardStats();
      final majorsData = await _adminService.getMajorReports();
      final postsData = await _postService.getPosts();

      setState(() {
        if (statsData != null) _stats = statsData;
        _majorStats = majorsData;
        _posts = postsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final events = _posts.where((p) => p.type == 'event').take(3).toList();
    final news = _posts.where((p) => p.type == 'news').take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatGrid(),
              _buildMissionCard(),
              _buildSectionHeader('ພາກວິຊາ', () {}),
              _buildDepartmentGrid(),
              _buildSectionHeader('ກິດຈະກຳທີ່ຈະມາເຖິງ', () {}),
              _buildEventsList(events),
              _buildSectionHeader('ຂ່າວສານລ່າສຸດ', () {}),
              _buildNewsList(news),
              _buildSuccessCard(),
              const SizedBox(height: 50),
            ],
          ),
        ),
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
        children: [
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ສະບາຍດີ, ${widget.user.firstName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                    const Text(
                      'ຄະນະວິທະຍາສາດທຳມະຊາດ',
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
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາ...',
          hintStyle: TextStyle(fontFamily: 'Google Sans'),
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'ສິດເກົ່າທັງໝົດ',
            _stats['totalAlumni'].toString(),
            Icons.people,
            Colors.blue,
          ),
          _buildStatCard(
            'ວຽກທີ່ເປີດຮັບ',
            _stats['totalJobs'].toString(),
            Icons.work,
            Colors.green,
          ),
          _buildStatCard(
            'ກິດຈະກຳ',
            _stats['totalPosts'].toString(),
            Icons.calendar_month,
            Colors.purple,
          ),
          _buildStatCard(
            'ຜົນງານດີເດັ່ນ',
            '89',
            Icons.workspace_premium,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _majorStats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
        ),
        itemBuilder: (context, index) {
          final item = _majorStats[index];
          return _buildDeptCard(
            item['major'],
            '${item['count']} ນັກສຶກສາ',
            Colors.blue,
          );
        },
      ),
    );
  }

  Widget _buildEventsList(List<PostModel> events) {
    if (events.isEmpty)
      return const Center(
        child: Text(
          "ຍັງບໍ່ມີກິດຈະກຳ",
          style: TextStyle(fontFamily: 'Google Sans'),
        ),
      );
    return Column(
      children:
          events
              .map(
                (e) => ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event, color: Colors.blue),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Google Sans',
                    ),
                  ),
                  subtitle: Text(
                    e.createdAt.substring(0, 10),
                    style: const TextStyle(fontFamily: 'Google Sans'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )
              .toList(),
    );
  }

  Widget _buildNewsList(List<PostModel> news) {
    if (news.isEmpty)
      return const Center(
        child: Text(
          "ຍັງບໍ່ມີຂ່າວສານ",
          style: TextStyle(fontFamily: 'Google Sans'),
        ),
      );
    return Column(
      children:
          news
              .map(
                (n) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: ListTile(
                    // ✅ Use ImageHelper.networkImage for News images
                    leading: ImageHelper.networkImage(
                      n.imageUrl,
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                    subtitle: Text(
                      n.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Google Sans',
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text(
              'ເບິ່ງທັງໝົດ',
              style: TextStyle(fontFamily: 'Google Sans'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Google Sans',
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'Google Sans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCard(String name, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Google Sans',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            count,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontFamily: 'Google Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_graph, color: Colors.blue),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ພາລະກິດຂອງພວກເຮົາ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Google Sans',
                  ),
                ),
                Text(
                  'ເຊື່ອມໂຍງນັກສຶກສາເກົ່າ ສ້າງເຄືອຂ່າຍວິຊາຊີບ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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

  Widget _buildSuccessCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A56BE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
          const SizedBox(height: 10),
          const Text(
            'ແບ່ງປັນຄວາມສຳເລັດຂອງທ່ານ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Google Sans',
            ),
          ),
          const Text(
            'ບອກພວກເຮົາກ່ຽວກັບຜົນງານ ແລະ ຄວາມກ້າວໜ້າຂອງທ່ານ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Google Sans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'ອັບເດດໂປຣໄຟລ໌',
              style: TextStyle(fontFamily: 'Google Sans'),
            ),
          ),
        ],
      ),
    );
  }
}
