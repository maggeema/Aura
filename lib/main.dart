import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Pages/login_page.dart';
import 'Pages/create_account_page.dart';
import 'Pages/map_page.dart';
import 'Pages/reviews_page.dart';

import 'Pages/upload_cafes.dart'; // ✅ Import the upload script

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await uploadCafesFromCSV(); // ✅ Call the function ONCE to upload data
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => CreateAccountPage(),
        '/map': (context) => MapPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/reviews') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => ReviewsPage(
              cafeId: args['cafeId']!,
              cafeName: args['cafeName']!,
              address: args['address']!,
            ),
          );
        }
        return null;
      },
    );
  }
}
