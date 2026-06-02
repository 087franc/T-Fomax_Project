import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProjectTeamPage extends StatefulWidget {
  const ProjectTeamPage({super.key});

  @override
  State<ProjectTeamPage> createState() => _ProjectTeamPageState();
}

class _ProjectTeamPageState extends State<ProjectTeamPage> {
  int _selectedIndex = 0;
  List<dynamic> _apiList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    await _fetchCombinedList();
  }

  Future<void> _fetchCombinedList() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().get("/api/v1/groups/list");

      debugPrint("--- API Debug (Team) ---");
      debugPrint("Endpoint: /api/v1/proactive/list");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          _apiList = data;
        } else if (data is Map && data.containsKey('data')) {
          _apiList = data['data'] ?? [];
        } else {
          _apiList = [];
        }
        debugPrint("Items Loaded: ${_apiList.length}");
      } else {
        debugPrint("Error: API returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 1. DADUS TIM NO PROJETU
  final List<Map<String, dynamic>> _projectTeams = [
    {
      "naran_projetu": "Manutensaun Backbone Dili-Tibar",
      "status": "Aktivu",
      "lider": "Marcos de Deus",
      "servisu": [
        {
          "naran": "Splicing Fibra Ótika",
          "data": "2026-05-01",
          "status": "Finalizado",
        },
        {
          "naran": "Teste OTDR Segmentu A",
          "data": "2026-05-02",
          "status": "Finalizado",
        },
        {
          "naran": "Tensaun Kabel nian",
          "data": "2026-05-04",
          "status": "In Progress",
        },
      ],
      "membru": [
        {
          "naran": "Mateus Belo",
          "servisu": "Espertu Splise Fibra Ótika",
          "status": "Servisu hela",
          "id": "EMP-7701",
          "no_telefone": "+670 7712 3456",
          "email": "mateus.belo@telkomcel.tl",
          "address": "Bairro Pite, Dili",
          "foto": "https://i.pravatar.cc/150?u=mateus",
        },
        {
          "naran": "Antonio da Costa",
          "servisu": "Tékniku OTDR",
          "status": "Servisu hela",
          "id": "EMP-7705",
          "no_telefone": "+670 7821 9988",
          "email": "antonio.costa@telkomcel.tl",
          "address": "Comoro, Dili",
          "foto": "https://i.pravatar.cc/150?u=antonio",
        },
        {
          "naran": "João Silva",
          "servisu": "Kondutór/Ajuda-na'in",
          "status": "Hein",
          "id": "EMP-7712",
          "no_telefone": "+670 7543 2110",
          "email": "joao.silva@telkomcel.tl",
          "address": "Becora, Dili",
          "foto": "https://i.pravatar.cc/150?u=joao",
        },
      ],
    },
    {
      "naran_projetu": "Rollout Fatin FO Baucau Villa",
      "status": "Pendente",
      "lider": "Augusto Pires",
      "servisu": [
        {"naran": "Survey Site", "data": "2026-04-28", "status": "Kompleta"},
        {
          "naran": "Aprova Permision",
          "data": "2026-04-30",
          "status": "Kompleta",
        },
      ],
      "membru": [
        {
          "naran": "Lino de Jesus",
          "servisu": "Obra Sivil sira",
          "status": "La iha servisu",
          "id": "EMP-8802",
          "no_telefone": "+670 7733 4455",
          "email": "lino.jesus@telkomcel.tl",
          "address": "Baucau Villa",
          "foto": "https://i.pravatar.cc/150?u=lino",
        },
        {
          "naran": "Zelia Martins",
          "servisu": "Suporta Admin",
          "status": "La iha servisu",
          "id": "EMP-8844",
          "no_telefone": "+670 7766 5544",
          "email": "zelia.martins@telkomcel.tl",
          "address": "Vila Verde, Dili",
          "foto": "https://i.pravatar.cc/150?u=zelia",
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<dynamic> combinedList = [..._apiList];

    if (_isLoading && combinedList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (combinedList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchCombinedList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(child: Text("Seidauk iha dadus team")),
          ),
        ),
      );
    }

    Widget _buildTeamView(List<dynamic> combinedList) {
      return ListView.builder(
        key: const ValueKey("TeamView"),
        padding: const EdgeInsets.all(20),
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final team = combinedList[index];
          return _buildTeamCard(team);
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Detail Projetu" : "Ekipa Detail",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFFED1C24),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex == 0
            ? _buildProjectView()
            : _buildTeamView(combinedList),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewTeam(),
        backgroundColor: const Color(0xFFED1C24),
        elevation: 4,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFFED1C24),
              unselectedItemColor: Colors.grey[400],
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_rounded),
                  activeIcon: Icon(Icons.assignment_rounded, size: 28),
                  label: "Project",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_rounded),
                  activeIcon: Icon(Icons.groups_rounded, size: 28),
                  label: "Team",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectView() {
    return ListView.builder(
      key: const ValueKey("ProjectView"),
      padding: const EdgeInsets.all(20),
      itemCount: _projectTeams.length,
      itemBuilder: (context, index) {
        final project = _projectTeams[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    bool isAktivu = project['status'] == "Aktivu";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAktivu
                    ? [const Color(0xFFED1C24), Colors.red[700]!]
                    : [Colors.grey[700]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
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
                        "PROJETU",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project['naran_projetu'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin,
                        color: Color(0xFFED1C24),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "HEANDLE BY",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          project['lider'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showJobDetails(project),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED1C24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Detail Project Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    // 1. Resolve Group Name (supports API 'group_name' or local 'naran_projetu')
    final String groupName =
        team["group_name"] ?? team["naran_projetu"] ?? "Ekipa Foun";

    // 2. Resolve Member List (supports API 'group_members' or local 'membru')
    final List rawList = team["group_members"] ?? team["membru"] ?? [];
    final List membruList = List.from(rawList);
    membruList.sort((a, b) {
      final aRole = (a['role'] ?? a['position'] ?? a['servisu'] ?? '').toString().toLowerCase();
      final bRole = (b['role'] ?? b['position'] ?? b['servisu'] ?? '').toString().toLowerCase();
      final aChief = aRole.contains('chief');
      final bChief = bRole.contains('chief');
      if (aChief && !bChief) return -1;
      if (!aChief && bChief) return 1;
      return 0;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.groups_rounded, color: Color(0xFFED1C24)),
        ),
        title: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          "Team Leader • ${membruList.length} Membru",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        iconColor: const Color(0xFFED1C24),
        collapsedIconColor: Colors.grey,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        children: [
          const Divider(height: 1, indent: 20, endIndent: 20),
          ...membruList.map<Widget>((member) {
            // Resolve member fields (supports API 'name'/'position' or local 'naran'/'servisu')
            final String memberName =
                member['name'] ?? member['naran'] ?? "Unknown";
            final String memberPos =
                member['position'] ?? member['servisu'] ?? "Staff";

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 5,
              ),
              onTap: () => _showMemberDetails(member),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFED1C24).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                ),
              ),
              title: Text(
                memberName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFED1C24),
                  decoration: TextDecoration.underline,
                ),
              ),
              subtitle: Text(memberPos),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            );
          }).toList(),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    // Resolve fields for details
    final String memberName = member['name'] ?? member['naran'] ?? "Unknown";
    final String memberPos = member['position'] ?? member['servisu'] ?? "Staff";
    final String memberEmail = member['email'] ?? "N/A";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 30),
                Hero(
                  tag: member['id_user'] ?? member['id'] ?? memberName,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFED1C24).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      child: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  memberPos,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoRow(
                  Icons.badge_outlined,
                  "Nº Empregu",
                  (member['id_user'] ?? member['id'] ?? "N/A").toString(),
                ),
                _buildInfoRow(
                  Icons.phone_outlined,
                  "Telefone",
                  member['no_telefone'] ?? "N/A",
                ),
                _buildInfoRow(Icons.email_outlined, "Email", memberEmail),
                _buildInfoRow(
                  Icons.schedule_outlined,
                  "Schedule",
                  member['schedule_type'] ?? "N/A",
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED1C24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Taka Detalle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        team['naran_projetu'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: team['status'] == "Aktivu"
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        team['status'],
                        style: TextStyle(
                          color: team['status'] == "Aktivu"
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin,
                      color: Color(0xFFED1C24),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Lider: ${team['lider']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  "Servisu Realizada",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                if (team['servisu'] != null)
                  ...team['servisu'].map<Widget>(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s['status'] == "Finalizado"
                                ? Colors.green[100]
                                : Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            s['status'] == "Finalizado"
                                ? Icons.check_rounded
                                : Icons.history_rounded,
                            color: s['status'] == "Finalizado"
                                ? Colors.green[700]
                                : Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          s['naran'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Data: ${s['data']}"),
                        trailing: Text(
                          s['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: s['status'] == "Finalizado"
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                const Text(
                  "Team Members",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...() {
                  final List rawMembru = team['membru'] ?? [];
                  final List sortedMembru = List.from(rawMembru);
                  sortedMembru.sort((a, b) {
                    final aRole = (a['role'] ?? a['position'] ?? a['servisu'] ?? '').toString().toLowerCase();
                    final bRole = (b['role'] ?? b['position'] ?? b['servisu'] ?? '').toString().toLowerCase();
                    final aChief = aRole.contains('chief');
                    final bChief = bRole.contains('chief');
                    if (aChief && !bChief) return -1;
                    if (!aChief && bChief) return 1;
                    return 0;
                  });
                  return sortedMembru;
                }().map<Widget>(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['naran'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                m['servisu'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED1C24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFED1C24), size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          left: 30,
          right: 30,
          top: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Formuláriu Tim Foun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 25),
            _buildTextField("Naran Projetu/Ganguan", Icons.assignment_outlined),
            const SizedBox(height: 15),
            _buildTextField("Hili Team Leader", Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField("Membru sira (use comma)", Icons.people_outline),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED1C24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "KRIA TIM",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFED1C24)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
