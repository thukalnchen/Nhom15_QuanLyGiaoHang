import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.login),
      ),
      body: const Center(
        child: Text('Login Screen - TODO'),
      ),
    );
  }
}
