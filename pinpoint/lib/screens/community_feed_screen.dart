import 'package:flutter/material.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<Map<String, dynamic>> posts = [
    {
      "username": "Aditi Sharma",
      "profilePic":
          "https://randomuser.me/api/portraits/women/79.jpg",
      "image":
          "https://images.unsplash.com/photo-1509042239860-f550ce710b93",
      "caption": "☕ Loved the new latte flavor at Bean & Brew! #coffeelover",
      "likes": 128,
      "comments": 12,
      "time": "2 hrs ago",
      "isLiked": false
    },
    {
      "username": "Ravi Kumar",
      "profilePic":
          "https://randomuser.me/api/portraits/men/32.jpg",
      "image":
          "https://images.unsplash.com/photo-1594007654729-407eedc4be3d",
      "caption": "🍕 Best pizza in town! Used PinPoint offers 🔥",
      "likes": 98,
      "comments": 7,
      "time": "5 hrs ago",
      "isLiked": false
    },
    {
      "username": "Megha Verma",
      "profilePic":
          "https://randomuser.me/api/portraits/women/47.jpg",
      "image":
          "https://images.unsplash.com/photo-1551024709-8f23befc6f87",
      "caption": "Sweet Tooth Bakery never disappoints 🧁💜",
      "likes": 212,
      "comments": 19,
      "time": "1 day ago",
      "isLiked": false
    },
  ];

  void toggleLike(int index) {
    setState(() {
      posts[index]["isLiked"] = !posts[index]["isLiked"];
      posts[index]["likes"] += posts[index]["isLiked"] ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text(
          "Community",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A00F8),
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/create_post'),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 User info row
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(post["profilePic"]),
                  ),
                  title: Text(
                    post["username"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post["time"]),
                  trailing: const Icon(Icons.more_vert, color: Colors.grey),
                ),

                // 🔹 Post image
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      post["image"],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),

                // 🔹 Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => toggleLike(index),
                        child: Icon(
                          post["isLiked"]
                              ? Icons.favorite_rounded
                              : Icons.favorite_border,
                          color: post["isLiked"]
                              ? Colors.pinkAccent
                              : Colors.grey[700],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined,
                          size: 26, color: Colors.grey[700]),
                      const SizedBox(width: 16),
                      Icon(Icons.share_outlined,
                          size: 26, color: Colors.grey[700]),
                    ],
                  ),
                ),

                // 🔹 Likes count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "${post["likes"]} likes",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),

                // 🔹 Caption
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: post["username"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const TextSpan(text: "  "),
                        TextSpan(
                          text: post["caption"],
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Comments link
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "View all ${post["comments"]} comments",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

                const SizedBox(height: 4),
                const Divider(thickness: 0.4, color: Colors.black12),
              ],
            ),
          );
        },
      ),
    );
  }
}
