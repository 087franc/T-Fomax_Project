import 'package:flutter/material.dart';
// import 'login_page.dart'; // Importa failu login ne'ebé ita kria ona
// import 'otp_page.dart'; // Importa failu otp ne'ebé ita kria ona
import 'home_page.dart';
// import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-Fomax', // Telkomcel Fiber Optic Maintenance Excellence
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),

      home: MainDashboardPage(),

      routes: {'': (context) => MainDashboardPage()},
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: const Center(
        child: Text(
          "Benvindu! Ita tama ona ho seguru.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
