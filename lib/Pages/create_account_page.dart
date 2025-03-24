import 'package:flutter/material.dart';
import 'package:date_format_field/date_format_field.dart';

class CreateAccountPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final buttonColor = Colors.green.withOpacity(0.6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BFA5),
              Color(0xFF8BC34A),
              Color(0xFF1A237E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '[placeholder for logo]',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildLabel('email'),
                  _buildTextField(_emailController),
                  SizedBox(height: 20),
                  _buildLabel('password'),
                  _buildTextField(_passwordController, obscure: true),
                  SizedBox(height: 20),
                  _buildLabel('confirm password'),
                  _buildTextField(_confirmPasswordController, obscure: true),
                  SizedBox(height: 20),
                  _buildLabel('birthday'),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: DateFormatField(
                      type: DateFormatType.type2,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        hintText: 'MM/DD/YYYY',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      onComplete: (date) {
                        _birthdayController.text = date.toString();
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () {
                        _signUp(context);
                      },
                      child: Text('Sign Up', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool obscure = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.zero,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  void _signUp(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final birthday = _birthdayController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthday.isEmpty) {
      _showErrorDialog(context, 'Please fill out all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog(context, 'Passwords do not match.');
      return;
    }

    // ✅ Simulate success
    Navigator.pushReplacementNamed(context, '/map');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Up Failed'),
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
