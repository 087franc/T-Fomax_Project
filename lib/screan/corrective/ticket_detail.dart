import 'package:flutter/material.dart';
import 'chat_team.dart';

class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final String myTeamId;
  final VoidCallback onClaim;
  final VoidCallback onFinalize;

  const TicketDetailPage({
    super.key,
    required this.ticket,
    required this.myTeamId,
    required this.onClaim,
    required this.onFinalize,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late Map<String, dynamic> _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
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

  void _showClaimSetupDialog() {
    final TextEditingController teamController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.people_outline, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Resolve Setup"),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Preenxe dadus ekipa no mensajen primeiru hodi claim ticket ne'e:",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: teamController,
                  decoration: const InputDecoration(
                    labelText: "Ekipa / Membru (Team Members)",
                    hintText: "p.e. Ramos, Kokoa",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Favor preenxe naran membru ekipa";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: "Mensajen Foun (Chat Message)",
                    hintText: "p.e. Ami atu ba check fibra...",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.chat),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Favor preenxe mensajen foun";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kansela", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final String teamStr = teamController.text.trim();
                final String msgStr = messageController.text.trim();
                Navigator.pop(context);

                setState(() {
                  _ticket['status'] = "ON PROCESS";
                  _ticket['claimed_by'] = widget.myTeamId;
                  _ticket['team_members'] = teamStr;
                });
                widget.onClaim();

                final ticketId =
                    _ticket['id']?.toString() ??
                    _ticket['data']?['id']?.toString() ??
                    'No ID';
                if (!CorrectiveChatPage.allChats.containsKey(ticketId)) {
                  CorrectiveChatPage.allChats[ticketId] = [];
                }

                CorrectiveChatPage.allChats[ticketId]!.add({
                  "user": "System",
                  "type": "text",
                  "content": "Ekipa servisu: $teamStr",
                  "time": DateTime.now().toString().substring(11, 16),
                });

                CorrectiveChatPage.allChats[ticketId]!.add({
                  "user": "Me",
                  "type": "text",
                  "content": msgStr,
                  "time": DateTime.now().toString().substring(11, 16),
                });

                _navigateToChat();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Submete", style: TextStyle(color: Colors.white)),
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
    String claimedBy = _ticket['claimed_by']?.toString() ?? '';

    bool isOpen = status == "OPEN";
    bool isSOLVED = status == "SOLVED";
    bool isMyTicket = claimedBy == widget.myTeamId;

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
                          status,
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
