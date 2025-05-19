import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String email = '';
  String age = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = doc.data();
      if (userData != null) {
        final emailFromDb = userData['email'] as String? ?? '';
        final ageFromDb = userData['age'] as String? ?? '';

        setState(() {
          email = emailFromDb;
          age = ageFromDb;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w500),
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
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),

                      // Email field
                      _buildProfileInfo(
                        title: 'Email',
                        value: email.isNotEmpty ? email : 'maggeema@gmail.com',
                      ),
                      SizedBox(height: 20),

                      // Age field
                      _buildProfileInfo(
                        title: 'Age',
                        value: age.isNotEmpty ? age : '22 years',
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo({required String title, required String value}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333), // Dark grey label
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333), // Same dark grey for consistency
            ),
          ),
        ],
      ),
    );
  }
}
