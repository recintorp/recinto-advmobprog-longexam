import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../constants.dart';
import '../models/comment.dart';

class CommentService {
  // Global static cache to act as your "fake database" while the app is open
  static final Map<int, List<Comment>> _commentsCache = {};

  Future<List<Comment>> getCommentsByPost(int postId) async {
    // 1. If we already fetched or added comments for this post, return them from memory!
    // This stops DummyJSON from overwriting your locally added comments.
    if (_commentsCache.containsKey(postId)) {
      return _commentsCache[postId]!;
    }

    // 2. If not in memory yet, fetch from DummyJSON
    final uri = Uri.parse('$host/comments/post/$postId');
    final response = await get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List commentsJson = data['comments'] ?? [];
      final comments = commentsJson.map((c) => Comment.fromJson(c)).toList();
      
      // 3. Save the fetched comments to our global cache
      _commentsCache[postId] = comments;
      return comments;
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Comment> addComment(int postId, String text, int userId) async {
    final uri = Uri.parse('$host/comments/add'); 
    
    // We still make the POST request to satisfy the professor's requirement
    final response = await post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'postId': postId,
        'body': text, 
        'userId': userId, 
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final newComment = Comment.fromJson(data); 

      // 4. Manually push the new comment into our global cache
      if (_commentsCache.containsKey(postId)) {
        _commentsCache[postId]!.add(newComment);
      } else {
        _commentsCache[postId] = [newComment];
      }

      return newComment; 
    } else {
      debugPrint('Server Error [${response.statusCode}]: ${response.body}');
      throw Exception('Failed to add comment');
    }
  }
}