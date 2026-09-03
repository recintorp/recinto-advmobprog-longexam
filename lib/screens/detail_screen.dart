import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../services/post_interaction_service.dart';

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

class DetailScreen extends StatefulWidget {
  final Post post;
  final User? author;

  const DetailScreen({super.key, required this.post, this.author});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _likes = 0;
  bool _isLiked = false;
  bool _isLoadingComments = true;
  bool _isSendingComment = false;
  List<Comment> _comments = [];
  final Map<int, int> _commentReactions = {};
  final CommentService _commentService = CommentService();
  final PostInteractionService _interactionService = PostInteractionService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _loadLikeState();
    _loadComments();
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

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentService.getCommentsByPost(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _togglePostLike() async {
    final state = await _interactionService.toggleLike(widget.post.id, widget.post.likes);
    if (mounted) {
      setState(() {
        _isLiked = state.isLiked;
        _likes = state.likes;
      });
    }
  }

  void _setCommentReaction(int commentId, int reaction) {
    setState(() {
      final current = _commentReactions[commentId] ?? 0;
      _commentReactions[commentId] = current == reaction ? 0 : reaction;
    });
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
    } catch (e) {
      debugPrint('Failed to send comment: $e');
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0.5,
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildPostHeader(),
                Divider(height: 1, thickness: 1, color: theme.dividerColor),
                _buildReactionSummary(),
                Container(height: 8, color: theme.scaffoldBackgroundColor),
                if (_isLoadingComments)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('No comments yet', style: TextStyle(color: theme.hintColor)),
                    ),
                  )
                else
                  ..._comments.map(_buildCommentTile),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.brown.shade200,
                backgroundImage: (widget.author?.image.isNotEmpty ?? false)
                    ? NetworkImage(widget.author!.image)
                    : null,
                child: (widget.author?.image.isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.author != null
                          ? '${widget.author!.firstName} ${widget.author!.lastName}'
                          : 'User ${widget.post.userId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Text('16h • ', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        Icon(Icons.public, size: 14, color: theme.iconTheme.color),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: theme.iconTheme.color),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.post.body, style: const TextStyle(fontSize: 16, height: 1.35)),
        ],
      ),
    );
  }

  Widget _buildReactionSummary() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _togglePostLike,
            child: Row(
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
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                          ),
                          child: const Icon(Icons.favorite, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCount(_likes),
                  style: TextStyle(
                    color: _isLiked ? Colors.brown : theme.hintColor,
                    fontSize: 14,
                    fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatCount(_comments.length)} comments • 14 shares',
            style: TextStyle(color: theme.hintColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final reaction = _commentReactions[comment.id] ?? 0;
    final displayName = comment.name.isNotEmpty ? comment.name : comment.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0, right: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('1d', style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Text('Reply', style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _setCommentReaction(comment.id, 1),
                            child: Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 16,
                              color: reaction == 1 ? Colors.brown : theme.iconTheme.color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => _setCommentReaction(comment.id, -1),
                            child: Icon(
                              Icons.thumb_down_alt_outlined,
                              size: 16,
                              color: reaction == -1 ? Colors.brown : theme.iconTheme.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.brown.shade200,
            backgroundImage: const NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
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
            icon: Icon(Icons.camera_alt_outlined, color: theme.iconTheme.color),
            onPressed: () {},
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
    );
  }
}