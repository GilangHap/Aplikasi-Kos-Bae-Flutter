// FILE: lib/app/widgets/menu_item_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable menu item widget for drawer navigation
/// Shows icon, label, and gradient pill background when selected
class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const MenuItemWidget({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.selectedGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.softGrey,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu item model for drawer
class MenuItem {
  final IconData icon;
  final String label;
  final String route;
  
  const MenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
