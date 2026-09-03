import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostLikeState {
  final bool isLiked;
  final int likes;
  const PostLikeState({required this.isLiked, required this.likes});
}

/// DummyJSON has no real "like" endpoint, so this cache — shared across
/// every PostCard/DetailScreen instance and backed by SharedPreferences —
/// is the actual source of truth for like state.
///
/// Keyed by "userId:postId" rather than just postId, since whether *you*
/// liked a post is personal — different accounts on the same device must
/// never share like state, even though the like count itself is shared.
class PostInteractionService {
  static final Map<String, PostLikeState> _cache = {};
  static Future<void>? _hydrationFuture;
  static const _prefsKey = 'post_like_state';

  Future<void> _hydrate() => _hydrationFuture ??= _doHydrate();

  Future<void> _doHydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final Map<String, dynamic> data = jsonDecode(raw);
    data.forEach((key, value) {
      _cache[key] = PostLikeState(
        isLiked: value['isLiked'] as bool,
        likes: value['likes'] as int,
      );
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _cache.map(
      (key, value) => MapEntry(key, {'isLiked': value.isLiked, 'likes': value.likes}),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<String> _keyFor(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    return '$userId:$postId';
  }

  Future<PostLikeState> getLikeState(int postId, int fallbackLikes) async {
    await _hydrate();
    final key = await _keyFor(postId);
    return _cache[key] ?? PostLikeState(isLiked: false, likes: fallbackLikes);
  }

  Future<PostLikeState> toggleLike(int postId, int fallbackLikes) async {
    await _hydrate();
    final key = await _keyFor(postId);
    final current = _cache[key] ?? PostLikeState(isLiked: false, likes: fallbackLikes);
    final updated = PostLikeState(
      isLiked: !current.isLiked,
      likes: current.isLiked ? current.likes - 1 : current.likes + 1,
    );
    _cache[key] = updated;
    await _persist();
    return updated;
  }
}