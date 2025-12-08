// FILE: lib/app/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../models/room_model.dart';

/// Status Badge Widget with color coding
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    Key? key,
    required this.status,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        RoomStatus.getLabel(status),
        style: TextStyle(
          color: colors['text'],
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors(String status) {
    switch (status) {
      case 'kosong':
        return {
          'bg': const Color(0xFFB9F3CC).withOpacity(0.3),
          'text': const Color(0xFF2E7D32),
        };
      case 'terisi':
        return {
          'bg': const Color(0xFFF7C4D4).withOpacity(0.3),
          'text': const Color(0xFFC2185B),
        };
      case 'maintenance':
        return {
          'bg': const Color(0xFFF7F5C6).withOpacity(0.3),
          'text': const Color(0xFFF57C00),
        };
      default:
        return {
          'bg': Colors.grey.shade200,
          'text': Colors.grey.shade700,
        };
    }
  }
}
