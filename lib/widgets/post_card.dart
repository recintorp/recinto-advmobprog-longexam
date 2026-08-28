import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes;
  bool _isLiked = false;
  bool _showComments = false;
  bool _isLoadingComments = false;
  List<Comment> _comments = [];
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likes++ : _likes--;
    });
  }

  Future<void> _toggleComments() async {
    setState(() => _showComments = !_showComments);
    
    if (_showComments && _comments.isEmpty) {
      setState(() => _isLoadingComments = true);
      try {
        _comments = await _commentService.getCommentsByPost(widget.post.id);
      } finally {
        if (mounted) setState(() => _isLoadingComments = false);
      }
    }
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add(Comment(
          id: DateTime.now().millisecondsSinceEpoch,
          body: _commentController.text.trim(),
          postId: widget.post.id,
          userId: 0,
          username: 'You',
        ));
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar, Name, Time, Options)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            leading: CircleAvatar(
              backgroundColor: Colors.brown.shade200,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text('User ${widget.post.userId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Row(
              children: [
                const Text('16h • ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Icon(Icons.public, size: 14, color: Colors.grey[600]),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: Colors.grey[700]),
                const SizedBox(width: 16),
                Icon(Icons.close, color: Colors.grey[700]),
              ],
            ),
          ),
          
          // Post Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Text(widget.post.body, style: const TextStyle(fontSize: 15, height: 1.3)),
          ),
          const SizedBox(height: 8),
          
          // Stats Row (Likes count, Comment count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle),
                      child: const Icon(Icons.thumb_up, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('$_likes', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  ],
                ),
                Text(
                  '${_comments.isNotEmpty ? _comments.length : widget.post.dislikes} comments • 14 shares',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          
          // Action Buttons (Like, Comment, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: _isLiked ? Colors.brown : Colors.grey[700]),
                    label: Text('Like', style: TextStyle(color: _isLiked ? Colors.brown : Colors.grey[700], fontWeight: FontWeight.bold)),
                    onPressed: _toggleLike,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700]),
                    label: Text('Comment', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    onPressed: _toggleComments,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    icon: Icon(Icons.reply_outlined, color: Colors.grey[700]), // Share icon
                    label: Text('Share', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          
          // Comments Section
          if (_showComments) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            _isLoadingComments 
                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.brown.shade100,
                              child: const Icon(Icons.person, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_comments[index].username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(_comments[index].body, style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12.0, top: 4.0),
                                    child: Text('2h  Like  Reply', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            // Add Comment Input
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.brown.shade200,
                    backgroundImage: const NetworkImage('https://picsum.photos/200'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a public comment...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.brown),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}