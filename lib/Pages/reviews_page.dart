import 'package:flutter/material.dart';

class ReviewsPage extends StatefulWidget {
  ReviewsPage({Key? key}) : super(key: key);

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Map<String, dynamic>> reviews = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(reviews[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    labelText: 'Write your review (150 words max)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 150,
                  maxLines: null,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _publishReview();
                  },
                  child: Text('Publish Review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${review['name']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (review['address'] != null && review['address'].isNotEmpty) ...[
              Text('Address: ${review['address']}'),
              SizedBox(height: 8),
            ],
            Text('Review: ${review['review']}'),
          ],
        ),
      ),
    );
  }

  void _publishReview() {
    String name = nameController.text.trim();
    String address = addressController.text.trim();
    String review = reviewController.text.trim();

    if (name.isNotEmpty && review.isNotEmpty) {
      Map<String, dynamic> newReview = {
        'name': name,
        'address': address,
        'review': review,
      };

      setState(() {
        reviews.add(newReview);
      });

      // Clear text fields after publishing review
      nameController.clear();
      addressController.clear();
      reviewController.clear();
    } else {
      // Show a snackbar or alert dialog for incomplete form
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in Name and Review fields')),
      );
    }
  }
}
