import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/image_helper.dart';

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
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() async {
    setState(() => _isLoading = true);
    final posts = await _postService.getAdminPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<PostModel> filtered = _selectedType == 'All' 
        ? _posts 
        : _posts.where((p) => p.type.toLowerCase() == _selectedType.toLowerCase()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Header Toolbar ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('News & Events Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
            ElevatedButton.icon(
              onPressed: () {}, // _showAddNewsDialog
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Post New Article', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- 2. Filter Row ---
        Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 12),
            _buildFilterChip('News'),
            const SizedBox(width: 12),
            _buildFilterChip('Event'),
          ],
        ),
        const SizedBox(height: 32),

        // --- 3. Responsive Grid / Detailed Cards ---
        _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
            : filtered.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(60), child: Text('No news items found.', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.blueGrey))))
                : GridView.builder(
                    shrinkWrap: true, // Key to work inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Scroll handled by dashboard parent
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 450,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 32,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final post = filtered[index];
                      return _buildNewsCard(post);
                    },
                  ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedType == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.blueGrey, fontFamily: 'Google Sans')),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedType = label),
      selectedColor: const Color(0xFF1A56BE),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), 
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0))
      ),
    );
  }

  Widget _buildNewsCard(PostModel post) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
            child: ImageHelper.networkImage(post.imageUrl, width: 160, height: 220, fit: BoxFit.cover),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeBadge(post.type),
                  const SizedBox(height: 12),
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Google Sans', color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(post.createdAt.substring(0, 10), style: TextStyle(color: Colors.blueGrey[400], fontSize: 12, fontFamily: 'Google Sans')),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionIcon(Icons.edit_note_rounded, Colors.blue, () {}),
                      const SizedBox(width: 8),
                      _buildActionIcon(Icons.delete_outline_rounded, Colors.red, () async {
                        final ok = await _postService.deletePost(post.id);
                        if (ok) _fetchPosts();
                      }),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    bool isEvent = type.toLowerCase() == 'event';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: isEvent ? Colors.purple[50] : Colors.blue[50], borderRadius: BorderRadius.circular(30)),
      child: Text(type.toUpperCase(), style: TextStyle(color: isEvent ? Colors.purple : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.08), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(10)
      ),
    );
  }
}
