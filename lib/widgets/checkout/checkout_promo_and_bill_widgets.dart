import 'package:flutter/material.dart';

class CouponOffer {
  final String code;
  final String title;
  final String description;
  final double minOrderAmount;
  final double flatDiscount;
  final int percentDiscount;
  final double maxDiscount;

  const CouponOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.minOrderAmount,
    this.flatDiscount = 0,
    this.percentDiscount = 0,
    this.maxDiscount = 0,
  });

  double calculateDiscount(double itemTotal) {
    if (itemTotal < minOrderAmount) return 0.0;
    if (flatDiscount > 0) return flatDiscount;
    if (percentDiscount > 0) {
      final double raw = (itemTotal * percentDiscount) / 100.0;
      return maxDiscount > 0 && raw > maxDiscount ? maxDiscount : raw;
    }
    return 0.0;
  }
}

class CheckoutPromoAndBillWidgets {
  static const List<CouponOffer> availableCoupons = [
    CouponOffer(
      code: 'FLASH20',
      title: 'Flat ₹20 OFF',
      description: 'Valid on orders above ₹149',
      minOrderAmount: 149,
      flatDiscount: 20,
    ),
    CouponOffer(
      code: 'SUPER50',
      title: 'Flat ₹50 OFF',
      description: 'Valid on orders above ₹399',
      minOrderAmount: 399,
      flatDiscount: 50,
    ),
    CouponOffer(
      code: 'WELCOME10',
      title: '10% Instant Savings (Up to ₹30)',
      description: 'Valid on all orders above ₹99',
      minOrderAmount: 99,
      percentDiscount: 10,
      maxDiscount: 30,
    ),
  ];
}

class CheckoutFreeDeliveryBanner extends StatelessWidget {
  final double itemTotal;
  static const double threshold = 199.0;

  const CheckoutFreeDeliveryBanner({
    super.key,
    required this.itemTotal,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = (threshold - itemTotal).clamp(0.0, threshold);
    final bool isUnlocked = remaining <= 0;
    final double progress = (itemTotal / threshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUnlocked
                      ? 'FREE Delivery unlocked on your ₹199+ order! (Saved ₹25)'
                      : 'Shop for ₹199 or more to unlock FREE Delivery (Add ₹${remaining.ceil()})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFDCFCE7),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CheckoutCouponSectionCard extends StatelessWidget {
  final double itemTotal;
  final CouponOffer? appliedCoupon;
  final ValueChanged<CouponOffer?> onCouponChanged;

  const CheckoutCouponSectionCard({
    super.key,
    required this.itemTotal,
    required this.appliedCoupon,
    required this.onCouponChanged,
  });

  void _openCouponsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Coupons & Offers',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...CheckoutPromoAndBillWidgets.availableCoupons.map((coupon) {
                final bool isEligible = itemTotal >= coupon.minOrderAmount;
                final double savings = coupon.calculateDiscount(itemTotal);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEligible
                        ? const Color(0xFFF8FAFC)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEligible
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00875A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          coupon.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              isEligible
                                  ? '${coupon.description} • Save ₹${savings.toStringAsFixed(0)}'
                                  : 'Add ₹${(coupon.minOrderAmount - itemTotal).ceil()} more to unlock',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isEligible
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: isEligible
                            ? () {
                                onCouponChanged(coupon);
                                Navigator.pop(ctx);
                              }
                            : null,
                        child: Text(
                          isEligible ? 'APPLY' : 'LOCKED',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isEligible
                                ? const Color(0xFF00875A)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double discount = appliedCoupon != null
        ? appliedCoupon!.calculateDiscount(itemTotal)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: discount > 0
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Color(0xFF00875A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: discount > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appliedCoupon!.code} Applied!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      Text(
                        'You saved ₹${discount.toStringAsFixed(0)} on this order',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Coupon / Promo Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Save up to ₹50 with FLASH20 / SUPER50',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
          ),
          if (discount > 0)
            TextButton(
              onPressed: () => onCouponChanged(null),
              child: const Text(
                'REMOVE',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _openCouponsBottomSheet(context),
              child: const Text(
                'VIEW OFFERS',
                style: TextStyle(
                  color: Color(0xFF00875A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CheckoutInstructionQuickChips extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const CheckoutInstructionQuickChips({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  static const List<String> _presets = [
    'Leave at door',
    'Don\'t ring bell',
    'Call on arrival',
    'Hand it to security',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _presets.map((preset) {
        final bool isSelected = controller.text.contains(preset);
        return InkWell(
          onTap: () {
            if (isSelected) {
              controller.text = controller.text
                  .replaceAll(preset, '')
                  .replaceAll(', ,', ',')
                  .trim();
            } else {
              controller.text = controller.text.trim().isEmpty
                  ? preset
                  : '${controller.text.trim()}, $preset';
            }
            onChanged();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00875A)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              preset,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF00875A)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
