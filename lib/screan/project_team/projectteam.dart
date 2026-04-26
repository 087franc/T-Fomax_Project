import 'package:flutter/material.dart';

class ProjectTeamPage extends StatefulWidget {
  const ProjectTeamPage({super.key});

  @override
  State<ProjectTeamPage> createState() => _ProjectTeamPageState();
}

class _ProjectTeamPageState extends State<ProjectTeamPage> {
  // 1. DADUS TIM NO PROJETU
  final List<Map<String, dynamic>> _projectTeams = [
    {
      "project_name": "Maintenance Backbone Dili-Tibar",
      "status": "Active",
      "leader": "Marcod de Deus",
      "members": [
        {"name": "Mateus Belo", "role": "Splicer Expert", "status": "Working"},
        {
          "name": "Antonio da Costa",
          "role": "OTDR Technician",
          "status": "Working",
        },
        {"name": "João Silva", "role": "Driver/Helper", "status": "Standby"},
      ],
    },
    {
      "project_name": "Rollout FO Site Baucau Villa",
      "status": "Pending",
      "leader": "Augusto Pires",
      "members": [
        {"name": "Lino de Jesus", "role": "Civil Works", "status": "Off Duty"},
        {
          "name": "Zelia Martins",
          "role": "Admin Support",
          "status": "Off Duty",
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Team no Projetu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFED1C24),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _projectTeams.length,
        itemBuilder: (context, index) {
          final team = _projectTeams[index];
          return _buildTeamCard(team);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewTeam(),
        backgroundColor: const Color(0xFFED1C24),
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    bool isActive = team['status'] == "Active";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isActive ? Colors.red[50] : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['project_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Leader: ${team['leader']}",
                        style: const TextStyle(
                          color: Color(0xFFED1C24),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    team['status'],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black,
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.grey[400],
                ),
              ],
            ),
          ),

          // Lista Membru
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: team['members'].length,
            itemBuilder: (context, i) {
              final member = team['members'][i];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person, size: 20),
                ),
                title: Text(
                  member['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text("${member['role']} • ${member['status']}"),
                trailing: Icon(
                  Icons.circle,
                  size: 12,
                  color: member['status'] == "Working"
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            },
          ),

          const Divider(),
          // Butaun ba Manager
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // TextButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.chat_bubble_outline),
                //   label: const Text("Chat Team"),
                // ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Detail Job"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _createNewTeam() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Formuláriu Tim Foun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            const TextField(
              decoration: InputDecoration(
                labelText: "Naran Projetu/Ganguan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                labelText: "Hili Team Leader",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                labelText: "Membru sira (use comma)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED1C24),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "KRIA TIM",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
