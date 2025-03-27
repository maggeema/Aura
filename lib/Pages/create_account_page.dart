import 'package:flutter/material.dart';
import 'package:date_format_field/date_format_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  DateTime? _birthday;

  @override
  Widget build(BuildContext context) {
    final buttonColor = Colors.grey.withOpacity(0.6);
    final darkGrey = Color(0xFF333333);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: darkGrey),
                            label: Text('Back to Login', style: TextStyle(color: darkGrey)),
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildLabel('email', darkGrey),
                        _buildTextField(_emailController, darkGrey),
                        SizedBox(height: 20),
                        _buildLabel('password', darkGrey),
                        _buildTextField(_passwordController, darkGrey, obscure: true),
                        SizedBox(height: 20),
                        _buildLabel('confirm password', darkGrey),
                        _buildTextField(_confirmPasswordController, darkGrey, obscure: true),
                        SizedBox(height: 20),
                        _buildLabel('birthday', darkGrey),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: DateFormatField(
                            type: DateFormatType.type2,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'MM/DD/YYYY',
                              hintStyle: TextStyle(color: darkGrey),
                            ),
                            onComplete: (date) {
                              setState(() {
                                _birthday = date;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 160,
                          child: ElevatedButton(
                            onPressed: () => _signUp(context),
                            child: Text('Sign Up', style: TextStyle(fontSize: 16, color: darkGrey)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(color: color, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, Color color, {bool obscure = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.zero,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: color),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  void _signUp(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || _birthday == null) {
      _showErrorDialog(context, 'Please fill out all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog(context, 'Passwords do not match.');
      return;
    }

    final now = DateTime.now();
    final age = now.difference(_birthday!).inDays ~/ 365;

    if (age < 16) {
      _showErrorDialog(context, 'You must be at least 16 years old to sign up.');
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'birthday': _birthday!.toIso8601String(),
            'createdAt': Timestamp.now(),
          });

      Navigator.pushReplacementNamed(context, '/map');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'This email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;
        default:
          errorMessage = 'Something went wrong. Please try again.';
      }

      _showErrorDialog(context, errorMessage);
    } catch (e) {
      _showErrorDialog(context, 'Unexpected error: ${e.toString()}');
    }
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
