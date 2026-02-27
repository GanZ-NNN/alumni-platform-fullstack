import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class ManageNewsScreen extends StatefulWidget {
  final int adminId; // ຮັບ ID ຂອງ Admin ມາເພື່ອໃຊ້ເປັນ authorId
  const ManageNewsScreen({super.key, required this.adminId});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() async {
    final data = await _postService.getAdminPosts();
    setState(() {
      _posts = data;
      _isLoading = false;
    });
  }

  // ແບບຟອມເພີ່ມຂ່າວ
  void _showAddPostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = 'news';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
                      if (picked != null) {
                        selectedImage = File(picked.path);
                        setDialogState(() {});
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Pick Image'),
                  ),
                  const SizedBox(width: 8),
                  if (selectedImage != null) const Text('Image selected')
                ],
              ),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'news', child: Text('News')),
                  DropdownMenuItem(value: 'event', child: Text('Event')),
                ],
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                // 1. ดึง Navigator มารอก่อนจะทำการ await
                final navigator = Navigator.of(context);
                
                final success = await _postService.createPost(
                  authorId: widget.adminId,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                      type: selectedType,
                      imageFile: selectedImage,
                );

                // 2. เช็ค mounted เพื่อยืนยันว่า Widget ยังทำงานอยู่ก่อนสั่ง _fetchPosts
                if (!mounted) return;

                if (success) {
                  _fetchPosts();
                  // 3. ใช้ตัวแปร navigator ที่ดึงมาแทนการใช้ context ตรงๆ
                  navigator.pop();
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage News & Events')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return ListTile(
                  leading: Icon(post.type == 'news' ? Icons.article : Icons.event),
                  title: Text(post.title),
                  subtitle: Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      if (await _postService.deletePost(post.id)) _fetchPosts();
                    },
                  ),
                );
              },
            ),
    );
  }
}