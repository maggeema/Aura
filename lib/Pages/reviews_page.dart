import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsPage extends StatefulWidget {
  final String cafeId;
  final String cafeName;
  final String address;

  ReviewsPage({
    required this.cafeId,
    required this.cafeName,
    required this.address,
  });

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  int currentPage = 0;

  String? selectedSeating;
  String? selectedAvailability;
  String? selectedNoise;
  Set<String> selectedAmenities = {};
  String? selectedSeatingType;
  Set<String> selectedVibes = {};

  final Map<String, IconData> allIcons = {
    "Yes": Icons.check,
    "No": Icons.clear,
    "Many spots available": Icons.event_available,
    "Limited Spots": Icons.event_busy,
    "No spots available": Icons.block,
    "Quiet": Icons.volume_mute,
    "Chatty": Icons.record_voice_over,
    "Loud": Icons.volume_up,
    "WiFi Available": Icons.wifi,
    "Bathroom": Icons.wc,
    "Power Outlets": Icons.power,
    "Isolated Seating": Icons.person,
    "Communal Seating": Icons.group,
    "Both are offered here": Icons.category,
    "Minimalist": Icons.crop_square,
    "Cozy": Icons.chair,
    "Ambient": Icons.nightlight,
    "Playful": Icons.sentiment_satisfied,
    "Aromatic": Icons.local_florist,
    "Sociable": Icons.groups,
    "Retro": Icons.radio,
    "Trendy": Icons.whatshot,
    "Bright": Icons.wb_sunny,
    "Dim": Icons.lightbulb_outline,
    "Upbeat": Icons.music_note,
    "Spacious": Icons.open_in_full,
    "Crowded": Icons.people,
    "Energic": Icons.bolt,
    "Snug": Icons.bed,
    "Lively": Icons.surround_sound,
    "Work Friendly": Icons.work,
    "No Laptop Zone": Icons.do_not_disturb_alt,
    "Deep Focus": Icons.center_focus_strong,
  };

  final List<String> vibesOptions = [
    "Minimalist", "Cozy", "Ambient", "Playful", "Aromatic",
    "Sociable", "Retro", "Trendy", "Bright", "Dim",
    "Upbeat", "Spacious", "Crowded", "Energic", "Snug", "Lively",
    "Work Friendly", "No Laptop Zone", "Deep Focus"
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildSingleSelectPage("Is there seating offered?", ["Yes", "No"], selectedSeating, (val) {
        setState(() {
          selectedSeating = val;
          if (val == "No") currentPage = 1;
        });
      }),
      if (selectedSeating == "No") _buildNoSeatingConfirmationPage(),
      if (selectedSeating == "Yes") ...[
        _buildSingleSelectPage("Current availability?", ["Many spots available", "Limited Spots", "No spots available"], selectedAvailability, (val) {
          setState(() => selectedAvailability = val);
        }),
        _buildSingleSelectPage("Noise level?", ["Quiet", "Chatty", "Loud"], selectedNoise, (val) {
          setState(() => selectedNoise = val);
        }),
        _buildMultiSelectPage("Amenities available", ["WiFi Available", "Bathroom", "Power Outlets"], selectedAmenities),
        _buildSingleSelectPage("Seating type?", ["Isolated Seating", "Communal Seating", "Both are offered here"], selectedSeatingType, (val) {
          setState(() => selectedSeatingType = val);
        }),
        _buildVibesPage(),
      ]
    ];

    return WillPopScope(
      onWillPop: _onExitPrompt,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _confirmExitToMap,
          ),
          title: Text('Check-In'),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5D0FE), Color(0xFF93C5FD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: pages[currentPage],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: currentPage > 0
                      ? ElevatedButton(
                          onPressed: () => setState(() => currentPage--),
                          style: _navButtonStyle(),
                          child: Text("Back"),
                        )
                      : SizedBox.shrink(),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: _isLastPage()
                      ? ElevatedButton(
                          onPressed: _canProceed() ? _submitReview : null,
                          style: _navButtonStyle(),
                          child: Text("Publish"),
                        )
                      : ElevatedButton(
                          onPressed: _canProceed() ? () => setState(() => currentPage++) : null,
                          style: _navButtonStyle(),
                          child: Text("Next"),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSeatingConfirmationPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("No seating? Let others know.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 24),
        Text("Press publish to confirm this check-in.", textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSingleSelectPage(String title, List<String> options, String? selected, void Function(String) onSelect) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((option) {
            final isSelected = selected == option;
            return ElevatedButton.icon(
              icon: Icon(allIcons[option]),
              label: Text(option),
              onPressed: () => onSelect(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.purple[100] : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectPage(String title, List<String> options, Set<String> selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return ElevatedButton.icon(
              icon: Icon(allIcons[option]),
              label: Text(option),
              onPressed: () {
                setState(() {
                  isSelected ? selected.remove(option) : selected.add(option);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.purple[100] : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVibesPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Vibes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: vibesOptions.map((vibe) {
            final isSelected = selectedVibes.contains(vibe);
            return ElevatedButton.icon(
              icon: Icon(allIcons[vibe]),
              label: Text(vibe),
              onPressed: () {
                setState(() {
                  isSelected ? selectedVibes.remove(vibe) : selectedVibes.add(vibe);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.purple[100] : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  ButtonStyle _navButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple[100],
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    );
  }

  bool _canProceed() {
    if (selectedSeating == "No" && currentPage == 1) return true;
    switch (currentPage) {
      case 0:
        return selectedSeating != null;
      case 1:
        return selectedAvailability != null;
      case 2:
        return selectedNoise != null;
      case 3:
        return true;
      case 4:
        return selectedSeatingType != null;
      case 5:
        return selectedVibes.isNotEmpty;
      default:
        return true;
    }
  }

  bool _isLastPage() {
    return (selectedSeating == "Yes" && currentPage == 5) ||
           (selectedSeating == "No" && currentPage == 1);
  }

  Future<bool> _onExitPrompt() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Leave this page?"),
        content: Text("You haven't published your check-in yet. Do you want to return to the home page?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes, Leave")),
        ],
      ),
    ) ?? false;
  }

  void _confirmExitToMap() async {
    bool shouldLeave = await _onExitPrompt();
    if (shouldLeave) {
      Navigator.pushNamedAndRemoveUntil(context, '/map', (_) => false);
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final data = userDoc.data();
    final streak = data?['streak'] ?? 0;
    final lastCheckIn = data?['lastCheckIn'];

    // Determine today's date (calendar day only)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? lastDate;

    if (lastCheckIn != null && lastCheckIn is Timestamp) {
      final last = lastCheckIn.toDate();
      lastDate = DateTime(last.year, last.month, last.day);
    }

    // If last check-in was before today, increment streak
    int newStreak = streak;
    if (lastDate == null || lastDate.isBefore(today)) {
      newStreak = streak + 1;
      await userRef.update({
        'streak': newStreak,
        'lastCheckIn': Timestamp.fromDate(today),
      });
    }

    // Set avatar based on new streak
    String avatarImage;
    if (newStreak >= 30) {
      avatarImage = "assets/owl.png";
    } else if (newStreak >= 14) {
      avatarImage = "assets/cat.png";
    } else if (newStreak >= 7) {
      avatarImage = "assets/turtle.png";
    } else {
      avatarImage = "assets/coffee_logo.png";
    }

    final timestamp = Timestamp.now();
    final reviewSummary = [
      selectedAvailability,
      selectedNoise,
      selectedAmenities.join(', '),
      selectedSeatingType,
      selectedVibes.isNotEmpty ? "Vibes: ${selectedVibes.join(', ')}" : null,
    ].whereType<String>().join(" | ");

    final reviewData = {
      'seatingOffered': selectedSeating,
      'availability': selectedAvailability,
      'noiseLevel': selectedNoise,
      'amenities': selectedAmenities.join(', '),
      'seatingType': selectedSeatingType,
      'vibes': selectedVibes.join(', '),
      'review': reviewSummary,
      'timestamp': timestamp,
      'avatar': avatarImage,
    };


    await FirebaseFirestore.instance
        .collection('cafes')
        .doc(widget.cafeId)
        .collection('reviews')
        .add(reviewData);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checkins')
        .add({
      'cafeId': widget.cafeId,
      'cafeName': widget.cafeName,
      'address': widget.address,
      'review': reviewSummary,
      'timestamp': timestamp,
    });

    Navigator.pushNamedAndRemoveUntil(context, '/map', (_) => false);
  }

}
