import 'dart:convert';
import 'package:flutter/material.dart';
import 'chat_team.dart';
import '/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final String myTeamId;
  final VoidCallback onClaim;
  final VoidCallback onFinalize;
  final String _userId;
  final String _sessionToken;

  const TicketDetailPage({
    super.key,
    required this.ticket,
    required this.myTeamId,
    required this.onClaim,
    required this.onFinalize,
    required String userId,
    required String sessionToken,
  }) : _userId = userId,
       _sessionToken = sessionToken;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late Map<String, dynamic> _ticket;
  String _ticketUserId = "";

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadTicketUserId();
  }

  Future<void> _loadTicketUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _ticketUserId = prefs.getString('ticket_user_id') ?? '';
        });
      }
    } catch (e) {
      print("Error loading ticket user id: $e");
    }
  }

  void _handleClaim() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Claim Ticket?"),
          ],
        ),
        content: const Text(
          "Ita ho ita-nia tim prontu resolve ticket ne'e?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kansela", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showClaimSetupDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // endpoint foti ticket id husi database ticket nian
  Future<void> _showClaimSetupDialog() async {
    final ticketId =
        _ticket['id']?.toString() ??
        _ticket['data']?['id']?.toString() ??
        'No ID';

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';

      dynamic ticketUserId;
      if (email.isNotEmpty) {
        try {
          final userResponse = await ApiService().get(
            "/api/v1/tickets/user-id?email=$email",
          );
          if (userResponse.statusCode == 200) {
            final decoded = jsonDecode(userResponse.body);
            if (decoded is Map) {
              var val = decoded['user_id'] ?? decoded['id'];
              if (val == null && decoded['data'] != null) {
                var data = decoded['data'];
                if (data is Map) {
                  val = data['user_id'] ?? data['id'];
                } else {
                  val = data;
                }
              }
              if (val != null) {
                ticketUserId = int.tryParse(val.toString()) ?? val;
                await prefs.setString(
                  'ticket_user_id',
                  ticketUserId.toString(),
                );
                if (mounted) {
                  setState(() {
                    _ticketUserId = ticketUserId.toString();
                  });
                }
              }
            } else {
              ticketUserId = int.tryParse(decoded.toString()) ?? decoded;
              await prefs.setString('ticket_user_id', ticketUserId.toString());
              if (mounted) {
                setState(() {
                  _ticketUserId = ticketUserId.toString();
                });
              }
            }
          }
        } catch (e) {
          print("Error fetching ticket user id: $e");
        }
      }

      //depois de foti ticket id husi database ticket depois post no assign fali ba database seluk

      //endpoint hodi assign ticket

      final finalUserId =
          ticketUserId ?? int.tryParse(widget._userId) ?? widget._userId;

      final Map<String, dynamic> assignBody = {"assigned_to": finalUserId};

      print("assignBody: $assignBody");

      final assignResponse = await ApiService().post(
        "/api/v1/tickets/$ticketId/assign",
        assignBody,
      );

      print(
        "Assign response: ${assignResponse.statusCode} - ${assignResponse.body}",
      );

      if (assignResponse.statusCode == 200 ||
          assignResponse.statusCode == 201) {
        final Map<String, dynamic> statusBody = {"status": 1};

        print("statusBody: $statusBody");

        //endpoint hodi update status ticket
        // muda status iha fali database seluk ne'e mak id 1

        final statusResponse = await ApiService().patch(
          "/api/v1/tickets/$ticketId/status",
          statusBody,
        );

        print(
          "Status patch response: ${statusResponse.statusCode} - ${statusResponse.body}",
        );

        if (statusResponse.statusCode == 200 ||
            statusResponse.statusCode == 201) {
          setState(() {
            _ticket['status'] = "PROGRESS";
            _ticket['claimed_by'] = widget.myTeamId;
            _ticket['assigned_to'] = finalUserId.toString();
          });

          widget.onClaim();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ticket assigned and status updated successfully"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CorrectiveChatPage(
                ticketId: ticketId,
                onFinalize: () {
                  setState(() {
                    _ticket['status'] = "SOLVED";
                  });
                  widget.onFinalize();
                },
              ),
            ),
          );
        } else {
          String errorMessage =
              "Failed to update status: Status ${statusResponse.statusCode}";

          try {
            final decoded = jsonDecode(statusResponse.body);
            if (decoded is Map && decoded.containsKey('message')) {
              errorMessage = decoded['message'].toString();
            } else if (decoded is Map && decoded.containsKey('error')) {
              errorMessage = decoded['error'].toString();
            } else if (statusResponse.body.isNotEmpty) {
              errorMessage = statusResponse.body;
            }
          } catch (_) {
            if (statusResponse.body.isNotEmpty) {
              errorMessage = statusResponse.body;
            }
          }

          debugPrint("Status error response: ${statusResponse.body}");
          _showSnackBar(errorMessage, Colors.white);
        }
      } else {
        String errorMessage =
            "Failed to claim ticket: Status ${assignResponse.statusCode}";

        try {
          final decoded = jsonDecode(assignResponse.body);
          if (decoded is Map && decoded.containsKey('message')) {
            errorMessage = decoded['message'].toString();
          } else if (decoded is Map && decoded.containsKey('error')) {
            errorMessage = decoded['error'].toString();
          } else if (assignResponse.body.isNotEmpty) {
            errorMessage = assignResponse.body;
          }
        } catch (_) {
          if (assignResponse.body.isNotEmpty) {
            errorMessage = assignResponse.body;
          }
        }

        debugPrint("Assign error response: ${assignResponse.body}");
        _showSnackBar(errorMessage, Colors.white);
      }
    } catch (e) {
      debugPrint("Assign exception: $e");
      _showSnackBar("Error: ${e.toString()}", Colors.white);
    }
  }

  void _showSnackBar(String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Info"),
          ],
        ),
        content: Text(message),
        backgroundColor: color,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ok", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CorrectiveChatPage(
          ticketId:
              _ticket['id']?.toString() ??
              _ticket['data']?['id']?.toString() ??
              'No ID',
          onFinalize: () {
            setState(() {
              _ticket['status'] = "SOLVED";
            });
            widget.onFinalize();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("TICKET DATA ON BUILD: $_ticket");
    var tData = _ticket['data'] is Map ? _ticket['data'] : {};
    String ticketId =
        tData['id']?.toString() ?? _ticket['id']?.toString() ?? 'No ID';
    String trackingNo =
        tData['tracking_no']?.toString() ??
        _ticket['tracking_no']?.toString() ??
        '';
    String corporateName =
        tData['corporate_name']?.toString() ??
        _ticket['corporate_name']?.toString() ??
        '';
    String custId =
        tData['cust_id']?.toString() ?? _ticket['cust_id']?.toString() ?? '';
    String title =
        _ticket['ticket_title']?.toString() ??
        _ticket['title']?.toString() ??
        'No Title';
    String status =
        _ticket['status']?.toString() ??
        _ticket['ticket_status']?.toString() ??
        'OPEN';
    String displayStatus = status;
    if (status == "0" || status.toUpperCase() == "OPEN") {
      displayStatus = "OPEN";
    } else if (status == "1" ||
        status.toUpperCase() == "PROGRESS" ||
        status.toUpperCase() == "ON PROCESS") {
      displayStatus = "PROGRESS";
    } else if (status == "2" || status.toUpperCase() == "CANCELED") {
      displayStatus = "CANCELED";
    } else if (status == "3" || status.toUpperCase() == "ON HOLD") {
      displayStatus = "ON HOLD";
    } else if (status == "4" || status.toUpperCase() == "CLOSED") {
      displayStatus = "CLOSED";
    } else if (status == "5" ||
        status.toUpperCase() == "RESOLVED" ||
        status.toUpperCase() == "SOLVED") {
      displayStatus = "RESOLVED";
    } else if (status == "6" || status.toUpperCase() == "RE OPEN") {
      displayStatus = "RE OPEN";
    }

    String claimedBy =
        tData['claimed_by']?.toString() ??
        _ticket['claimed_by']?.toString() ??
        '';
    String assignedTo =
        tData['assigned_to']?.toString() ??
        _ticket['assigned_to']?.toString() ??
        '';

    bool isOpen = displayStatus == "OPEN";
    bool isSOLVED = displayStatus == "RESOLVED";
    bool isMyTicket =
        claimedBy == widget.myTeamId ||
        (assignedTo.isNotEmpty &&
            (assignedTo == widget._userId || assignedTo == _ticketUserId));

    Color statusColor;
    if (isSOLVED) {
      statusColor = Colors.grey;
    } else if (isOpen) {
      statusColor = Colors.blueAccent;
    } else {
      statusColor = isMyTicket ? Colors.orangeAccent : Colors.redAccent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detail Ticket",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.1),
                    Colors.orangeAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticketId,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Details section
            const Text(
              "Informasaun Detail",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            _buildDetailRow(
              Icons.confirmation_number_outlined,
              "Tracking No",
              trackingNo,
            ),
            _buildDetailRow(
              Icons.business_outlined,
              "Corporate Name",
              corporateName,
            ),
            _buildDetailRow(
              Icons.person_pin_circle_outlined,
              "Customer ID",
              custId,
            ),
            if (claimedBy.isNotEmpty)
              _buildDetailRow(
                Icons.assignment_ind_outlined,
                "Claimed By",
                claimedBy,
              ),

            const SizedBox(height: 40),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 55,
              child: isOpen
                  ? ElevatedButton.icon(
                      onPressed: _handleClaim,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "CLAIM TICKET",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    )
                  : isSOLVED
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.done_all, color: Colors.grey),
                      label: const Text(
                        "TICKET SOLVED",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    )
                  : isMyTicket
                  ? ElevatedButton.icon(
                      onPressed: _navigateToChat,
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ENTER CHAT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline, color: Colors.grey),
                      label: const Text(
                        "CLAIMED BY OTHER TEAM",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
}
