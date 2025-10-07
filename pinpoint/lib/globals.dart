import 'package:translator/translator.dart';

String selectedLang = 'en';
final globalTranslator = GoogleTranslator();


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




