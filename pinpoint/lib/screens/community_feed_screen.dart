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
      "image": "https://images.unsplash.com/photo-1509042239860-f550ce710b93",
      "caption": "☕ Loved the new latte flavor at Bean & Brew! #coffeelover",
      "likes": 128,
      "comments": 12,
      "time": "2 hrs ago",
      "isLiked": false
    },
    {
      "username": "Ravi Kumar",
      "profilePic": "https://randomuser.me/api/portraits/men/32.jpg",
      "image": "https://images.unsplash.com/photo-1594007654729-407eedc4be3d",
      "caption": "🍕 Best pizza in town! Used PinPoint offers 🔥",
      "likes": 98,
      "comments": 7,
      "time": "5 hrs ago",
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
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Community Feed 💬",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C1A63),
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
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF6A00F8),
          child: const Icon(Icons.add, size: 28),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(post["profilePic"]),
                  ),
                  title: Text(
                    post["username"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    post["time"],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.grey),
                ),

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post["image"],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => toggleLike(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Icon(
                            post["isLiked"]
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: post["isLiked"]
                                ? Colors.pinkAccent
                                : Colors.grey[700],
                            size: post["isLiked"] ? 30 : 27,
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
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
