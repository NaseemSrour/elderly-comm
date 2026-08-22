import 'package:flutter/material.dart';

import '../../core/models/models.dart';

/// Shared building blocks for Admin Mode forms. Admin UI is for the family, so
/// ordinary compact Material widgets are appropriate here (unlike Elder Mode).

/// One text field per household language, for editing a [LocalizedText].
class LocalizedField extends StatelessWidget {
  final String label;
  final List<Language> languages;
  final Map<String, TextEditingController> controllers;

  const LocalizedField({
    super.key,
    required this.label,
    required this.languages,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        for (final lang in languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controllers[lang.code],
              textDirection:
                  lang.rtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: lang.label,
              ),
            ),
          ),
      ],
    );
  }
}

/// Utility for building/reading localized controllers.
class LocalizedControllers {
  final Map<String, TextEditingController> map;

  LocalizedControllers(List<Language> languages, LocalizedText initial)
      : map = {
          for (final l in languages)
            l.code: TextEditingController(text: initial[l.code] ?? ''),
        };

  LocalizedText collect() => {
        for (final e in map.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  void dispose() {
    for (final c in map.values) {
      c.dispose();
    }
  }
}

/// A single-line field for an emoji (or short symbol). Photo capture is a
/// future enhancement; the [CommunicationObject.imagePath] slot is already
/// reserved for it.
class EmojiField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const EmojiField({super.key, required this.controller, this.label = 'Icon / emoji'});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: label,
        hintText: '🥣',
      ),
    );
  }
}

/// Confirm-before-delete dialog (destructive actions get a confirmation).
Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete')),
      ],
    ),
  );
  return ok ?? false;
}

/// Standard scaffold for an admin form with a Save action.
class AdminFormScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  const AdminFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('SAVE',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        // Leave room so the last field isn't hidden behind the Save bar.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: children,
      ),
      // A big, unmistakable Save button pinned to the bottom of every form.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 60,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

/// A reusable "manage a list of entities" screen: shows rows with edit + delete
/// and a floating Add button.
class AdminListScaffold<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final String Function(T) emojiOf;
  final void Function(T) onEdit;
  final Future<void> Function(T) onDelete;
  final VoidCallback onAdd;

  const AdminListScaffold({
    super.key,
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    required this.emojiOf,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Nothing here yet. Tap Add.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  leading: Text(emojiOf(item),
                      style: const TextStyle(fontSize: 28)),
                  title: Text(titleOf(item)),
                  subtitle: Text(subtitleOf(item)),
                  onTap: () => onEdit(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(item),
                  ),
                );
              },
            ),
    );
  }
}
