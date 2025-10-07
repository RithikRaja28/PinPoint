class Post {
  final String id;
  final String username;
  final String profileImage;
  final String content;
  final String imageUrl;
  final int likes;
  final int comments;
  final String timeAgo;

  Post({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      timeAgo: json['timeAgo'] ?? '',
    );
  }
}
