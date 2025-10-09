import 'package:flutter/material.dart';
import 'package:translator/translator.dart'; // make sure to add 'translator: ^0.1.7' or latest version in pubspec.yaml

class DummyPage extends StatefulWidget {
  const DummyPage({super.key});

  @override
  State<DummyPage> createState() => _DummyPageState();
}

class _DummyPageState extends State<DummyPage> {
  final translator = GoogleTranslator();
  String textToTranslate = "Hello, how are you?";
  String selectedLang = 'es'; // Default: Spanish
  final List<Map<String, String>> languages = [
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'German', 'code': 'de'},
    {'name': 'Tamil', 'code': 'ta'},
    {'name': 'Hindi', 'code': 'hi'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Language Translation Test"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Enter text to translate:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type something here...",
              ),
              onChanged: (value) {
                setState(() {
                  textToTranslate = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Select Language: ",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedLang,
                  items: languages
                      .map((lang) => DropdownMenuItem(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLang = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            /// FutureBuilder Section
            FutureBuilder<String>(
              future: translator
                  .translate(textToTranslate, to: selectedLang)
                  .then((value) => value.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Translating...",
                    style: TextStyle(color: Colors.black54),
                  );
                }
                if (snapshot.hasError) {
                  return const Text(
                    "Error during translation",
                    style: TextStyle(color: Colors.red),
                  );
                }
                return Text(
                  snapshot.data ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
