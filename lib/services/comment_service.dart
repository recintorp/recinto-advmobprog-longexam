import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/comment.dart';

class CommentService {
  static final Map<int, List<Comment>> _commentsCache = {};

  Future<List<Comment>> getCommentsByPost(int postId) async {
    if (_commentsCache.containsKey(postId)) {
      // Return a COPY. Callers must never get a live reference to the
      // cache's internal list, or mutating their own widget state
      // (e.g. _comments.add(...)) silently mutates the cache too and
      // vice versa -- that aliasing is what caused comments to double.
      return List<Comment>.from(_commentsCache[postId]!);
    }

    final uri = Uri.parse('$host/comments/post/$postId');
    final response = await get(uri, headers: {'Content-Type': 'application/json'});

    List<Comment> comments;
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List commentsJson = data['comments'] ?? [];
      comments = commentsJson.map((c) => Comment.fromJson(c)).toList();
    } else {
      throw Exception('Failed to load comments');
    }

    // Re-apply anything added locally that survived a hot restart. Safe to
    // dedupe on `id` here because addComment() now always assigns locally-
    // added comments a negative, timestamp-based id -- see the comment
    // there for why that's necessary.
    final local = await _loadLocalComments(postId);
    for (final c in local) {
      if (!comments.any((existing) => existing.id == c.id)) {
        comments.add(c);
      }
    }

    _commentsCache[postId] = comments;
    return List<Comment>.from(comments);
  }

  Future<Comment> addComment(int postId, String text, int userId) async {
    final uri = Uri.parse('$host/comments/add');
    final response = await post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'postId': postId, 'body': text, 'userId': userId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final serverComment = Comment.fromJson(data);

      // DummyJSON's mock /comments/add doesn't hydrate the nested user's
      // name, so build the display name from the logged-in user instead.
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('firstName') ?? '';
      final lastName = prefs.getString('lastName') ?? '';
      final displayName = '$firstName $lastName'.trim();

      // DummyJSON's mock endpoint doesn't actually persist anything, so
      // the `id` it echoes back isn't guaranteed unique between calls --
      // two different comments can come back with the same id. That
      // collided id was silently sinking the second comment to be added
      // during the getCommentsByPost merge step above (which dedupes by
      // id) any time the app was restarted. Assigning our own unique,
      // negative, timestamp-based id instead means it can never collide
      // with another local comment or with a real (always positive)
      // server-seeded comment id.
      final localId = -DateTime.now().microsecondsSinceEpoch;

      final newComment = Comment(
        id: localId,
        body: serverComment.body.isNotEmpty ? serverComment.body : text,
        postId: postId,
        userId: userId,
        username: serverComment.username,
        name: displayName.isNotEmpty ? displayName : serverComment.name,
      );

      if (_commentsCache.containsKey(postId)) {
        _commentsCache[postId]!.add(newComment);
      } else {
        _commentsCache[postId] = [newComment];
      }

      await _saveLocalComment(postId, newComment);
      return newComment;
    } else {
      debugPrint('Server Error [${response.statusCode}]: ${response.body}');
      throw Exception('Failed to add comment');
    }
  }

  Future<List<Comment>> _loadLocalComments(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('local_comments_$postId') ?? [];
    return raw.map((s) => Comment.fromCache(jsonDecode(s))).toList();
  }

  Future<void> _saveLocalComment(int postId, Comment comment) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_comments_$postId';
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(comment.toJson()));
    await prefs.setStringList(key, existing);
  }
}