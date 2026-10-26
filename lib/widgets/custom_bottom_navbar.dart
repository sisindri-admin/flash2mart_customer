import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPillNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isHome: true,
              ),
              _buildPillNavItem(
                index: 1,
                label: 'Categories',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
              ),
              _buildPillNavItem(
                index: 2,
                label: 'Buy Again',
                icon: Icons.shopping_basket_outlined,
                activeIcon: Icons.shopping_basket_rounded,
              ),
              _buildPillNavItem(
                index: 3,
                label: 'Offers',
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool isHome = false,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEEEEE) : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 25,
                color: isSelected
                    ? const Color(0xFFE11D48) // Red active icon from Image 2
                    : const Color(0xFF52525B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF09090B)
                      : const Color(0xFF27272A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}