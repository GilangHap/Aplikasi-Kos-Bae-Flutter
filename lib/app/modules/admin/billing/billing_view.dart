import 'package:flutter/material.dart';

class AdminBillingView extends StatelessWidget {
  const AdminBillingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            'Billing Management (placeholder)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'TODO: Implement billing interface',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
