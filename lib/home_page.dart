// --- DASHBOARD PAGE ---
import 'package:flutter/material.dart';
// // import 'dart:convert';xa
// // import 'preventive.dart';
// // import 'screan/form_aumenta_laporan.dart';
import 'screan/proactive.dart';
import 'screan/presensi.dart';
import 'screan/corrective/corective.dart';
import 'screan/potensi_pengukuran.dart';
// import 'preventivepage.dart';
import 'screan/alker_sarkel.dart';
import 'screan/projectteam.dart';
import 'screan/preventive/preventivepage.dart';
import 'login_page.dart';

class MainDashboardPage extends StatelessWidget {
  const MainDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Presensi', 'icon': Icons.touch_app, 'color': Colors.red},
      {'title': 'Corrective', 'icon': Icons.build, 'color': Colors.blue},
      {
        'title': 'Preventive',
        'icon': Icons.energy_savings_leaf,
        'color': Colors.orange,
      },
      {
        'title': 'Proactive',
        'icon': Icons.settings_input_component,
        'color': Colors.red,
      },
      {
        'title': 'Potensi & \nPengukuran',
        'icon': Icons.bolt,
        'color': Colors.green,
      },
      {
        'title': 'Alker & Sarker',
        'icon': Icons.inventory_2,
        'color': Colors.red,
      },
      {'title': 'Project Team', 'icon': Icons.groups, 'color': Colors.grey},
      {
        'title': 'Tagging',
        'icon': Icons.location_on_outlined,
        'color': Colors.blue,
      },
      {'title': 'Download', 'icon': Icons.file_download, 'color': Colors.red},
    ];

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "T-FOMAX Dashboard",
              style: TextStyle(color: Colors.white),
            ),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset(
                'img/T-Fomax.png',
                width: 20,
                height: 30,
                fit: BoxFit.cover,
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
                  image: AssetImage('img/T-Fomax.png'),
                  fit: BoxFit.cover,
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
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
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
            opacity: 0.3,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('img/telkomcel.jpg'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: menuItems.map((item) {
                return InkWell(
                  onTap: () {
                    // Logika navigasi tetap sama seperti kode Anda sebelumnya
                    if (item['title'] == 'Preventive') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreventivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Proactive') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TambahProactivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Presensi') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PresensiPage(),
                        ),
                      );
                    } else if (item['title'] == 'Corrective') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CorrectivePage(),
                        ),
                      );
                    } else if (item['title'] == 'Potensi & \nPengukuran') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PotensiPengukuranPage(),
                        ),
                      );
                    } else if (item['title'] == 'Alker & Sarker') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlkerSarkerPage(),
                        ),
                      );
                    } else if (item['title'] == 'Project Team') {
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
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          // --- VARIASI BORDER DI SINI ---
                          border: Border.all(
                            color: item['color'].withOpacity(
                              0.5,
                            ), // Warna border mengikuti warna icon
                            width: 2, // Ketebalan border
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'],
                          size: 45,
                          color: item['color'],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
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
