import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Pages/home_page.dart' as home;
import 'Pages/settings_page.dart';
import 'Pages/reviews_page.dart';
import 'Pages/login_page.dart';
import 'Pages/map_page.dart';
import 'Pages/create_account_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/home': (context) => home.HomePage(),
        '/settings': (context) => SettingsPage(),
        '/reviews': (context) => ReviewsPage(),
      },
    );
  }
}
