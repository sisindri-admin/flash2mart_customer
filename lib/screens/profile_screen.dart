import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? currentAddress;
  final VoidCallback? onAddressTap;

  const ProfileScreen({
    super.key,
    this.currentAddress,
    this.onAddressTap,
  });

  // Firestore "customers" కలెక్షన్‌లో నిర్దిష్ట ఫీల్డ్‌ని Update/Add చేసే రియూజబుల్ ఫంక్షన్
  Future<void> _updateCustomerField(
    BuildContext context,
    String userId,
    String fieldName,
    String dialogTitle,
    String currentValue,
    TextInputType inputType,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue.contains("No ") ? "" : currentValue,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: "Enter $fieldName",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
            ),
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                try {
                  // Firestore 'customers' collection డాక్యుమెంట్‌కి ఫీల్డ్ యాడ్/అప్‌డేట్ అవుతుంది
                  await FirebaseFirestore.instance
                      .collection('customers')
                      .doc(userId)
                      .set({
                    fieldName: newValue,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$fieldName updated successfully!"),
                        backgroundColor: const Color(0xFF00875A),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // 1. 'customers' కలెక్షన్ నుండి Logged-in User ఐడీతో డేటా ఫెచ్ చేస్తుంది
        future: userId.isNotEmpty
            ? FirebaseFirestore.instance.collection('customers').doc(userId).get()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00875A)),
            );
          }

          Map<String, dynamic>? customerData;
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            customerData = snapshot.data!.data() as Map<String, dynamic>?;
          }

          // 2. మీ 'customers' Firestore structure ప్రకారం ఫీల్డ్స్ అసైన్ చేయడం
          final String name = customerData?['name'] ?? currentUser?.displayName ?? "Flash2Mart User";
          final String email = customerData?['email'] ?? currentUser?.email ?? "No Email Registered";
          final String phone = customerData?['phone'] ?? currentUser?.phoneNumber ?? "No Phone Number";
          final String area = customerData?['area'] ?? "No Area Provided";
          final String dbAddress = currentAddress ?? "Vedayapalem, Nellore";

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00875A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF00875A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Details List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        // Name
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.person_outline, color: Color(0xFF00875A)),
                          ),
                          title: const Text("Full Name"),
                          subtitle: Text(name),
                        ),
                        const Divider(height: 1),

                        // Email
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.email_outlined, color: Color(0xFF00875A)),
                          ),
                          title: const Text("Email Address"),
                          subtitle: Text(email),
                        ),
                        const Divider(height: 1),

                        // Phone Number (Firestore 'phone' Field)
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.phone_outlined, color: Color(0xFF00875A)),
                          ),
                          title: const Text("Phone Number"),
                          subtitle: Text(phone),
                          trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                          onTap: () {
                            if (userId.isNotEmpty) {
                              _updateCustomerField(
                                context,
                                userId,
                                'phone',
                                'Update Phone Number',
                                phone,
                                TextInputType.phone,
                              );
                            }
                          },
                        ),
                        const Divider(height: 1),

                        // Area Field (Firestore 'area' Field)
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.map_outlined, color: Color(0xFF00875A)),
                          ),
                          title: const Text("Area / City"),
                          subtitle: Text(area),
                          trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                          onTap: () {
                            if (userId.isNotEmpty) {
                              _updateCustomerField(
                                context,
                                userId,
                                'area',
                                'Update Area',
                                area,
                                TextInputType.text,
                              );
                            }
                          },
                        ),
                        const Divider(height: 1),

                        // Delivery Address
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.location_on_outlined, color: Color(0xFF00875A)),
                          ),
                          title: const Text("Delivery Address"),
                          subtitle: Text(
                            dbAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            if (onAddressTap != null) {
                              Navigator.pop(context);
                              onAddressTap!();
                            }
                          },
                        ),
                        const Divider(height: 1),

                        // My Orders
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF00875A)),
                          ),
                          title: const Text("My Orders"),
                          subtitle: const Text("Order history & status tracking"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Logout Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFEBEE),
                        child: Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out from Flash2Mart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().handleLogout(context);
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}