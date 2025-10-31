import 'package:flutter/material.dart';
import 'home.dart'; // 👈 make sure this path is correct

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // 👈 this should now work fine
    );
  }
}
