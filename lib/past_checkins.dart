// checkins_page.dart
import 'package:flutter/material.dart';

class CheckInsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final darkGrey = Color(0xFF333333);

    return Scaffold(
      appBar: AppBar(title: Text('My Check-Ins')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: 5, // Placeholder number
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Café ${index + 1}', style: TextStyle(color: darkGrey)),
              subtitle: Text('Placeholder review data', style: TextStyle(color: darkGrey)),
              leading: Icon(Icons.local_cafe, color: darkGrey),
            );
          },
        ),
      ),
    );
  }
}
