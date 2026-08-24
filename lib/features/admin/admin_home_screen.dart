import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/backup_service.dart';
import '../elder/widgets.dart';
import 'admin_editors.dart';

/// Admin Mode home — a menu for the family. Ordinary dense Material UI is fine
/// here (this screen is not for the elder). Every section is fully data-driven:
/// edits write to SQLite and Elder Mode refreshes immediately.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const _backup = BackupService();

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

    Widget actionTile(
        IconData icon, String title, String subtitle, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Backup & Transfer',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          actionTile(Icons.upload_file, 'Export data to a file',
              'Save everything you set up (with photos) to one file',
              () => _export(context)),
          actionTile(Icons.download, 'Import data from a file',
              'Load a backup onto this tablet — replaces current data',
              () => _import(context)),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Changes are saved on this tablet and take effect immediately. '
              'Use Export to move your setup to another tablet, and Import to '
              'load it there.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- export ----
  Future<void> _export(BuildContext context) async {
    final scope = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _backup.exportBytes(scope.config);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Home Talk backup',
        fileName: _backup.suggestedFileName(scope.config),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (path == null) return; // user cancelled

      // On desktop the picker returns the chosen path but doesn't write the
      // bytes itself — make sure the file actually ends up on disk.
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
      messenger.showSnackBar(
          SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // --------------------------------------------------------------- import ----
  Future<void> _import(BuildContext context) async {
    final scope = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a Home Talk backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true, // load bytes directly, cross-platform
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return; // cancelled or unreadable

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
            'Importing will replace everything on this tablet — rooms, '
            'objects, routines and photos — with the contents of the file. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _backup.importBytes(bytes, scope.store);
      await scope.reload();
      messenger.showSnackBar(const SnackBar(
          content: Text('Import complete. Your data has been replaced.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}
