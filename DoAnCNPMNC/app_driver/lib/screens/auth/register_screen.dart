import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.register),
      ),
      body: const Center(
        child: Text('Register Screen - TODO'),
      ),
    );
  }
}
