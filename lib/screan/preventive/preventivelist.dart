import 'package:flutter/material.dart';
import 'dart:convert';

class PreventiveListPage extends StatelessWidget {
  const PreventiveListPage({super.key});

  final String jsonRaw = '''
  [
    {
      "wo": "WO-PRE-196AB5C0889",
      "date": "08 May 2025 06:27:37",
      "route": "KEFAMENANU - TSEL ATAMBUA",
      "desc": "Lanjutkan gerakan peduli infra, perbaikan core",
      "category": "Normalisasi Fisik",
      "status": "CLOSED"
    },
    {
      "wo": "WO-PRE-1969BD2E7F5",
      "date": "05 May 2025 06:03:32",
      "route": "KEFAMENANU - TSEL ATAMBUA",
      "desc": "Lanjutkan gerakan peduli infra",
      "category": "Patroli",
      "status": "OPEN"
    },
    {
      "wo": "WO-PRE-1967D152502",
      "date": "29 Apr 2025 06:47:39",
      "route": "ATAMBUA - BETUN",
      "desc": "Lanjutkan gerakan peduli infra",
      "category": "Patroli",
      "status": "CLOSED"
    },
    {
      "wo": "WO-PRE-1967E452599",
      "date": "29 Apr 2025 06:54:39",
      "route": "Keva",
      "desc": "Lanjutkan gerakan peduli infra",
      "category": "Patroli",
      "status": "OPEN"
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    // Muda dadus JSON ba Lista
    final List<dynamic> tickets = json.decode(jsonRaw);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Lista Ticket Preventivu",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(255, 82, 82, 1),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final t = tickets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t['wo'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        t['date'],
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t['route'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t['desc'],
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t['category'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        t['status'],
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
