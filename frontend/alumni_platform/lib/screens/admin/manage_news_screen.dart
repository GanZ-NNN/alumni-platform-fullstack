import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; 
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';

class ManageNewsScreen extends StatefulWidget {
  final int adminId;
  const ManageNewsScreen({super.key, required this.adminId});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

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

  // --- 1. ຟັງຊັນແກ້ໄຂໂພສ (Edit Post) - ✅ ຮອງຮັບການແກ້ຮູບ ✅ ---
  void _showEditPostDialog(PostModel post) {
    final titleCtrl = TextEditingController(text: post.title);
    final contentCtrl = TextEditingController(text: post.content);
    String selectedType = post.type;
    
    XFile? pickedFile; 
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Post'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 10),
                  TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                  const SizedBox(height: 20),
                  
                  // ສະແດງຮູບເກົ່າ (ຖ້າມີ)
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty && imageBytes == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(post.imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),

                  // ສ່ວນເລືອກຮູບໃໝ່
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
                        icon: const Icon(Icons.image_search, size: 18),
                        label: const Text('Change Image'),
                      ),
                      const SizedBox(width: 10),
                      if (imageBytes != null) 
                        const Expanded(child: Text('New Image ✅', style: TextStyle(color: Colors.green, fontSize: 12))),
                    ],
                  ),

                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'news', child: Text('News')),
                      DropdownMenuItem(value: 'event', child: Text('Event')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                String finalImageUrl = post.imageUrl ?? '';

                // 🛑 ຖ້າມີການເລືອກຮູບໃໝ່ ໃຫ້ອັບໂຫລດກ່ອນ 🛑
                if (imageBytes != null && pickedFile != null) {
                  final newUrl = await _authService.uploadImage(imageBytes!, pickedFile!.name);
                  if (newUrl != null) finalImageUrl = newUrl;
                }

                final success = await _postService.updatePost(
                  id: post.id,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  type: selectedType,
                  imageUrl: finalImageUrl, 
                );

                if (success) {
                  _fetchPosts();
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Post Updated!'), backgroundColor: Colors.blue));
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. ຟັງຊັນເພີ່ມໂພສໃໝ່ (Add Post) ---
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
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 10),
                  TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                  const SizedBox(height: 20),
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
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text('Pick Image'),
                      ),
                      const SizedBox(width: 10),
                      if (imageBytes != null) 
                        const Expanded(
                          child: Text('Selected ✅', style: TextStyle(color: Colors.green, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'news', child: Text('News')),
                      DropdownMenuItem(value: 'event', child: Text('Event')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                String? uploadedImageUrl;
                if (imageBytes != null && pickedFile != null) {
                  uploadedImageUrl = await _authService.uploadImage(imageBytes!, pickedFile!.name);
                }

                final success = await _postService.createPost(
                  authorId: widget.adminId,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  type: selectedType,
                  imageUrl: uploadedImageUrl ?? '', 
                );

                if (success) {
                  _fetchPosts();
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Post Created!'), backgroundColor: Colors.green));
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
                      backgroundImage: (post.imageUrl != null && post.imageUrl!.isNotEmpty) 
                          ? NetworkImage(post.imageUrl!) 
                          : null,
                      child: (post.imageUrl == null || post.imageUrl!.isEmpty)
                          ? Icon(post.type == 'event' ? Icons.event : Icons.article, color: post.type == 'event' ? Colors.orange : Colors.blue, size: 20)
                          : null,
                    ),
                    title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(post.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(post.createdAt.length > 10 ? post.createdAt.substring(0, 10) : post.createdAt, 
                             style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showEditPostDialog(post),
                          tooltip: 'Edit Post',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            if (await _postService.deletePost(post.id)) _fetchPosts();
                          },
                          tooltip: 'Delete Post',
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