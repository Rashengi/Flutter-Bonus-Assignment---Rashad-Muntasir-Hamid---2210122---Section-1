import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summer_iub_app/firebase_options.dart';
import 'package:summer_iub_app/screens/home.dart';
import 'package:summer_iub_app/state_management/coffee_state_management.dart';

Future<void> main() async {
  // Required before any plugin work happens in main().
  WidgetsFlutterBinding.ensureInitialized();

  final bool firebaseEnabled = await _initializeFirebaseIfConfigured();

  runApp(MyApp(firebaseEnabled: firebaseEnabled));
}

Future<bool> _initializeFirebaseIfConfigured() async {
  if (!DefaultFirebaseOptions.hasValidConfig) {
    debugPrint(
      'Firebase is not configured. Running in offline-only mode. '
      'Please update firebase_options.dart with your Firebase project values.',
    );
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e\n$st');
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;

  const MyApp({super.key, required this.firebaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (context) =>
                  CoffeeStateManagement(firebaseEnabled: firebaseEnabled),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Summer CSE464 class',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        ),
        home: HomePage(pageTitle: "Welcome to CSE464!"),
      ),
    );
  }
}
