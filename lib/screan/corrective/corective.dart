import 'package:flutter/material.dart';
import 'chat_team.dart';

class CorrectivePage extends StatefulWidget {
  const CorrectivePage({super.key});

  @override
  State<CorrectivePage> createState() => _CorrectivePageState();
}

class _CorrectivePageState extends State<CorrectivePage> {
  // SIMULASAUN USER ID (User ne'ebé login hela agora)
  final String myTeamId = "TEAM-FRANS-01";

  static final List<Map<String, dynamic>> _tickets = [
    {
      "id": "TKT-FO-001",
      "title": "Fiber Optic Cut (FO Putus)",
      "status": "OPEN",
      "claimed_by": null, // Seidauk iha na'in
    },
    {
      "id": "TKT-FO-002",
      "title": "Signal Degradation",
      "status": "OPEN",
      "claimed_by": null,
    },
    {
      "id": "TKT-FO-003",
      "title": "Splice Loss",
      "status": "OPEN",
      "claimed_by": null,
    },
    {
      "id": "TKT-FO-004",
      "title": "Connector Issue",
      "status": "OPEN",
      "claimed_by": null,
    },
  ];

  void _handleAction(int index) {
    if (_tickets[index]['status'] == "OPEN") {
      _confirmClaim(index);
    } else if (_tickets[index]['status'] == "ON PROCESS") {
      if (_tickets[index]['claimed_by'] == myTeamId) {
        _navigateToChat(index);
      } else {
        _showAccessDenied();
      }
    }
  }

  void _confirmClaim(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Claim Ticket?"),
        content: const Text(
          "Ita ho ita-nia tim sei foti responsabilidade ba ticket ne'e?",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text("Kansela"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tickets[index]['status'] = "ON PROCESS";
                _tickets[index]['claimed_by'] = myTeamId; // REJISTA NA'IN
              });
              Navigator.pop(context);
              _navigateToChat(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Claim Ticket"),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CorrectiveChatPage(
          ticketId: _tickets[index]['id'],
          onFinalize: () {
            setState(() {
              _tickets[index]['status'] = "SOLVED";
            });
          },
        ),
      ),
    );
  }

  void _showAccessDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failha! Ticket ne'e ema seluk mak claim ona."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Corrective (Gangguan)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          var t = _tickets[index];
          bool isMyTicket = t['claimed_by'] == myTeamId;
          bool isOpen = t['status'] == "OPEN";
          bool isSOLVED = t['status'] == "SOLVED";

          return Card(
            child: ListTile(
              title: Text(
                t['id'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${t['title']}\nStatus: ${t['status']}",
                style: TextStyle(
                  color: isSOLVED
                      ? Colors.grey
                      : (isOpen ? Colors.blue : Colors.orange),
                ),
              ),
              trailing: ElevatedButton(
                // Se SOLVED, butaun mate. Se ema seluk foti, butaun kór seluk.
                onPressed: isSOLVED ? null : () => _handleAction(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen
                      ? Colors.blue
                      : (isMyTicket ? Colors.orange : Colors.grey),
                ),
                child: Text(
                  isOpen ? "CLAIM" : (isMyTicket ? "ENTER CHAT" : "ON PROCESS"),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
