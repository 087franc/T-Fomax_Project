// --- DASHBOARD PAGE ---
import 'package:flutter/material.dart';
import 'screan/proactive/proactive.dart';
import 'screan/presensi/presensi.dart';
import 'screan/corrective/corective.dart';
import 'screan/potensi&pengukuran/potensi_pengukuran.dart';
// import 'preventivepage.dart';
import 'screan/alker&sarkel/alker_sarkel.dart';
import 'screan/project_team/projectteam.dart';
import 'screan/preventive/preventivepage.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'profile.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class MainDashboardPage extends StatelessWidget {
  const MainDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Presensa', 'icon': Icons.touch_app, 'color': Colors.red},
      {'title': 'Korektivu', 'icon': Icons.build, 'color': Colors.blue},
      {
        'title': 'Preventivu',
        'icon': Icons.energy_savings_leaf,
        'color': Colors.orange,
      },
      {
        'title': 'Proactivu',
        'icon': Icons.settings_input_component,
        'color': Colors.red,
      },
      {
        'title': 'Potensial no \nMedida',
        'icon': Icons.bolt,
        'color': Colors.green,
      },
      {
        'title': 'Fasilidade no \nEkipamento',
        'icon': Icons.inventory_2,
        'color': Colors.red,
      },
      {'title': 'Ekipa ba Projetu', 'icon': Icons.groups, 'color': Colors.grey},
      {
        'title': 'Tag',
        'icon': Icons.location_on_outlined,
        'color': Colors.blue,
      },
      {'title': 'Download', 'icon': Icons.file_download, 'color': Colors.red},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent, Color.fromARGB(255, 200, 20, 20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "T-FOMAX Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Image.asset(
                  'img/profile.jpg',
                  width: 25,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('img/t-fomax.jpg'),
                  fit: BoxFit.fill,
                ),

                color: Color.fromRGBO(255, 82, 82, 1),
              ),
              child: null,
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Baranda'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Settings seidauk prontu")),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Termina Sesaun'),
              onTap: () {
                //get session_id from shared preferences
                Future<String?> getSessionId() async {
                  final prefs = await SharedPreferences.getInstance();
                  return prefs.getString('session_id');
                }

                Future<void> deleteData() async {
                  final url = Uri.parse(
                    'http://172.20.219.243:3000/api/v1/user-sessions/${await getSessionId()}',
                  );

                  final response = await http.delete(
                    url,
                    headers: {'Content-Type': 'application/json'},
                  );

                  if (response.statusCode == 200 ||
                      response.statusCode == 204) {
                    print('Data berhasil dihapus');
                  } else {
                    print('Gagal hapus data: ${response.statusCode}');
                  }
                }

                deleteData();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          Opacity(
            opacity: 0.15, // Opacity dibuat lebih soft
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('img/t-fomax.jpg'),
                  fit: BoxFit.fill, // Gunakan cover agar tidak distorsi
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: GridView.count(
              clipBehavior: Clip.none, // Agar bayangan tidak terpotong
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.70, // Disesuaikan agar card lebih lega
              children: menuItems.map((item) {
                return InkWell(
                  onTap: () {
                    // Logika navigasi tetap sama seperti kode Anda sebelumnya
                    if (item['title'] == 'Preventivu') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreventivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Proactivu') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TambahProactivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Presensa') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PresensiPage(),
                        ),
                      );
                    } else if (item['title'] == 'Korektivu') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CorrectivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Potensial no \nMedida') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PotensiPengukuranPage(),
                        ),
                      );
                    } else if (item['title'] == 'Fasilidade no \nEkipamento') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlkerSarkerPage(),
                        ),
                      );
                    } else if (item['title'] == 'Ekipa ba Projetu') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProjectTeamPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Menu ${item['title']} seidauk prontu"),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  splashColor: item['color'].withOpacity(0.2),
                  highlightColor: item['color'].withOpacity(0.1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: item['color'].withOpacity(0.25),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'],
                            size: 32,
                            color: item['color'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
