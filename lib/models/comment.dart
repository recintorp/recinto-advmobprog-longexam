class Comment {
  final int id;
  final String body;
  final int postId;
  final int userId;
  final String username;
  final String name;

  Comment({
    required this.id,
    required this.body,
    required this.postId,
    required this.userId,
    required this.username,
    required this.name,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final fullName = user?['fullName'] as String?;
    final firstName = user?['firstName'] as String?;
    final lastName = user?['lastName'] as String?;
    final joined = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Comment(
      id: json['id'] ?? 0,
      body: json['body'] ?? '',
      postId: json['postId'] ?? 0,
      userId: user != null ? user['id'] ?? 0 : 0,
      username: user != null ? user['username'] ?? '' : '',
      name: (fullName != null && fullName.isNotEmpty) ? fullName : joined,
    );
  }

  // Used to persist locally-added comments to SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'postId': postId,
        'userId': userId,
        'username': username,
        'name': name,
      };

  factory Comment.fromCache(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      body: json['body'] ?? '',
      postId: json['postId'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
    );
  }
}