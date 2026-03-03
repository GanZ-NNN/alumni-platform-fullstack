import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // ສໍາລັບຈັດການ bytes ຂອງຮູບໃນ Web
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class ManageNewsScreen extends StatefulWidget {
  final int adminId;
  const ManageNewsScreen({super.key, required this.adminId});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  // ✅ Scroll Controllers ສໍາລັບ Web
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  void _fetchPosts() async {
    setState(() => _isLoading = true);
    final data = await _postService.getAdminPosts();
    if (mounted) {
      setState(() {
        _posts = data;
        _isLoading = false;
      });
    }
  }

  void _showAddPostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = 'news';
    XFile? pickedFile;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                const SizedBox(height: 15),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setDialogState(() {
                            pickedFile = picked;
                            imageBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(width: 10),
                    if (imageBytes != null) const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'news', child: Text('News')),
                    DropdownMenuItem(value: 'event', child: Text('Event')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final success = await _postService.createPost(
                  authorId: widget.adminId,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  type: selectedType,
                  // ສົ່ງ imageBytes ໄປ (ຖ້າມີ)
                );
                if (success) {
                  _fetchPosts();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('News & Events Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddPostDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Post'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _verticalController,
                itemCount: _posts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: post.type == 'event' ? Colors.orange[100] : Colors.blue[100],
                      child: Icon(post.type == 'event' ? Icons.event : Icons.article, color: post.type == 'event' ? Colors.orange : Colors.blue, size: 20),
                    ),
                    title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(post.createdAt.substring(0, 10), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            if (await _postService.deletePost(post.id)) _fetchPosts();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}