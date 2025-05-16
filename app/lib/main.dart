import 'package:app/app/login_page.dart';
import 'package:app/app/register_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showLogin = true;

  void toggleView() => setState(() => showLogin = !showLogin);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:
          showLogin
              ? LoginPage(onToggle: toggleView)
              : RegisterPage(onToggle: toggleView),
    );
  }
}
