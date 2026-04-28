// login_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  // 1. Kria variable hodi kontrola loading
  bool _isLoading = false;

  Future<void> login() async {
    // 2. Ativa loading antes haruka dadus ba Go
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://172.20.222.203:3000/api/v1/auth/request-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text, "password": passCtrl.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['message'] == "OTP generated successfully") {
        // 1. RAI SESSION ID BA LOCAL STORAGE
        final prefs = await SharedPreferences.getInstance();

        // Cek se backend haruka duni session_id
        if (data['session_id'] != null) {
          await prefs.setString('session_id', data['session_id']);
        }

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => OTPPage(email: emailCtrl.text),
          ),
        );
      } else {
        _showSnackBar(data['message'] ?? "Username/Password Sala", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erro: Labele liga ba Server Go", Colors.orange);
    } finally {
      // 3. Desativa loading maski susesu ka failu
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset("img/t-fomax.webp"),
              // const SizedBox(height: 10),
              const Text(
                "Login Page",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Email/Nik",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 25),

              // 4. Kondisaun ba Loading Spinner
              _isLoading
                  ? CircularProgressIndicator() // Hatudu roda dulas
                  : ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.redAccent,
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}


// id,
// location
// deskrisaun kegiatan
// kategory
// status