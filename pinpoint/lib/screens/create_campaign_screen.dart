// create_campaign_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:pinpoint/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen>
    with TickerProviderStateMixin {
  String? _posterUrl;
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
  final ScrollController _scrollController = ScrollController();

  // Theme colors
  static const Color brandDark = Color(0xFF6A00F8);
  static const Color brandMid = Color(0xFF7C4DFF);
  static const Color brandLight = Color(0xFFEDE2FF);
  static const Color textPrimary = Color(0xFF2C1A63);
  static const Color neutralBg = Color(0xFFF5F3FE);

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

  void _showSnack(String text, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.redAccent : brandMid,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Navigation ---
  void _next() {
    if (_currentStep == 0 && !_step1Valid) {
      _showSnack("Please fill title & offer text.", true);
      return;
    }
    if (_currentStep == 1 && !_step2Valid) {
      _showSnack("Please choose valid start and end date/time.", true);
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _scrollToTop();
    } else {
      _submitCampaign();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // --- Poster ---
  Future<void> _pickPoster() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        setState(() => _posterFile = File(picked.path));
        _showSnack("Poster uploaded.");
      }
    } catch (_) {
      _showSnack("Failed to pick image.", true);
    }
  }

  Future<void> _generatePosterDummy() async {
    setState(() => _generatingPoster = true);
    try {
      final uri = Uri.parse("http://192.168.1.11:5000/api/poster");
      final request = http.MultipartRequest('POST', uri);
      request.fields['shop_name'] = _titleController.text.trim();
      request.fields['offer'] = _offerController.text.trim();
      request.fields['radius_km'] = _radiusKm.toString();
      request.fields['start'] = _combinedStart.toIso8601String();
      request.fields['end'] = _combinedEnd.toIso8601String();
      if (_posterFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('logo', _posterFile!.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(respStr);
        setState(() {
          _posterUrl = "http://192.168.1.11:5000${data['poster_url']}";
        });
        _showSnack("AI Poster Generated!");
      } else {
        _showSnack("Failed to generate poster.", true);
      }
    } catch (e) {
      _showSnack("Error: $e", true);
    } finally {
      if (mounted) setState(() => _generatingPoster = false);
    }
  }

  // ------------------- Submit Campaign --------------------

  // --- Submit ---
  Future<void> _submitCampaign() async {
    setState(() => _isSubmitting = true);
    try {
      final uri = Uri.parse('http://192.168.1.11:5000/api/campaigns/');
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
      if (response.statusCode == 201) {
        _showSnack("Campaign created successfully!");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _showSnack("Failed to create campaign.", true);
      }
    } catch (e) {
      _showSnack("Error: $e", true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Date Pickers ---
  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _startDate = pickedDate;
          _startTime = pickedTime;
        });
      }
    }
  }

  Future<void> _pickEndDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _endDate = pickedDate;
          _endTime = pickedTime;
        });
      }
    }
  }

  // --- Step Indicator ---
 // --- Step Indicator ---
Widget _stepIndicator() {
  const labels = ['Basic', 'Target', 'Poster', 'Review'];
  final progress = (_currentStep + 1) / labels.length;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Step labels row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          labels.length,
          (i) => Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? brandMid
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: i == _currentStep
                        ? brandDark
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      // // Progress bar
      // ClipRRect(
      //   borderRadius: BorderRadius.circular(8),
      //   child: LinearProgressIndicator(
      //     value: progress,
      //     minHeight: 8,
      //     color: brandMid,
      //     backgroundColor: Colors.grey.shade200,
      //   ),
      // ),
      // const SizedBox(height: 10),
      // Completion status
      Center(
        child: Text(
          "${(progress * 100).round()}% complete",
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}


  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final steps = [
      _basicInfoCard(),
      _targetingCard(),
      _posterCard(),
      _reviewCard(),
    ];

    return Scaffold(
      backgroundColor: neutralBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _scrollingHeader(),
                    const SizedBox(height: 20),
                    _stepIndicator(),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: steps[_currentStep],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _bottomButtons(),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _scrollingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF7FF), Color(0xFFEDE7F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.campaign_rounded, color: brandDark, size: 26),
          SizedBox(width: 10),
          Text(
            "Launch Your Campaign",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: brandDark,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Buttons ---
  Widget _bottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: brandMid),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    color: brandMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandMid,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep < 3 ? "Next" : "Launch Campaign",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Cards ---
  Widget _basicInfoCard() => _cardWrapper("Basic Details", [
    _textInput(
      "Campaign Title",
      _titleController,
      hint: "e.g. Weekend Coffee Special",
    ),
    const SizedBox(height: 16),
    _textInput(
      "Offer Text",
      _offerController,
      hint: "e.g. Get 20% off on all lattes",
      maxLines: 4,
    ),
  ]);

  Widget _targetingCard() => _cardWrapper("Targeting", [
    const Text("Target radius", style: TextStyle(fontWeight: FontWeight.w600)),
    Slider(
      value: _radiusKm,
      min: 0.5,
      max: 5.0,
      divisions: 45,
      label: "${_radiusKm.toStringAsFixed(1)} km",
      activeColor: brandMid,
      onChanged: (v) => setState(() => _radiusKm = v),
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "${_radiusKm.toStringAsFixed(1)} km radius",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    const SizedBox(height: 12),
    _dateTile(
      "Start Date & Time",
      Icons.play_arrow,
      _startDate != null && _startTime != null
          ? "${DateFormat.yMMMd().format(_startDate!)}  ${_startTime!.format(context)}"
          : "Pick start date & time",
      _pickStartDateTime,
    ),
    const SizedBox(height: 10),
    _dateTile(
      "End Date & Time",
      Icons.stop,
      _endDate != null && _endTime != null
          ? "${DateFormat.yMMMd().format(_endDate!)}  ${_endTime!.format(context)}"
          : "Pick end date & time",
      _pickEndDateTime,
    ),
  ]);

  Widget _posterCard() => _cardWrapper("Campaign Poster", [
    _posterPreview(),
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
            onPressed: _generatingPoster ? null : _generatePosterDummy,
            icon: _generatingPoster
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: _generatingPoster
                ? const Text("Generating...")
                : const Text("Generate AI"),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandDark.withOpacity(0.85),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  ]);

  Widget _reviewCard() => _cardWrapper("Review Campaign", [
    ListTile(
      title: Text(
        _titleController.text.isEmpty
            ? "Untitled Campaign"
            : _titleController.text,
      ),
      subtitle: Text(_offerController.text),
    ),
    Text("Radius: ${_radiusKm.toStringAsFixed(1)} km"),
    Text(
      "Schedule: ${DateFormat.yMMMd().add_jm().format(_combinedStart)} → ${DateFormat.yMMMd().add_jm().format(_combinedEnd)}",
    ),
    const SizedBox(height: 12),
    _posterPreview(),
  ]);

  // --- Reusable Widgets ---
  Widget _cardWrapper(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      shadowColor: brandMid.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textInput(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: brandMid),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTile(
    String label,
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: brandMid),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(text, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _posterPreview() {
    final height = 180.0;
    if (_posterFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_posterFile!, height: height, fit: BoxFit.cover),
      );
    } else if (_posterUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_posterUrl!, height: height, fit: BoxFit.cover),
      );
    } else {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
  }
}
