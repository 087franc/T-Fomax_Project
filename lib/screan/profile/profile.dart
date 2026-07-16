import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'changes_password.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String role = "";
  String scheduleType = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Foti dadus husi LocalStorage
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name') ?? "Utilizador";
      email = prefs.getString('user_email') ?? "email@exemplo.com";
      role = prefs.getString('user_role') ?? "Staff";
      scheduleType = prefs.getString('user_schedule_type') ?? "fixed";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Perfil Utilizador",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header ho Foto Perfil
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: AssetImage(
                        'img/profile.jpg',
                      ), // Foto profile
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Detallu Informasaun
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email, "Email", email),
                  _buildInfoTile(Icons.badge, "Role / Pozisaun", role),
                  _buildInfoTile(
                    Icons.schedule,
                    "Schedule Type",
                    scheduleType,
                  ), // Ezemplu de'it
                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text("Troka Password"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 10)),
                  // // Logout Button
                  // ElevatedButton.icon(
                  //   onPressed: () async {
                  //     final prefs = await SharedPreferences.getInstance();
                  //     final sessionId = prefs.getString('session_id');

                  //     // 1. Delete session on backend
                  //     if (sessionId != null) {
                  //       try {
                  //         await ApiService().delete(
                  //           '/api/v1/user-sessions/$sessionId',
                  //         );
                  //       } catch (e) {
                  //         debugPrint('Error deleting session from backend: $e');
                  //       }
                  //     }

                  //     // 2. Clear local session data
                  //     await prefs.clear();

                  //     // 3. Navigate to LoginPage
                  //     if (!mounted) return;
                  //     Navigator.pushAndRemoveUntil(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const LoginPage(),
                  //       ),
                  //       (route) => false,
                  //     );
                  //   },
                  //   icon: const Icon(Icons.logout, color: Colors.white),
                  //   label: const Text("Termina Sesaun"),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.redAccent,
                  //     foregroundColor: Colors.white,
                  //     minimumSize: const Size(double.infinity, 50),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
