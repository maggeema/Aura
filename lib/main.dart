import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'Pages/home_page.dart' as home;
import 'Pages/settings_page.dart';
import 'Pages/reviews_page.dart';
import 'Pages/login_page.dart';
import 'Pages/map_page.dart';
import 'Pages/create_account_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set initial route to login
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => CreateAccountPage(),
        '/map': (context) => MapPage(),
        '/home': (context) => home.HomePage(), // Use alias for HomePage
        '/settings': (context) => SettingsPage(),
        '/reviews': (context) => ReviewsPage(),
      },
    );
  }
}
