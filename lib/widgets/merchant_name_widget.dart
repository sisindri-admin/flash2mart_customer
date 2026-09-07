import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MerchantNameWidget extends StatelessWidget {
  final String merchantId;
  const MerchantNameWidget({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    if (merchantId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('merchants').doc(merchantId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final storeName = data?['storeName'] ?? '';
          if (storeName.isNotEmpty) {
            return Text(
              storeName,
              style: const TextStyle(fontSize: 10, color: Color(0xFF00875A), fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}