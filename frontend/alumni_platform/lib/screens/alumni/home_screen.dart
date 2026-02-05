// lib/screens/alumni/home_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'directory_screen.dart';
import 'jobs_screen.dart'; // ✅ 1. Import ໜ້າ Jobs

class AlumniHomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const AlumniHomeScreen({super.key, required this.currentUser});

  @override
  State<AlumniHomeScreen> createState() => _AlumniHomeScreenState();
}

class _AlumniHomeScreenState extends State<AlumniHomeScreen> {
  int _currentIndex = 0;
  
  late UserModel _displayUser;
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser;
    _fetchPosts();
  }

  void _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    final data = await _postService.getPosts();
    setState(() {
      _posts = data;
      _isLoadingPosts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    // ລາຍຊື່ໜ້າຈໍທັງໝົດ (4 ໜ້າ)
    final List<Widget> pages = [
      // [0] ໜ້າ News Feed
      RefreshIndicator(
        onRefresh: () async => _fetchPosts(), 
        child: _isLoadingPosts
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 300, child: Center(child: Text("ຍັງບໍ່ມີຂ່າວສານໃນຕອນນີ້"))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: post.type == 'event' ? Colors.orange : Colors.blue,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4), 
                                  bottomRight: Radius.circular(10)
                                ),
                              ),
                              child: Text(
                                post.type.toUpperCase(), 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 5),
                                  Text(post.content, style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Post Date: ${post.createdAt.length > 10 ? post.createdAt.substring(0, 10) : post.createdAt}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),

      // [1] ໜ້າ Directory
      const DirectoryScreen(),

      // [2] ໜ້າ Jobs (Career Hub) ✅ ເພີ່ມໃໝ່
      JobsScreen(currentUser: _displayUser),

      // [3] ໜ້າ Profile
      ProfileScreen(
        user: _displayUser,
        onUserUpdated: (updatedUser) {
          setState(() {
            _displayUser = updatedUser;
          });
        },
      ),
    ];

    // ຊື່ Title ຕາມ Index
    final List<String> titles = ['Alumni Feed', 'Directory', 'Career Hub', 'My Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]), // ປ່ຽນ Title ຕາມໜ້າ
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      
      body: pages[_currentIndex], 

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // ✅ ສຳຄັນ! ຕ້ອງໃສ່ເມື່ອມີ 4 ປຸ່ມຂຶ້ນໄປ
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Directory'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'), // ✅ ປຸ່ມໃໝ່
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}