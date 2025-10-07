import 'package:flutter/material.dart';
import '../models/footfall_data.dart';
import '../services/api_service.dart';

class HeatmapProvider with ChangeNotifier {
  List<FootfallData> _data = [];
  bool _loading = true;

  List<FootfallData> get data => _data;
  bool get loading => _loading;

  final ApiService apiService = ApiService();

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();
    _data = await apiService.fetchFootfallData();
    _loading = false;
    notifyListeners();
  }

  int getTotalFootfall() {
    return _data.fold(0, (sum, item) => sum + item.count);
  }

  FootfallData? getPeakFootfall() {
    if (_data.isEmpty) return null;
    _data.sort((a, b) => b.count.compareTo(a.count));
    return _data.first;
  }
}
