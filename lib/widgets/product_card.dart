import 'dart:convert';
import 'package:flutter/material.dart';
import 'merchant_name_widget.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? data['title'] ?? 'Product';
    final double price = (data['price'] ?? 0).toDouble();
    final String imageBase64 = data['imageBase64'] ?? '';
    final String merchantId = data['merchantId'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: imageBase64.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.memory(base64Decode(imageBase64), fit: BoxFit.cover),
                    )
                  : const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MerchantNameWidget(merchantId: merchantId),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00875A),
                        minimumSize: const Size(50, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {},
                      child: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}