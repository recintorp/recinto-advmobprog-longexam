import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../services/post_interaction_service.dart';
import '../screens/detail_screen.dart';

String _formatCount(int count) {
  if (count >= 1000000) {
    final value = count / 1000000;
    return '${value.toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
  }
  if (count >= 1000) {
    final value = count / 1000;
    return '${value.toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
  }
  return '$count';
}

class PostCard extends StatefulWidget {
  final Post post;
  final User? author;
  final VoidCallback? onCommentAdded;

  const PostCard({super.key, required this.post, this.author, this.onCommentAdded});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _likes = 0;
  bool _isLiked = false;
  bool _showComments = false;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  List<Comment> _comments = [];
  final CommentService _commentService = CommentService();
  final PostInteractionService _interactionService = PostInteractionService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _loadLikeState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeState() async {
    final state = await _interactionService.getLikeState(widget.post.id, widget.post.likes);
    if (mounted) {
      setState(() {
        _isLiked = state.isLiked;
        _likes = state.likes;
      });
    }
  }

  Future<void> _toggleLike() async {
    final state = await _interactionService.toggleLike(widget.post.id, widget.post.likes);
    if (mounted) {
      setState(() {
        _isLiked = state.isLiked;
        _likes = state.likes;
      });
    }
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

  Future<void> _addComment() async {
    if (_isSendingComment) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');

      if (currentUserId == null) {
        debugPrint('Error: No active user session found.');
        return;
      }

      final newComment = await _commentService.addComment(
        widget.post.id,
        text,
        currentUserId,
      );

      if (!mounted) return;
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      widget.onCommentAdded?.call();
    } catch (e) {
      debugPrint('Failed to send comment: $e');
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _openDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(post: widget.post, author: widget.author),
      ),
    );

    if (!mounted) return;

    try {
      final comments = await _commentService.getCommentsByPost(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } catch (e) {
      debugPrint('Failed to refresh comments: $e');
    }

    await _loadLikeState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = theme.hintColor;
    final iconColor = theme.iconTheme.color;
    final surfaceColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            leading: CircleAvatar(
              backgroundColor: Colors.brown.shade200,
              backgroundImage: (widget.author?.image.isNotEmpty ?? false)
                  ? NetworkImage(widget.author!.image)
                  : null,
              child: (widget.author?.image.isNotEmpty ?? false)
                  ? null
                  : const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              widget.author != null
                  ? '${widget.author!.firstName} ${widget.author!.lastName}'
                  : 'User ${widget.post.userId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Row(
              children: [
                Text('16h • ', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                Icon(Icons.public, size: 14, color: iconColor),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: iconColor),
                const SizedBox(width: 16),
                Icon(Icons.close, color: iconColor),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openDetail,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Text(widget.post.body, style: const TextStyle(fontSize: 15, height: 1.3)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 34,
                      height: 20,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.thumb_up, size: 12, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.cardColor, width: 1.5),
                              ),
                              child: const Icon(Icons.favorite, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_formatCount(_likes), style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  ],
                ),
                GestureDetector(
                  onTap: _openDetail,
                  child: Text(
                    '${_formatCount(_comments.isNotEmpty ? _comments.length : widget.post.dislikes)} comments • 14 shares',
                    style: TextStyle(color: secondaryTextColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: iconColor),
                    icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: _isLiked ? Colors.brown : iconColor),
                    label: Text('Like', style: TextStyle(color: _isLiked ? Colors.brown : iconColor, fontWeight: FontWeight.bold)),
                    onPressed: _toggleLike,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: iconColor),
                    icon: Icon(Icons.chat_bubble_outline, color: iconColor),
                    label: Text('Comment', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                    onPressed: _toggleComments,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: iconColor),
                    icon: Icon(Icons.reply_outlined, color: iconColor),
                    label: Text('Share', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          if (_showComments) ...[
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            _isLoadingComments
                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final displayName = comment.name.isNotEmpty ? comment.name : comment.username;
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
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(comment.body, style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                                    child: Text('Just now  Like  Reply', style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSendingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.brown),
                    onPressed: _isSendingComment ? null : _addComment,
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