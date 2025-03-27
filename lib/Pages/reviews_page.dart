import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsPage extends StatefulWidget {
  final String cafeId;
  final String cafeName;
  final String address;

  ReviewsPage({
    Key? key,
    required this.cafeId,
    required this.cafeName,
    required this.address,
  }) : super(key: key);

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  Set<String> selectedSeatingOffered = {};
  Set<String> selectedAvailability = {};
  Set<String> selectedNoiseLevel = {};
  Set<String> selectedAmenities = {};
  Set<String> selectedSeatingType = {};
  Set<String> selectedVibes = {};

  @override
  Widget build(BuildContext context) {
    final bool seatingIsYes = selectedSeatingOffered.contains('Yes');

    return Scaffold(
      appBar: AppBar(title: Text('Add Check-In')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildSection('Seating offered?', ['Yes', 'No'], selectedSeatingOffered, (value) {
                            setState(() {
                              selectedSeatingOffered.clear();
                              selectedSeatingOffered.add(value);
                            });
                          }),

                          if (seatingIsYes) ...[
                            _buildSection('Current Availability?', [
                              'Many spots available',
                              'Limited Spots',
                              'No spots available'
                            ], selectedAvailability, _handleSingleSelect(selectedAvailability)),

                            _buildSection('Noise Level', [
                              'Quiet', 'Chatty', 'Loud'
                            ], selectedNoiseLevel, _handleSingleSelect(selectedNoiseLevel)),

                            _buildSection('Amenities', [
                              'WiFi Available', 'Bathroom', 'Power Outlets'
                            ], selectedAmenities, _handleMultiSelect(selectedAmenities)),

                            _buildSection('Seating', [
                              'Isolated Seating', 'Communal Seating'
                            ], selectedSeatingType, _handleSingleSelect(selectedSeatingType)),

                            _buildSection('Vibes', [
                              'Work Friendly', 'Social Atmosphere', 'Deep Focus'
                            ], selectedVibes, _handleMultiSelect(selectedVibes)),
                          ],

                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitReview,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                            ),
                            child: Text('Publish'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submitReview() async {
    final data = {
      'seatingOffered': selectedSeatingOffered.join(', '),
      'availability': selectedAvailability.join(', '),
      'noiseLevel': selectedNoiseLevel.join(', '),
      'amenities': selectedAmenities.join(', '),
      'seatingType': selectedSeatingType.join(', '),
      'vibes': selectedVibes.join(', '),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('cafes')
        .doc(widget.cafeId)
        .collection('reviews')
        .add(data);

    if (!mounted) return;
    Navigator.pop(context); // ✅ Return to map
  }

  void Function(String) _handleSingleSelect(Set<String> targetSet) => (value) {
        setState(() {
          targetSet.clear();
          targetSet.add(value);
        });
      };

  void Function(String) _handleMultiSelect(Set<String> targetSet) => (value) {
        setState(() {
          if (targetSet.contains(value)) {
            targetSet.remove(value);
          } else {
            targetSet.add(value);
          }
        });
      };

  Widget _buildSection(String title, List<String> options, Set<String> selectedSet, void Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: options.map((option) {
            final bool isSelected = selectedSet.contains(option);
            return ElevatedButton(
              onPressed: () => onSelect(option),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(160, 60),
                backgroundColor: isSelected ? const Color.fromARGB(255, 194, 218, 243) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              child: Text(
                option,
                style: TextStyle(fontSize: 16, color: isSelected ? Colors.grey : null),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
