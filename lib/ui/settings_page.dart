import 'package:flutter/material.dart';
import 'user_storage.dart';
import 'currency_exchange_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _pushNotifications;
  bool _locationServices = true;

  @override
  void initState() {
    super.initState();
    _pushNotifications = SessionData.areNotificationsEnabled();
  }

  void _showInfoDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'The content of this page is not strict and can be edited by the buyer of the app. '
          'You can provide your specific information, contact details, or legal terms here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUnavailableDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Sorry, this feature is currently unavailable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = SessionData.getSelectedCurrency();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive trip departure reminders'),
            value: _pushNotifications,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
                SessionData.setNotificationsEnabled(value);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Reminders enabled' : 'Reminders disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          SwitchListTile(
            title: const Text('Location Services'),
            value: _locationServices,
            onChanged: (bool value) {
              setState(() {
                _locationServices = value;
              });
            },
            secondary: const Icon(Icons.location_on_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUnavailableDialog('Language'),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency & Exchange'),
            subtitle: Text('Active: $currentCurrency (Tap to change)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencyExchangePage(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInfoDialog('Help & Support'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInfoDialog('Privacy Policy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInfoDialog('Terms of Service'),
          ),
        ],
      ),
    );
  }
}
