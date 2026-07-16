import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();

    // Check both session_token and session_id as fallback
    final String? token = prefs.getString('session_token');
    final String? sessionId = prefs.getString('session_id');
    final int? loginTimestamp = prefs.getInt('login_timestamp');

    debugPrint("--- Session Debug ---");
    debugPrint("Session Token: ${token != null ? 'OK' : 'MISSING'}");
    debugPrint("Session ID: ${sessionId != null ? 'OK' : 'MISSING'}");
    debugPrint(
      "Timestamp: ${loginTimestamp != null ? 'OK ($loginTimestamp)' : 'MISSING'}",
    );

    bool isLoggedIn = false;

    // We need at least a token (or session_id) AND the timestamp to calculate the 3 days
    if ((token != null && token.isNotEmpty) && loginTimestamp != null) {
      final DateTime loginDate = DateTime.fromMillisecondsSinceEpoch(
        loginTimestamp,
      );
      final DateTime now = DateTime.now();

      // Calculate difference in hours for more precision, or stick to days
      final int differenceInDays = now.difference(loginDate).inDays;

      debugPrint("Age of session: $differenceInDays days");

      if (differenceInDays < 3) {
        isLoggedIn = true;
        debugPrint("Status: Active");
      } else {
        debugPrint("Status: Expired (> 3 days). Clearing storage...");
        await prefs.clear();
      }
    } else {
      debugPrint("Status: Invalid (Missing data)");
    }

    // Delay to show the splash/loading screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLoggedIn) {
      debugPrint("Result: Staying Logged In -> Home");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDashboardPage()),
      );
    } else {
      debugPrint("Result: Redirecting -> Login");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 20),
            Text("Verifika Sesaun...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
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
