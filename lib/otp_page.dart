import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Aumenta ida ne'e
import 'home_page.dart';

class OTPPage extends StatefulWidget {
  final String email;
  const OTPPage({super.key, required this.email});

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController otpCtrl = TextEditingController();
  bool _isVerifying = false;

  Future<void> verifyOTP() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek se backend haruka duni session_id
      final String? sessionId = prefs.getString('session_id');
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session ID la hetan, favor login fali"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse("http://172.20.222.144:3000/api/v1/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"session_id": sessionId, "otp": otpCtrl.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['message'] == "OTP verified successfully") {
        // 2. NAVEGA BA DASHBOARD NO HAMOOS HISTORIA BACK

        await prefs.setString('session_id', data['session_id']);
        if (data['session_token'] != null) {
          await prefs.setString('session_token', data['session_token']);
        }
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('user_id', data['user']['id'].toString());
        }
        await prefs.setString(
          'user_name',
          data['user']['name'],
        ); // Dadus husi backend
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString(
          'user_schedule_type',
          data['user']['schedule_type'],
        ); // hora diresaun

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboardPage()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "OTP Sala"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro: Labele liga ba server"),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 221, 219, 215),
      appBar: AppBar(
        title: const Text(
          "Verifika OTP",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Di'ak liu uza scroll atu keyboard la taka input
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                Text(
                  "User: ${widget.email}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Hatama kódigu OTP ne'ebé haruka ona",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: "000000",
                    hintStyle: TextStyle(color: Colors.grey, letterSpacing: 0),
                  ),
                ),
                const SizedBox(height: 30),
                _isVerifying
                    ? const CircularProgressIndicator(color: Colors.redAccent)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: verifyOTP,
                          child: const Text("VERIFIKA AGORA"),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
