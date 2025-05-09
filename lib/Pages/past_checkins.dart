import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final darkGrey = Color(0xFF333333);

    // Get signed-in user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('My Check-Ins')),
        body: Center(
          child: Text(
            'Please log in to see your check-ins.',
            style: TextStyle(color: darkGrey),
          ),
        ),
      );
    }

    // Firestore reference for this user's check-ins
    final checkinsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('checkins')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text('My Check-Ins')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: checkinsRef.snapshots(), // real-time updates
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No check-ins yet.',
                  style: TextStyle(color: darkGrey),
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                final cafeName = data['cafeName'] as String? ?? 'Unknown Café';
                final review = data['review'] as String? ?? '';
                final date = (data['timestamp'] as Timestamp).toDate();

                return ListTile(
                  // Center cup icon alongside two text lines
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_cafe, color: darkGrey),
                    ],
                  ),

                  // Line 1: Café name
                  title: Text(
                    cafeName,
                    style: TextStyle(
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Line 2: the user’s actual review in smaller font
                  subtitle: Text(
                    review,
                    style: TextStyle(
                      color: darkGrey,
                      fontSize: 12,
                    ),
                  ),

                  // Date on the right
                  trailing: Text(
                    '${date.month}/${date.day}/${date.year}',
                    style: TextStyle(color: darkGrey, fontSize: 12),
                  ),
                );
              },
            );
          },
        ), // StreamBuilder
      ), // Container
    ); // Scaffold
  }
}
