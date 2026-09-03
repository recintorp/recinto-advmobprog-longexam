import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PostService _postService = PostService();
  List<Post> _userPosts = [];
  bool _isLoading = true;
  String _fullName = '';
  String _profileImage = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final firstName = prefs.getString('firstName') ?? 'Unknown';
    final lastName = prefs.getString('lastName') ?? 'User';
    final image = prefs.getString('image') ?? 'https://picsum.photos/200';

    if (mounted) {
      setState(() {
        _fullName = '$firstName $lastName';
        _profileImage = image;
        // Built from stored login data so PostCard can show the real
        // name/avatar for this user's own posts instead of falling
        // back to "User {id}" (username/email aren't persisted at
        // login, so they're left blank -- PostCard doesn't use them).
        _currentUser = User(
          id: userId,
          username: '',
          email: '',
          firstName: firstName,
          lastName: lastName,
          image: image,
          token: prefs.getString('token') ?? '',
        );
      });
    }

    if (userId != 0) {
      try {
        final posts = await _postService.getPostsByUser(userId);
        if (mounted) setState(() => _userPosts = posts);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final neutralBg = isDark ? Colors.grey[800] : Colors.grey[300];
    final neutralFg = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.brown.shade200,
                  image: const DecorationImage(
                    image: NetworkImage('https://picsum.photos/800/400'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 140,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.brown.shade100,
                    backgroundImage: NetworkImage(_profileImage),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, color: theme.iconTheme.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DummyJSON Test API User',
                      style: TextStyle(fontSize: 16, color: theme.hintColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add to Story', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.edit, color: neutralFg),
                      label: Text('Edit Profile', style: TextStyle(color: neutralFg)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neutralBg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neutralBg,
                      elevation: 0,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Icon(Icons.more_horiz, color: neutralFg),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Divider(thickness: 8, color: theme.scaffoldBackgroundColor),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView.builder(
                itemCount: _userPosts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildProfileHeader();
                  }
                  return PostCard(
                    post: _userPosts[index - 1],
                    author: _currentUser,
                  );
                },
              ),
            ),
    );
  }
}