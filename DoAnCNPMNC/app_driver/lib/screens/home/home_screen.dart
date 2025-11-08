import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.dashboard),
      ),
      body: const Center(
        child: Text('Home Dashboard - TODO'),
      ),
    );
  }
}
