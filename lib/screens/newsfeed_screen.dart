import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

class NewsfeedScreen extends StatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _postService.getPosts();
      if (mounted) setState(() => _posts = posts);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCreatePostHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown.shade200,
            backgroundImage: const NetworkImage('https://picsum.photos/200'), // Authenticated user placeholder
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('What\'s on your mind?', style: TextStyle(color: Colors.black54, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.photo_library, color: Colors.green),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // FB thick grey dividers between cards
      appBar: AppBar(
        title: const Text(
          'Moppibook',
          style: TextStyle(
            fontFamily: 'Klavika',
            color: Colors.brown,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.messenger, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildCreatePostHeader();
                return PostCard(post: _posts[index - 1]);
              },
            ),
    );
  }
}