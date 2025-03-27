import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

@override
Widget build(BuildContext context) {
  final buttonColor = Colors.grey.withOpacity(0.6);
  final darkGrey = Color(0xFF333333); // ✅ Dark grey text

  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Spacer(),
              // Email field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'email',
                    style: TextStyle(
                      color: darkGrey,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(color: darkGrey),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Password field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'password',
                    style: TextStyle(
                      color: darkGrey,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: darkGrey),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _forgotPassword(context),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: darkGrey),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Login button
              Container(
                width: 160,
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  child: Text('Login', style: TextStyle(fontSize: 16, color: darkGrey)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // Create Account button
              Container(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Create Account', style: TextStyle(fontSize: 16, color: darkGrey)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      Navigator.pushReplacementNamed(context, '/map');
    } catch (e) {
      _showDialog(
        context,
        title: 'Login Failed',
        message: e.toString(),
      );
    }
  }

  void _forgotPassword(BuildContext context) {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog(
        context,
        title: 'Forgot Password',
        message: 'Please enter your email address first.',
      );
      return;
    }

    FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
      _showDialog(
        context,
        title: 'Reset Email Sent',
        message: 'Check your inbox for a link to reset your password.',
      );
    }).catchError((error) {
      _showDialog(
        context,
        title: 'Error',
        message: error.toString(),
      );
    });
  }

  void _showDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
