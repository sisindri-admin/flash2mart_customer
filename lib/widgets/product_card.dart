import 'dart:convert';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String unit;
  final String imageUrl;
  final int quantityInCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.quantityInCart,
    required this.onAdd,
    required this.onRemove,
  });

  Widget _buildProductImage(String imageStr) {
    if (imageStr.isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.green.shade200);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.green.shade200),
        );
      } catch (e) {
        return Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.green.shade200);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.green.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area with Soft Background
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildProductImage(imageUrl),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Product Name
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          
          // Unit / Weight
          Text(
            unit,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          // Price and ADD Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${price.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              quantityInCart == 0
                  ? SizedBox(
                      height: 34,
                      width: 70,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A).withOpacity(0.1),
                          foregroundColor: const Color(0xFF00875A),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF00875A), width: 1.5),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onAdd,
                        child: const Text(
                          'ADD',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00875A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26),
                            icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                            onPressed: onRemove,
                          ),
                          Text(
                            '$quantityInCart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            onPressed: onAdd,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}