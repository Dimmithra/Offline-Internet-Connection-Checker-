import 'package:flutter/material.dart';
import 'package:network_check_app/network_result_screen.dart';
// import 'package:admob_flutter/admob_flutter.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // // Initialize without device test ids.
  // Admob.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NetworkResultScreen(),
    );
  }
}
