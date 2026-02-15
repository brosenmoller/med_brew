import 'package:flutter/material.dart';
import 'package:med_brew/screens/home_screen.dart';

void main() {
  runApp(const MedBrew());
}

class MedBrew extends StatelessWidget {
  const MedBrew({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Med Brew",
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}