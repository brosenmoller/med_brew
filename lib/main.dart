import 'package:flutter/material.dart';

void main() {
  runApp(const MedBrew());
}

class MedBrew extends StatelessWidget {
  const MedBrew({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Brew',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Med Brew")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text("Start Review"),
        ),
      ),
    );
  }
}
