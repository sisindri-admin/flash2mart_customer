import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final String deliveryOtp;
  final double lat;
  final double lng;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.deliveryOtp,
    required this.lat,
    required this.lng,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _circleCtrl;
  late final AnimationController _tickCtrl;
  late final AnimationController _pulseCtrl;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _circleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _tickCtrl.forward();
    });

    // Auto-redirect to the active order tracking screen after 2.4 seconds
    _redirectTimer = Timer(const Duration(milliseconds: 4200), _goToTracking);
  }

  void _goToTracking() {
    _redirectTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => OrderTrackingScreen(orderId: widget.orderId),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _circleCtrl.dispose();
    _tickCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A), // Deep Midnight Slate
              Color(0xFF064E3B), // Rich Emerald Dark
              Color(0xFF047857), // Premium Emerald Teal
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Center Animated Pulsing Rings + Drawn Right Tick Mark
                AnimatedBuilder(
                  animation: Listenable.merge([_circleCtrl, _tickCtrl, _pulseCtrl]),
                  builder: (context, _) {
                    final double scale = Curves.elasticOut.transform(_circleCtrl.value);
                    final double pulse = 1.0 + (_pulseCtrl.value * 0.14);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer soft glow ring
                        Transform.scale(
                          scale: scale * pulse,
                          child: Container(
                            width: 158,
                            height: 158,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withAlpha(35),
                            ),
                          ),
                        ),
                        // Middle ring
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withAlpha(65),
                            ),
                          ),
                        ),
                        // Inner bright circle + animated tick painter
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 98,
                            height: 98,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3.2),
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x6610B981),
                                  blurRadius: 24,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _AnimatedTickPainter(_tickCtrl.value),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                FadeTransition(
                  opacity: _circleCtrl,
                  child: Column(
                    children: [
                      const Text(
                        'Order Placed Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order #${widget.orderId}',
                        style: const TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // OTP & 15 Mins Delivery Badge Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(45)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.key_rounded, color: Color(0xFFFDE68A), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery OTP: ${widget.deliveryOtp}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Color(0xFF34D399), size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'Flash2Mart • 15 Mins Doorstep Delivery',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Redirecting indicator + instant Track Now button
                Column(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Opening your live active order...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _goToTracking,
                      child: const Text(
                        'TRACK NOW >',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTickPainter extends CustomPainter {
  final double progress;
  _AnimatedTickPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.27, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    final double firstSegLen = (p2 - p1).distance;
    final double secondSegLen = (p3 - p2).distance;
    final double totalLen = firstSegLen + secondSegLen;
    final double drawLen = totalLen * progress.clamp(0.0, 1.0);

    if (drawLen <= firstSegLen) {
      final t = drawLen / math.max(firstSegLen, 1.0);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (drawLen - firstSegLen) / math.max(secondSegLen, 1.0);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedTickPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
