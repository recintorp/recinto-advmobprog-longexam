import 'dart:convert';
import 'package:http/http.dart';
import '../constants.dart';
import '../models/comment.dart';

class CommentService {
  Future<List<Comment>> getCommentsByPost(int postId) async {
    final uri = Uri.parse('$host/comments/post/$postId');
    final response = await get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List commentsJson = data['comments'] ?? [];
      return commentsJson.map((c) => Comment.fromJson(c)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }
}