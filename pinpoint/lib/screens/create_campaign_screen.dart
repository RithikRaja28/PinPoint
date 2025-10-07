import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pinpoint/screens/dashboard_screen.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _titleController = TextEditingController();
  final _offerController = TextEditingController();

  double _radiusKm = 1.0;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  File? _posterFile;
  bool _generatingPoster = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  late final AnimationController _headerController;
  late final Animation<double> _headerScale;

  bool get _step1Valid =>
      _titleController.text.trim().isNotEmpty &&
      _offerController.text.trim().isNotEmpty;

  bool get _step2Valid =>
      _startDate != null &&
      _startTime != null &&
      _endDate != null &&
      _endTime != null &&
      _combinedStart.isBefore(_combinedEnd);

  DateTime get _combinedStart {
    final d = _startDate ?? DateTime.now();
    final t = _startTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  DateTime get _combinedEnd {
    final d = _endDate ?? DateTime.now().add(const Duration(hours: 1));
    final t = _endTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerScale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _offerController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ------------------- Step Navigation --------------------
  void _next() {
    if (_currentStep == 0 && !_step1Valid) {
      _showSnack("Please fill title & offer text.");
      return;
    }
    if (_currentStep == 1 && !_step2Valid) {
      _showSnack("Please choose valid start and end date/time.");
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitCampaign();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------- Poster Pick & Generate --------------------
  Future<void> _pickPoster() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _posterFile = File(picked.path));
        _showSnack("Poster uploaded.");
      }
    } catch (_) {
      _showSnack("Failed to pick image.");
    }
  }

  Future<void> _generatePosterDummy() async {
    setState(() => _generatingPoster = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _posterFile = null;
      _generatingPoster = false;
    });
    _showSnack("AI Poster generated (simulated).");
  }

  // ------------------- Submit Campaign --------------------
  Future<void> _submitCampaign() async {
    setState(() => _isSubmitting = true);
    try {
      final uri = Uri.parse('http://10.0.2.2:5000/api/campaigns/');
      final request = http.MultipartRequest('POST', uri);

      request.fields['title'] = _titleController.text.trim();
      request.fields['offer'] = _offerController.text.trim();
      request.fields['radius_km'] = _radiusKm.toString();
      request.fields['start'] = _combinedStart.toIso8601String();
      request.fields['end'] = _combinedEnd.toIso8601String();

      if (_posterFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('poster', _posterFile!.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        _showSnack("🎉 Campaign created successfully!");
        final data = json.decode(respStr);
        print("Campaign saved: $data");

        if (mounted) setState(() => _isSubmitting = false);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _showSnack("❌ Failed to create campaign: ${response.statusCode}");
        print("Error: $respStr");
      }
    } catch (e) {
      _showSnack("❌ Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  // ------------------- Date & Time Pickers --------------------
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _endTime = t);
  }

  // ------------------- Step Indicator --------------------
  Widget _stepIndicator() {
    const labels = ['Basic', 'Target', 'Poster', 'Review'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= _currentStep;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFB39DDB) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: i == _currentStep
                        ? Colors.deepPurple
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final steps = [
      _basicInfoCard(),
      _targetingCard(),
      _posterCard(),
      _reviewCard(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📢 Launch Your Campaign",
                    style: TextStyle(
                      color: Color(0xFF4A148C),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Step ${_currentStep + 1} of 4 · ${((_currentStep + 1) / 4 * 100).round()}% complete",
                    style: const TextStyle(
                      color: Color(0xFF4A148C),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _stepIndicator(),
                ],
              ),
            ),

            // Main Page
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xFF7E57C2)),
                        ),
                        child: const Text(
                          "← Back",
                          style: TextStyle(color: Color(0xFF7E57C2)),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF7E57C2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentStep < 3
                            ? "Next →"
                            : _isSubmitting
                            ? "Submitting..."
                            : "🚀 Launch Campaign",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- Cards --------------------
  Widget _basicInfoCard() => _cardWrapper(
    title: "📄 Basic Details",
    children: [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: "Campaign Title",
          hintText: "e.g. Weekend Coffee Special ☕",
          border: OutlineInputBorder(),
        ),
        maxLength: 60,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _offerController,
        decoration: const InputDecoration(
          labelText: "Offer Text",
          hintText: "e.g. Get 20% off on all lattes",
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
        maxLength: 280,
      ),
    ],
  );

  Widget _targetingCard() => _cardWrapper(
    title: "🎯 Targeting",
    children: [
      const Text("Target radius"),
      Slider(
        value: _radiusKm,
        min: 0.5,
        max: 5.0,
        divisions: 45,
        label: "${_radiusKm.toStringAsFixed(1)} km",
        onChanged: (v) => setState(() => _radiusKm = v),
      ),
      Text("${_radiusKm.toStringAsFixed(1)} km radius"),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.play_arrow),
        title: Text(
          _startDate == null
              ? "Pick start date & time"
              : "${DateFormat.yMMMd().format(_startDate!)} ${_startTime?.format(context) ?? ''}",
        ),
        onTap: () async {
          await _pickStartDate();
          await _pickStartTime();
        },
      ),
      ListTile(
        leading: const Icon(Icons.stop),
        title: Text(
          _endDate == null
              ? "Pick end date & time"
              : "${DateFormat.yMMMd().format(_endDate!)} ${_endTime?.format(context) ?? ''}",
        ),
        onTap: () async {
          await _pickEndDate();
          await _pickEndTime();
        },
      ),
    ],
  );

  Widget _posterCard() => _cardWrapper(
    title: "🖼️ Campaign Poster",
    children: [
      if (_posterFile != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_posterFile!, height: 200, fit: BoxFit.cover),
        )
      else
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: const Center(child: Text("No poster yet")),
        ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickPoster,
              icon: const Icon(Icons.photo),
              label: const Text("Upload"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generatePosterDummy,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generate AI"),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _reviewCard() => _cardWrapper(
    title: "✅ Review Campaign",
    children: [
      ListTile(
        title: Text(
          _titleController.text.isEmpty
              ? "Untitled Campaign"
              : _titleController.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_offerController.text),
      ),
      Text("Radius: ${_radiusKm.toStringAsFixed(1)} km"),
      Text(
        "Schedule: ${DateFormat.yMMMd().add_jm().format(_combinedStart)} → ${DateFormat.yMMMd().add_jm().format(_combinedEnd)}",
      ),
      const SizedBox(height: 16),
      _posterFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_posterFile!, height: 180, fit: BoxFit.cover),
            )
          : Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(child: Text("No poster")),
            ),
    ],
  );

  Widget _cardWrapper({required String title, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
