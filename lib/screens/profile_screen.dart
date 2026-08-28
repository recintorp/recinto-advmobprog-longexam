import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    
    if (mounted) {
      setState(() {
        _fullName = '${prefs.getString('firstName') ?? 'Unknown'} ${prefs.getString('lastName') ?? 'User'}';
        _profileImage = prefs.getString('image') ?? 'https://picsum.photos/200';
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
                    border: Border.all(color: Colors.white, width: 4),
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
                  Icon(Icons.school, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DummyJSON Test API User',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
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
                      icon: const Icon(Icons.edit, color: Colors.black87),
                      label: const Text('Edit Profile', style: TextStyle(color: Colors.black87)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      elevation: 0,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.more_horiz, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const Divider(thickness: 8, color: Color(0xFFE0E0E0)),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  return PostCard(post: _userPosts[index - 1]);
                },
              ),
            ),
    );
  }
}