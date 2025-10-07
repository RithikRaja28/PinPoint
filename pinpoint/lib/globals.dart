import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:pinpoint/user_model.dart';

String selectedLang = 'en';
final globalTranslator = GoogleTranslator();
UserModel? currentUser;
final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

// Navigator.pushReplacementNamed(context, '/dashboard');

//  FutureBuilder<String>(
//               future: translator
//                   .translate(textToTranslate, to: selectedLang)
//                   .then((value) => value.text),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Text(
//                     "Translating...",
//                     style: TextStyle(color: Colors.black54),
//                   );
//                 }
//                 if (snapshot.hasError) {
//                   return const Text(
//                     "Error during translation",
//                     style: TextStyle(color: Colors.red),
//                   );
//                 }
//                 return Text(
//                   snapshot.data ?? "",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.blueAccent,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 );
//               },
//             ),
