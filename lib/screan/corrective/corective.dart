import 'package:flutter/material.dart';
// import 'chat_team.dart';
import 'ticket_detail.dart';
import '/services/api_service.dart';
import 'dart:convert';
// import 'package:http/http.dart' as http;
import '/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CorrectivePage extends StatefulWidget {
  const CorrectivePage({super.key});

  @override
  State<CorrectivePage> createState() => _CorrectivePageState();
}

class _CorrectivePageState extends State<CorrectivePage> {
  // SIMULASAUN USER ID (User ne'ebé login hela agora)
  final String myTeamId = "TEAM-FRANS-01";
  List<dynamic> _ticketList = [];
  bool _isLoading = false;
  String _userId = "";
  String _sessionToken = "";

  // SEARCH FUNCTIONALITY VARIABLES
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userId = prefs.getString('user_id') ?? '';
        _sessionToken = prefs.getString('session_token') ?? '';
      });
    }

    await _fetchticketList();
  }

  Future<void> _fetchticketList() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get("/api/v1/tickets");
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          _ticketList = decoded;
        } else if (decoded is Map) {
          var dataVal = decoded['data'];
          if (dataVal is List) {
            _ticketList = dataVal;
          } else if (dataVal is Map && dataVal.containsKey('data')) {
            var innerData = dataVal['data'];
            if (innerData is List) {
              _ticketList = innerData;
            } else {
              _ticketList = [];
            }
          } else {
            _ticketList = [];
          }
        } else {
          _ticketList = [];
        }
        print("TICKET LIST FROM SERVER: $_ticketList");
      } else {
        _showErrorSnackBar("Erro foti dadus: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
      _showErrorSnackBar(
        "Erro koneksaun: Servidor labele to'o (Network unreachable)",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<dynamic> get _filteredTickets {
    if (_searchQuery.isEmpty) {
      return _ticketList;
    }
    return _ticketList.where((t) {
      var tData = t['data'] is Map ? t['data'] : {};
      String ticketId = (tData['id']?.toString() ?? t['id']?.toString() ?? '')
          .toLowerCase();
      String title = (t['title']?.toString() ?? '').toLowerCase();
      String trackingNo = (tData['tracking_no']?.toString() ?? '')
          .toLowerCase();
      String corporateName = (tData['corporate_name']?.toString() ?? '')
          .toLowerCase();
      String custId = (tData['cust_id']?.toString() ?? '').toLowerCase();
      String status = (t['status']?.toString() ?? '').toLowerCase();

      String query = _searchQuery.toLowerCase();
      return ticketId.contains(query) ||
          title.contains(query) ||
          trackingNo.contains(query) ||
          corporateName.contains(query) ||
          custId.contains(query) ||
          status.contains(query);
    }).toList();
  }

  void _openDetailPage(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailPage(
          ticket: ticket,
          myTeamId: myTeamId,
          userId: _userId,
          sessionToken: _sessionToken,
          onClaim: () {
            setState(() {
              ticket['status'] = "ON PROCESS";
              // ticket['claimed_by'] = myTeamId;
              ticket['assigned_to'] = _userId;
            });
          },
          onFinalize: () {
            setState(() {
              ticket['status'] = "SOLVED";
            });
          },
        ),
      ),
    );
  }

  // String _getStatusColor(String status) {
  //   switch (status.toUpperCase()) {
  //     case 'OPEN':
  //       return 'red'; // Vermelho
  //     case 'ON PROCESS':
  //       return 'orange'; // Laranja
  //     case 'SOLVED':
  //       return 'green'; // Verde
  //     default:
  //       return 'blue'; // Outros (Azul)
  //   }
  // }
  //
  // Future<void> _claimTicket(String ticketId, String teamId) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('http://[IP_ADDRESS]/api/v1/ticket/$ticketId/claim'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'team_id': teamId}),
  //     );

  //     if (response.statusCode == 200) {
  //       setState(() {}); // Refresh UI
  //       print('Ticket claim successful');
  //     } else {
  //       print('Failed to claim ticket: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error claiming ticket: $e');
  //   }
  // }

  // void _navigateToChat(String ticketId, int index) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           CorrectiveChatPage(ticketId: ticketId, onFinalize: () {}),
  //     ),
  //   );
  // }

  // void _handleAction(int index) {
  //   var t = _ticketList[index];
  //   var tData = t['data'] is Map ? t['data'] : {};
  //   String claimedBy =
  //       tData['claimed_by']?.toString() ?? t['claimed_by']?.toString() ?? '';
  //   String assignedTo =
  //       tData['assigned_to']?.toString() ?? t['assigned_to']?.toString() ?? '';
  //   bool isMyTicket =
  //       claimedBy == myTeamId ||
  //       (assignedTo.isNotEmpty && assignedTo == _userId);

  //   String statusRaw = t['status']?.toString() ?? '';
  //   String displayStatus = statusRaw;
  //   if (statusRaw == "0" || statusRaw.toUpperCase() == "OPEN") {
  //     displayStatus = "OPEN";
  //   } else if (statusRaw == "1" ||
  //       statusRaw.toUpperCase() == "PROGRESS" ||
  //       statusRaw.toUpperCase() == "ON PROCESS") {
  //     displayStatus = "PROGRESS";
  //   }

  //   if (displayStatus == "OPEN") {
  //     _confirmClaim(index);
  //   } else if (displayStatus == "PROGRESS") {
  //     if (isMyTicket) {
  //       _navigateToChat(
  //         index,
  //         tData['id']?.toString() ?? t['id']?.toString() ?? '',
  //       );
  //     } else {
  //       _showAccessDenied();
  //     }
  //   }
  // }

  // void _confirmClaim(int index) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Claim Ticket?"),
  //       content: const Text(
  //         "Ita ho ita-nia tim sei foti responsabilidade ba ticket ne'e?",
  //       ),
  //       actions: [
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
  //           child: const Text("Kansela"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             setState(() {
  //               _ticketList[index]['status'] = "ON PROCESS";
  //               _ticketList[index]['claimed_by'] = myTeamId; // REJISTA NA'IN
  //             });
  //             Navigator.pop(context);
  //             _navigateToChat(index, _ticketList[index]['id']);
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  //           child: const Text("Claim Ticket"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _navigateToChat(int index, String ticketId) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => CorrectiveChatPage(
  //         ticketId: ticketId,
  //         onFinalize: () {
  //           setState(() {
  //             _ticketList[index]['status'] = "SOLVED";
  //           });
  //         },
  //       ),
  //     ),
  //   );
  // }

  // void _showAccessDenied() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text("Failha! Ticket ne'e ema seluk mak claim ona."),
  //       backgroundColor: Colors.red,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final tickets = _filteredTickets;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Procura ticket...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text("Korektivu", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = "";
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainDashboardPage(),
                  ),
                ),
              ),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: tickets.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 300,
                        child: Center(child: Text("Seidauk iha dadus ticket")),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        var t = tickets[index];
                        bool isMyTicket = t['claimed_by'] == myTeamId;

                        String statusRaw = t['status']?.toString() ?? '';
                        String displayStatus = statusRaw;
                        if (statusRaw == "0" ||
                            statusRaw.toUpperCase() == "OPEN") {
                          displayStatus = "OPEN";
                        } else if (statusRaw == "1" ||
                            statusRaw.toUpperCase() == "PROGRESS" ||
                            statusRaw.toUpperCase() == "ON PROCESS") {
                          displayStatus = "PROGRESS";
                        } else if (statusRaw == "2" ||
                            statusRaw.toUpperCase() == "CANCELED") {
                          displayStatus = "CANCELED";
                        } else if (statusRaw == "3" ||
                            statusRaw.toUpperCase() == "ON HOLD") {
                          displayStatus = "ON HOLD";
                        } else if (statusRaw == "4" ||
                            statusRaw.toUpperCase() == "CLOSED") {
                          displayStatus = "CLOSED";
                        } else if (statusRaw == "5" ||
                            statusRaw.toUpperCase() == "RESOLVED" ||
                            statusRaw.toUpperCase() == "SOLVED") {
                          displayStatus = "RESOLVED";
                        } else if (statusRaw == "6" ||
                            statusRaw.toUpperCase() == "RE OPEN") {
                          displayStatus = "RE OPEN";
                        }

                        bool isOpen = displayStatus == "OPEN";
                        bool isSOLVED = displayStatus == "RESOLVED";

                        var tData = t['data'] is Map ? t['data'] : {};
                        String ticketId =
                            tData['id']?.toString() ??
                            t['id']?.toString() ??
                            'No ID';
                        String trackingNo =
                            tData['tracking_no']?.toString() ?? '';
                        String corporateName =
                            tData['corporate_name']?.toString() ?? '';
                        String custId = tData['cust_id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _openDetailPage(t),
                            title: Text(
                              ticketId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${t['title'] ?? ''}\nStatus: $displayStatus",
                                  style: TextStyle(
                                    color: isSOLVED
                                        ? Colors.grey
                                        : (isOpen
                                              ? Colors.blue
                                              : Colors.orange),
                                  ),
                                ),
                                if (trackingNo.isNotEmpty)
                                  Text(
                                    "Tracking No: $trackingNo",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (corporateName.isNotEmpty)
                                  Text(
                                    "Corporate: $corporateName",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (custId.isNotEmpty)
                                  Text(
                                    "Cust ID: $custId",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _openDetailPage(t),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                "Detail Ticket",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
