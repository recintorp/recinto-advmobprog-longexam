import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/post_card.dart';

class NewsfeedScreen extends StatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  List<Post> _posts = [];
  Map<int, User> _usersById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final results = await Future.wait([
        _postService.getPosts(),
        _userService.getUsers(),
      ]);
      final posts = results[0] as List<Post>;
      final users = results[1] as List<User>;
      if (mounted) {
        setState(() {
          _posts = posts;
          _usersById = {for (final u in users) u.id: u};
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCreatePostHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown.shade200,
            backgroundImage: const NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                "What's on your mind?",
                style: TextStyle(color: theme.hintColor, fontSize: 16),
              ),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Moppibook',
          style: TextStyle(
            fontFamily: 'Klavika',
            color: theme.appBarTheme.foregroundColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.messenger, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildCreatePostHeader(context);
                  final post = _posts[index - 1];
                  return PostCard(
                    post: post,
                    author: _usersById[post.userId],
                    onCommentAdded: _loadPosts,
                  );
                },
              ),
            ),
    );
  }
}