import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _capturedFile;
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;

  String _selectedQueryCategory = 'Order Related Issue';
  final List<String> _queryCategories = [
    'Order Related Issue',
    'Payment & Refund Problem',
    'Wrong or Damaged Product',
    'Delivery Delay',
    'App Bug / Technical Issue',
    'Other Query',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // కేవలం Live Camera మాత్రమే ఓపెన్ అవుతుంది (Gallery Allow చేయబడదు)
  Future<void> _captureLiveImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, // ONLY LIVE CAMERA
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear, // వెనుక కెమెరా ఓపెన్ అవుతుంది
      );

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            _capturedFile = photo;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _capturedFile = photo;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('కెమెరా ఓపెన్ చేయడంలో లోపం: $e')),
        );
      }
    }
  }

  Future<void> _submitSupportQuery() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి మీ సమస్యను వివరించండి.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String imagePath = '';
      if (_capturedFile != null) {
        imagePath = _capturedFile!.path;
      }

      await FirebaseFirestore.instance.collection('support_queries').add({
        'category': _selectedQueryCategory,
        'message': messageText,
        'imagePath': imagePath,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('మీ సమస్య సక్సెస్ ఫుల్‌గా సబ్మిట్ చేయబడింది!'),
            backgroundColor: Color(0xFF00875A),
          ),
        );
        _messageController.clear();
        setState(() {
          _capturedFile = null;
          _webImageBytes = null;
          _selectedQueryCategory = _queryCategories.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('సబ్‌మిట్ చేయడంలో విఫలమైంది: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri launchUri = Uri.parse("https://wa.me/91$phone?text=Hello%20Flash2Mart%20Support");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Flash2Mart Support Query',
    );
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    const String supportPhone = "9281048287";
    const String supportEmail = "support@flash2mart.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.support_agent, size: 40, color: Color(0xFF00875A)),
                  SizedBox(height: 6),
                  Text(
                    "How can we help you?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Available 7 days a week (6:00 AM - 10:00 PM)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Contact Options
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_in_talk,
                    title: "Call Us",
                    color: Colors.blue,
                    onTap: () => _makePhoneCall(supportPhone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat_bubble_outline,
                    title: "WhatsApp",
                    color: Colors.green,
                    onTap: () => _openWhatsApp(supportPhone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_outlined,
                    title: "Email",
                    color: Colors.orange,
                    onTap: () => _sendEmail(supportEmail),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Raise a Support Ticket Form
            const Text(
              "Raise a Support Ticket",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Query Category", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedQueryCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _queryCategories.map((String cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedQueryCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text("Describe your Issue", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),

                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Type details about your problem...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF00875A)),
                        onPressed: _captureLiveImage, // Direct Live Camera Only
                        tooltip: 'Take Live Photo of Issue',
                      ),
                    ),
                  ),

                  // Live Photo Capture Instructions / Preview
                  const SizedBox(height: 8),
                  const Text(
                    "* Note: Only live camera photos are accepted.",
                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
                  ),

                  if (_capturedFile != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? (_webImageBytes != null
                                  ? Image.memory(_webImageBytes!, width: 70, height: 70, fit: BoxFit.cover)
                                  : Container(width: 70, height: 70, color: Colors.grey.shade300))
                              : Image.file(File(_capturedFile!.path), width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Live Photo Captured", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              TextButton.icon(
                                icon: const Icon(Icons.refresh, color: Color(0xFF00875A), size: 16),
                                label: const Text("Retake Photo", style: TextStyle(color: Color(0xFF00875A), fontSize: 12)),
                                onPressed: _captureLiveImage,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00875A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : _submitSupportQuery,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT TICKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ticket Status Tracker
            const Text(
              "My Support Tickets & Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            _buildTicketsStatusStream(),

            const SizedBox(height: 24),

            // FAQs Section
            const Text(
              "Frequently Asked Questions (FAQs)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: const [
                  ExpansionTile(
                    leading: Icon(Icons.local_shipping_outlined, color: Color(0xFF00875A)),
                    title: Text("How do I track my order?"),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Track your order in real-time under 'My Orders'.", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                  Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(Icons.currency_rupee_outlined, color: Color(0xFF00875A)),
                    title: Text("What are the payment options?"),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("We accept UPI, Cards, Net Banking, and COD.", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsStatusStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_queries')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("No tickets raised yet.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final category = data['category'] ?? 'Query';
            final message = data['message'] ?? '';
            final status = data['status'] ?? 'Pending';

            Color statusColor = Colors.orange;
            if (status == 'Resolved') statusColor = Colors.green;
            if (status == 'In Progress') statusColor = Colors.blue;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}