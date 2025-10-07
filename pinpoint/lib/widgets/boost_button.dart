import 'package:flutter/material.dart';

class BoostButton extends StatelessWidget {
  final VoidCallback onPressed;

  BoostButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.trending_up),
      label: Text("Boost Suggestion"),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
