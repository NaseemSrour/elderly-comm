import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import 'admin_home_screen.dart';

/// The deliberate barrier between Elder Mode and Admin Mode. Reached only via a
/// hidden long-press on the home header, then a press-and-HOLD confirm — a
/// confused elder won't hold a button for 2 seconds, but a family member will.
/// No password required (the elder need not understand one).
class AdminGate {
  static Future<void> open(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _HoldToEnterDialog(),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }
  }
}

class _HoldToEnterDialog extends StatefulWidget {
  const _HoldToEnterDialog();

  @override
  State<_HoldToEnterDialog> createState() => _HoldToEnterDialogState();
}

class _HoldToEnterDialogState extends State<_HoldToEnterDialog> {
  static const _hold = Duration(seconds: 2);
  Timer? _timer;
  double _progress = 0;

  void _start() {
    const tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (t) {
      setState(() =>
          _progress += tick.inMilliseconds / _hold.inMilliseconds);
      if (_progress >= 1) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _progress = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Family setup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Press and hold to enter.',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _start(),
            onTapUp: (_) => _stop(),
            onTapCancel: _stop,
            child: Container(
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.help,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _progress > 0 ? 'Keep holding…' : 'Hold',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.border,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
