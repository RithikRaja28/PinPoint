import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/footfall_data.dart';

class ApiService {
  Future<List<FootfallData>> fetchFootfallData() async {
    final String response = await rootBundle.loadString(
      'assets/mock_footfall.json',
    );
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => FootfallData.fromJson(json)).toList();
  }
}
