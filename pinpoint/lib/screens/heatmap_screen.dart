import 'package:flutter/material.dart';
import '../widgets/heatmap_overlay.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Population Density Heatmap")),
      body: const HeatmapOverlay(),
    );
  }
}
