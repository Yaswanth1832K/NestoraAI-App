import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class MessageSettingsPage extends StatefulWidget {
  const MessageSettingsPage({super.key});

  @override
  State<MessageSettingsPage> createState() => _MessageSettingsPageState();
}

class _MessageSettingsPageState extends State<MessageSettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Message Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            "Email Notifications",
            "Receive updates and messages via email",
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val),
          ),
          const Divider(),
          _buildSwitchTile(
            "Push Notifications",
            "Receive push notifications on this device",
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
          ),
          const Divider(),
          _buildSwitchTile(
            "SMS Notifications",
            "Receive text messages for urgent alerts",
            _smsNotifications,
            (val) => setState(() => _smsNotifications = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
