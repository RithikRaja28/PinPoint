import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  String? selectedImage;

  void pickImage() async {
    // Placeholder for image picker (will integrate later)
    setState(() {
      selectedImage =
          "https://images.unsplash.com/photo-1509042239860-f550ce710b93";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text("Create Post"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Post uploaded (mock only)"),
                backgroundColor: Color(0xFF6A00F8),
              ));
            },
            child: const Text(
              "Share",
              style: TextStyle(
                  color: Color(0xFF6A00F8), fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: selectedImage != null
                      ? DecorationImage(
                          image: NetworkImage(selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedImage == null
                    ? const Center(
                        child: Icon(Icons.add_a_photo_outlined,
                            color: Color(0xFF6A00F8), size: 50),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: "Write a caption...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: pickImage,
              icon:
                  const Icon(Icons.photo_library_outlined, color: Color(0xFF6A00F8)),
              label: const Text(
                "Choose Photo",
                style: TextStyle(color: Color(0xFF6A00F8)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6A00F8)),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
