import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  final Color darkGrey = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 40),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                ),
                Spacer(),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  obscureText: false,
                  showToggle: false,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  showToggle: true,
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _forgotPassword(context),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildButton('Login', () => _login(context)),
                SizedBox(height: 15),
                _buildButton('Create Account', () {
                  Navigator.pushNamed(context, '/register');
                }),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required bool showToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: darkGrey, fontSize: 14)),
        SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: darkGrey),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: showToggle
                  ? IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 3,
        ),
      ),
    );
  }

  void _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/map');
    } catch (e) {
      _showDialog(context, title: 'Login Failed', message: e.toString());
    }
  }

  void _forgotPassword(BuildContext context) {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog(context, title: 'Forgot Password', message: 'Please enter your email address first.');
      return;
    }

    FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
      _showDialog(context, title: 'Reset Email Sent', message: 'Check your inbox to reset your password.');
    }).catchError((error) {
      _showDialog(context, title: 'Error', message: error.toString());
    });
  }

  void _showDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
      ),
    );
  }
}
