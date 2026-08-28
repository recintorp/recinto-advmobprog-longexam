class Comment {
  final int id;
  final String body;
  final int postId;
  final int userId;
  final String username;

  Comment({
    required this.id,
    required this.body,
    required this.postId,
    required this.userId,
    required this.username,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      body: json['body'] ?? '',
      postId: json['postId'] ?? 0,
      userId: json['user'] != null ? json['user']['id'] ?? 0 : 0,
      username: json['user'] != null ? json['user']['username'] ?? '' : '',
    );
  }
}