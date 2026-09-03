import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  Future<User?> login(String username, String password) async {
    final uri = Uri.parse('$host/auth/login');
    final response = await post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id);
      await prefs.setString('token', user.token);
      await prefs.setString('firstName', user.firstName);
      await prefs.setString('lastName', user.lastName);
      await prefs.setString('image', user.image);

      return user;
    } else {
      throw Exception('Authentication failed: ${response.statusCode}');
    }
  }

  Future<List<User>> getUsers({int limit = 0}) async {
    final uri = Uri.parse('$host/users?limit=$limit');
    final response = await get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List usersJson = data['users'] ?? [];
      return usersJson.map((u) => User.fromJson(u)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Only remove this session's identity -- NOT prefs.clear(). A blanket
    // clear() was wiping data that isn't session-specific, like the
    // "local_comments_$postId" store standing in for a real comments
    // backend (meant to be visible to every account, not just the one
    // that added the comment) and the dark mode preference. That's why
    // logging out was permanently deleting comments and resetting theme.
    await prefs.remove('userId');
    await prefs.remove('token');
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('image');
  }
}