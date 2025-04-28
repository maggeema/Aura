import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String email = '';
  String memberDuration = '';
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
        final emailFromDb = userData['email'] as String?;
        final createdAtTimestamp = userData['createdAt'] as Timestamp?;

        if (emailFromDb != null && createdAtTimestamp != null) {
          final createdAt = createdAtTimestamp.toDate();
          final now = DateTime.now();
          final difference = now.difference(createdAt);

          setState(() {
            email = emailFromDb;
            memberDuration = formatDuration(difference);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false; // Even if fields are missing, stop loading spinner
          });
        }
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

  String formatDuration(Duration diff) {
    if (diff.inDays >= 365) {
      final years = diff.inDays ~/ 365;
      return "$years year${years > 1 ? 's' : ''} ago";
    } else if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return "$months month${months > 1 ? 's' : ''} ago";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    } else {
      return "Joined today!";
    }
  }

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Password Reset'),
          content: Text('A password reset link has been sent to your email.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
          ],
        ),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final darkGrey = Color(0xFF333333);

    return Scaffold(
      appBar: AppBar(title: Text('My Account')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator() // show spinner while loading
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGrey)),
                      SizedBox(height: 4),
                      Text(email.isNotEmpty ? email : 'Unavailable', style: TextStyle(fontSize: 16, color: darkGrey)),
                      SizedBox(height: 20),
                      Text('Member Since:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGrey)),
                      SizedBox(height: 4),
                      Text(memberDuration.isNotEmpty ? memberDuration : 'Unavailable', style: TextStyle(fontSize: 16, color: darkGrey)),
                      SizedBox(height: 40),
                      _buildActionButtons(darkGrey),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color darkGrey) {
    return Column(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.6),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text('Change Password', style: TextStyle(fontSize: 16, color: darkGrey)),
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/checkins'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.6),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text('View My Check-Ins', style: TextStyle(fontSize: 16, color: darkGrey)),
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.7),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text('Logout', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
