import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_tracking_model.dart';

class OrderStatusStepperCard extends StatelessWidget {
  final OrderTrackingModel model;
  final VoidCallback? onCancelTap;

  const OrderStatusStepperCard({
    super.key,
    required this.model,
    this.onCancelTap,
  });

  static const List<_StepMeta> _steps = [
    _StepMeta(label: 'Placed', icon: Icons.receipt_long_rounded),
    _StepMeta(label: 'Preparing', icon: Icons.soup_kitchen_rounded),
    _StepMeta(label: 'Packed', icon: Icons.inventory_2_rounded),
    _StepMeta(label: 'On Way', icon: Icons.delivery_dining_rounded),
    _StepMeta(label: 'Delivered', icon: Icons.verified_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = model.isCancelled;
    final bool isDelivered = model.isDelivered;

    final Color primaryColor = isCancelled
        ? const Color(0xFFDC2626)
        : isDelivered
            ? const Color(0xFF16A34A)
            : const Color(0xFF2563EB);

    final Color cardBgColor = isCancelled
        ? const Color(0xFFFEF2F2)
        : isDelivered
            ? const Color(0xFFF0FDF4)
            : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? const Color(0xFFFECACA)
              : isDelivered
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Cancel Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER #${model.orderId}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              if (model.canCancel && onCancelTap != null)
                TextButton(
                  onPressed: onCancelTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Status Title + Dynamic Bike Arrival Time
          Row(
            children: [
              Expanded(
                child: Text(
                  model.displayStatus,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (!isCancelled && !isDelivered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.two_wheeler_rounded,
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '~${model.estimatedBikeMinutes} Mins',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            model.statusSubtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 5-Step Progress Stepper
          Row(
            children: List.generate(_steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Connecting line
                final int stepBefore = index ~/ 2;
                final bool isPassed = model.currentStepIndex > stepBefore &&
                    !isCancelled;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE2E8F0),
                  ),
                );
              }

              final int stepIndex = index ~/ 2;
              final meta = _steps[stepIndex];
              final bool isCurrent =
                  model.currentStepIndex == stepIndex && !isCancelled;
              final bool isCompleted =
                  model.currentStepIndex > stepIndex && !isCancelled;

              Color circleBg = const Color(0xFFF1F5F9);
              Color iconColor = const Color(0xFF94A3B8);

              if (isCompleted) {
                circleBg = const Color(0xFF16A34A);
                iconColor = Colors.white;
              } else if (isCurrent) {
                circleBg = primaryColor;
                iconColor = Colors.white;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : meta.icon,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent || isCompleted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCurrent || isCompleted
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // 4-Digit Delivery OTP Card (Always prominent for customer)
          if (!isCancelled && !isDelivered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.pin_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delivery OTP',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        model.deliveryOtp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D4ED8),
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: model.deliveryOtp));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Delivery OTP copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepMeta {
  final String label;
  final IconData icon;

  const _StepMeta({required this.label, required this.icon});
}