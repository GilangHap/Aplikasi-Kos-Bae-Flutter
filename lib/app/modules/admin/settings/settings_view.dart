// FILE: lib/app/modules/admin/settings/settings_view.dart
import 'package:flutter/material.dart';

/// Admin settings placeholder view
class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.settings, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            'Settings (placeholder)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'TODO: Implement settings interface',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
