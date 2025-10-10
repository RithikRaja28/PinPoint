import 'package:flutter/material.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<Map<String, dynamic>> posts = [
    {
      "username": "Aditi Sharma",
      "profilePic": "https://randomuser.me/api/portraits/women/79.jpg",
      "image":
          "https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=900&q=80",
      "caption": "☕ Loved the new latte flavor at Bean & Brew! #coffeelover",
      "likes": 128,
      "comments": 12,
      "time": "2 hrs ago",
      "isLiked": false
    },
    {
      "username": "Neha Verma",
      "profilePic": "https://randomuser.me/api/portraits/women/45.jpg",
      "image":
          "https://images.unsplash.com/photo-1606787366850-de6330128bfc?auto=format&fit=crop&w=900&q=80",
      "caption": "Shopping spree done right 🛍️ #deals #PinPoint",
      "likes": 210,
      "comments": 18,
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

  void addNewPost(Map<String, dynamic> newPost) {
    setState(() {
      posts.insert(0, newPost);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Community Feed 💬",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E1D70),
            fontSize: 22,
          ),
        ),
      ),

      // 🌟 Floating Action Button (Add Post)
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF6A00F8),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
          onPressed: () async {
            final newPost = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => const CreatePostScreen(),
              ),
            );
            if (newPost != null) {
              addNewPost(newPost);
            }
          },
        ),
      ),

      // 🌈 Post Feed
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 User Info
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(post["profilePic"]),
                  ),
                  title: Text(
                    post["username"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    post["time"],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  trailing:
                      const Icon(Icons.more_vert_rounded, color: Colors.grey),
                ),

                // 🖼️ Post Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.network(
                        post["image"],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 280,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 280,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7C4DFF),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "PinPoint Deal",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ❤️ Action Buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => toggleLike(index),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: posts[index]["isLiked"] ? 1.2 : 1.0,
                          child: Icon(
                            posts[index]["isLiked"]
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: posts[index]["isLiked"]
                                ? Colors.pinkAccent
                                : Colors.grey[700],
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Icon(Icons.comment_outlined,
                          size: 26, color: Colors.grey[700]),
                      const SizedBox(width: 18),
                      Icon(Icons.share_outlined,
                          size: 26, color: Colors.grey[700]),
                    ],
                  ),
                ),

                // ❤️ Likes Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "${post["likes"]} likes",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // ✍️ Caption
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: post["username"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(text: "  "),
                        TextSpan(text: post["caption"]),
                      ],
                    ),
                  ),
                ),

                // 💬 Comments info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "View all ${post["comments"]} comments",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
