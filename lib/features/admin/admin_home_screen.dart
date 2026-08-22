import 'package:flutter/material.dart';

import '../elder/widgets.dart';
import 'admin_editors.dart';

/// Admin Mode home — a menu for the family. Ordinary dense Material UI is fine
/// here (this screen is not for the elder). Every section is fully data-driven:
/// edits write to SQLite and Elder Mode refreshes immediately.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context).config;

    Widget tile(IconData icon, String title, String subtitle, Widget target) {
      return ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => target)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Family Setup')),
      body: ListView(
        children: [
          tile(Icons.home, 'Household',
              '${config.householdName} • ${config.elderLang} → ${config.caregiverLang}',
              const HouseholdSettingsScreen()),
          const Divider(height: 1),
          tile(Icons.meeting_room, 'Rooms / Situations',
              '${config.situations.length} rooms', const SituationsListScreen()),
          tile(Icons.category, 'Objects', '${config.objects.length} objects',
              const ObjectsListScreen()),
          tile(Icons.touch_app, 'Actions', '${config.actions.length} actions',
              const ActionsListScreen()),
          tile(Icons.place, 'Destinations',
              '${config.locations.length} destinations',
              const LocationsListScreen()),
          const Divider(height: 1),
          tile(Icons.star, 'Common Requests',
              '${config.commonRequests.length} shortcuts',
              const CommonRequestsListScreen()),
          tile(Icons.list_alt, 'Routines', '${config.routines.length} routines',
              const RoutinesListScreen()),
          tile(Icons.sos, 'Help Requests',
              '${config.helpRequests.length} help items', const HelpListScreen()),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Changes are saved on this tablet and take effect immediately. '
              'Photo capture for objects is coming next.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
