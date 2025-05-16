import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onToggle;
  const RegisterPage({super.key, required this.onToggle});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  String errorMsg = '';

  void register() async {
    final res = await registerUser(
      nameCtrl.text,
      emailCtrl.text,
      passwordCtrl.text,
    );
    if (res.containsKey('error')) {
      setState(() => errorMsg = res['error']);
    } else {
      setState(() => errorMsg = 'Registered successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text('Register')),
            Text(errorMsg, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: widget.onToggle,
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
