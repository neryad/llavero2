import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pide volver a confirmar la identidad antes de una operación sensible.
///
/// Acepta PIN (siempre disponible) o biometría como alternativa.
Future<bool> requireReauth(BuildContext context) async {
  final l10n = L10n.of(context);
  final controllers = AppScope.of(context);
  final pinController = TextEditingController();
  var error = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.reauthTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.reauthPinLabel),
            ),
            if (error)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.reauthFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (controllers.lock.biometricsEnabled)
              TextButton.icon(
                onPressed: () async {
                  final good = await controllers.lock.authenticateBiometric();
                  if (!context.mounted) return;
                  if (good) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() => error = true);
                  }
                },
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.reauthBiometricLabel),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              final good = await controllers.lock.verifyPin(pinController.text);
              if (!context.mounted) return;
              if (good) {
                Navigator.of(context).pop(true);
              } else {
                setState(() => error = true);
              }
            },
            child: Text(l10n.okLabel),
          ),
        ],
      ),
    ),
  );
  pinController.dispose();
  return ok ?? false;
}
