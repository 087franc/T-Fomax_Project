import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool obscurePassword = true;
  bool obscurePassword2 = true;
  bool obscurePassword3 = true;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Halo Favor Prense Fill nebe Mamuk!", Colors.orange);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Password foun no konfirmasaun la hanesan!", Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService()
          .patch("/api/v1/users/change-password", {
            "old_password": oldPassword,
            "new_password": newPassword,
            "confirm_password": confirmPassword,
          });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          responseData['message'] ?? "Password troka ho susesu!",
          Colors.green,
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showSnackBar(
          responseData['message'] ??
              responseData['error'] ??
              "Falha atu troka password!",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar("Erro: Labele liga ba Server ($e)", Colors.orange);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      appBar: AppBar(
        title: const Text(
          "Troka Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 100),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Troka Password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Icon(Icons.lock, size: 50, color: Colors.redAccent),
              const SizedBox(height: 50),
              TextField(
                controller: _oldPasswordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password Tuan",
                  hintText: "prense Password Tuan",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _newPasswordController,
                obscureText: obscurePassword2,
                decoration: InputDecoration(
                  labelText: "Password  Foun",
                  hintText: "prense Password Foun",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword2
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword2 = !obscurePassword2;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: obscurePassword3,
                decoration: InputDecoration(
                  labelText: "Konfirma Password Foun",
                  hintText: "prense Password Foun",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword3
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword3 = !obscurePassword3;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton.icon(
                      onPressed: _changePassword,
                      label: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 20),
                      ),
                      icon: const Icon(Icons.change_circle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
