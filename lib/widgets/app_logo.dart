import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF00875A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00875A).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.electric_bolt_rounded,
              color: const Color(0xFFFFC107), // Lightning Amber Color
              size: size * 0.6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.extrabold,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(text: 'Flash', style: TextStyle(color: Color(0xFF00875A))),
              TextSpan(text: '2', style: TextStyle(color: Color(0xFFFFC107))),
              TextSpan(text: 'Mart', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}