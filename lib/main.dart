import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Pages/login_page.dart';
import 'Pages/create_account_page.dart';
import 'Pages/map_page.dart';
import 'Pages/reviews_page.dart';
import 'Pages/account_page.dart';
import 'Pages/past_checkins.dart';
import 'Pages/upload_cafes.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

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
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorObservers: [routeObserver],  
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => CreateAccountPage(),
        '/map': (context) => MapPage(),
        '/account': (context) => AccountPage(),
        '/checkins': (context) => CheckInsPage(),
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
