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
            : const Color(0xFFEFF6FF);

    final Color borderColor = isCancelled
        ? const Color(0xFFFECACA)
        : isDelivered
            ? const Color(0xFFBBF7D0)
            : const Color(0xFFBFDBFE);

    final bool showOtpBanner = !isCancelled &&
        !isDelivered &&
        (model.currentStepIndex >= 2 || model.deliveryPartnerId.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        model.storeName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (model.canCancel && onCancelTap != null)
                TextButton.icon(
                  onPressed: onCancelTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text(
                    'Cancel Order',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_rounded
                      : isDelivered
                          ? Icons.check_circle_rounded
                          : Icons.local_shipping_rounded,
                  color: primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT ORDER STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.displayStatus,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.statusSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 16),
            _buildHorizontalStepper(primaryColor),
          ],
          if (showOtpBanner) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Confirmation OTP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Share this 4-digit PIN with partner at doorstep',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: model.deliveryOtp));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery OTP copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        model.deliveryOtp.split('').join(' '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper(Color activeColor) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final int stepBefore = index ~/ 2;
          final bool isCompletedLine = stepBefore < model.currentStepIndex;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isCompletedLine
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        final int stepIdx = index ~/ 2;
        final _StepMeta meta = _steps[stepIdx];
        final bool isDone = stepIdx < model.currentStepIndex || model.isDelivered;
        final bool isCurrent = stepIdx == model.currentStepIndex && !model.isDelivered;

        final Color circleColor = isDone
            ? const Color(0xFF16A34A)
            : isCurrent
                ? activeColor
                : Colors.white;

        final Color iconColor = (isDone || isCurrent) ? Colors.white : const Color(0xFF94A3B8);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF16A34A)
                      : isCurrent
                          ? activeColor
                          : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : meta.icon,
                size: 15,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: (isDone || isCurrent) ? FontWeight.bold : FontWeight.w500,
                color: (isDone || isCurrent)
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StepMeta {
  final String label;
  final IconData icon;

  const _StepMeta({required this.label, required this.icon});
}