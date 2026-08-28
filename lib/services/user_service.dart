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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all saved data on logout
  }
}