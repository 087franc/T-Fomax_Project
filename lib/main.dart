import 'package:flutter/material.dart';
// import 'login_page.dart'; // Importa failu login ne'ebé ita kria ona
// import 'otp_page.dart'; // Importa failu otp ne'ebé ita kria ona
// import 'home_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: const SessionCheck(),
    );
  }
}

class SessionCheck extends StatefulWidget {
  const SessionCheck({super.key});

  @override
  State<SessionCheck> createState() => _SessionCheckState();
}

class _SessionCheckState extends State<SessionCheck> {
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');
    return token != null && token.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    bool isLoggedIn = await _isLoggedIn();
    await Future.delayed(const Duration(seconds: 2));
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDashboardPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          );
        }
        if (snapshot.data == true) {
          return const MainDashboardPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Dashboard")),
//       body: const Center(
//         child: Text(
//           "Benvindu! Ita tama ona ho seguru.",
//           style: TextStyle(fontSize: 20),
//         ),
//       ),
//     );
//   }
// }
