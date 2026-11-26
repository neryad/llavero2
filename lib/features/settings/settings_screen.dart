import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/platform/device_integrity.dart';
import '../../core/platform/screen_security.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_l10n.dart';

/// Ajustes reales de la app: tema, idioma, seguridad y bloqueo.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DeviceIntegrity _integrity = DeviceIntegrity.intact;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ScreenSecurity.setScreenshotsBlocked(
      AppScope.of(context).settings.blockScreenshots,
    );
    DeviceIntegrityChecker.check().then((result) {
      if (!mounted) return;
      setState(() => _integrity = result);
    });
  }

  void _setScreenshots(bool value) {
    final settings = AppScope.of(context).settings;
    setState(() => settings.setBlockScreenshots(value));
    ScreenSecurity.setScreenshotsBlocked(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final settings = controllers.settings;
    final lock = controllers.lock;
    // Solo se puede guardar la copia de la DEK si está desenvolta.
    final canToggleBiometrics = !lock.isLocked && lock.unlockedDek != null;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.settingsLabel)),
      body: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
          children: <Widget>[
            // --- Estado de seguridad ---
            Text(
              l10n.securityStatusLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: Text(
                lock.hasPin ? l10n.vaultCreatedStatus : l10n.noVaultStatus,
              ),
            ),
            ListTile(
              leading: Icon(
                _integrity.isCompromised
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_outlined,
                color: _integrity.isCompromised
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              title: Text(
                _integrity.isCompromised
                    ? l10n.compromisedDeviceWarning
                    : l10n.deviceOkStatus,
              ),
              subtitle: Text(l10n.deviceIntegrityLabel),
            ),
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: Text(l10n.changePinLabel),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePin),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: Text(
                lock.biometricsEnabled
                    ? l10n.biometricsStatusOn
                    : l10n.biometricsStatusOff,
              ),
              subtitle: canToggleBiometrics
                  ? null
                  : Text(l10n.biometricsNeedsUnlock),
              trailing: Switch(
                value: lock.biometricsEnabled,
                onChanged: canToggleBiometrics
                    ? (value) => lock.setBiometricsEnabled(value)
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(
                '${l10n.failedAttemptsLabel}: ${lock.failedAttempts}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.lockNowLabel),
              onTap: () => lock.lock(),
            ),
            const Divider(height: 32),

            // --- Preferencias ---
            Text(
              l10n.themeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SegmentedButton<AppThemeMode>(
              segments: <ButtonSegment<AppThemeMode>>[
                ButtonSegment(value: AppThemeMode.system, label: Text(l10n.themeSystem)),
                ButtonSegment(value: AppThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: AppThemeMode.dark, label: Text(l10n.themeDark)),
              ],
              selected: <AppThemeMode>{settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SegmentedButton<AppLanguage>(
              segments: <ButtonSegment<AppLanguage>>[
                ButtonSegment(value: AppLanguage.system, label: Text(l10n.languageSystem)),
                ButtonSegment(value: AppLanguage.spanish, label: Text(l10n.languageSpanish)),
                ButtonSegment(value: AppLanguage.english, label: Text(l10n.languageEnglish)),
              ],
              selected: <AppLanguage>{settings.language},
              onSelectionChanged: (s) => settings.setLanguage(s.first),
            ),
            const Divider(height: 32),

            ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: Text(l10n.autoLockSettingLabel),
              trailing: DropdownButton<AutoLockDelay>(
                value: settings.autoLockDelay,
                items: <MapEntry<AutoLockDelay, String>>[
                  MapEntry(AutoLockDelay.immediately, l10n.autoLockImmediately),
                  MapEntry(AutoLockDelay.thirtySeconds, l10n.autoLock30Seconds),
                  MapEntry(AutoLockDelay.oneMinute, l10n.autoLock1Minute),
                  MapEntry(AutoLockDelay.fiveMinutes, l10n.autoLock5Minutes),
                ].map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ).toList(),
                onChanged: (value) {
                  if (value != null) settings.setAutoLockDelay(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(l10n.pinLengthSettingLabel),
              trailing: DropdownButton<int>(
                value: settings.pinLength,
                items: <int>[4, 5, 6, 7, 8]
                    .map(
                      (n) => DropdownMenuItem<int>(value: n, child: Text('$n')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) settings.setPinLength(value);
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.screenshot_outlined),
              title: Text(l10n.blockScreenshotsSettingLabel),
              subtitle: Platform.isIOS ? Text(l10n.screenshotsIosNote) : null,
              value: settings.blockScreenshots,
              onChanged: _setScreenshots,
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_off_outlined),
              title: Text(
                '${l10n.clipboardTimeoutSettingLabel}: '
                '${settings.clipboardTimeoutSeconds}s',
              ),
            ),
            const Divider(height: 32),

            ListTile(
              leading: const Icon(Icons.import_export),
              title: Text(l10n.exportImportTitle),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.exportImport),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
