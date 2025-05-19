import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final darkGrey = Color(0xFF333333);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Check-Ins',
            style: TextStyle(color: darkGrey),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5D0FE), Color(0xFF93C5FD)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                'Please log in to see your check-ins.',
                style: TextStyle(color: darkGrey, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    final checkinsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('checkins')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Check-Ins',
          style: TextStyle(color: darkGrey, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5D0FE), Color(0xFF93C5FD)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: checkinsRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No check-ins yet.',
                    style: TextStyle(color: darkGrey, fontSize: 16),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_cafe, color: Color(0xFF333333)),
                        ],
                      ),
                      title: Text(
                        cafeName,
                        style: TextStyle(
                          color: darkGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        review,
                        style: TextStyle(
                          color: darkGrey,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Text(
                        '${date.month}/${date.day}/${date.year}',
                        style: TextStyle(color: darkGrey, fontSize: 13),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
