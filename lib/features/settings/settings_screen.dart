import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/platform/screen_security.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/reauth_dialog.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_l10n.dart';

/// Ajustes agrupados: Seguridad, Herramientas, Apariencia y Acerca de.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ScreenSecurity.setScreenshotsBlocked(
      AppScope.of(context).settings.blockScreenshots,
    );
  }

  void _setScreenshots(bool value) {
    final settings = AppScope.of(context).settings;
    setState(() => settings.setBlockScreenshots(value));
    ScreenSecurity.setScreenshotsBlocked(value);
  }

  Future<void> _setPinLength(int value) async {
    // Cambiar la longitud afecta al PIN: hay que confirmar identidad primero.
    if (!await requireReauth(context)) return;
    if (mounted) AppScope.of(context).settings.setPinLength(value);
  }

  Widget _group(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 24),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controllers = AppScope.of(context);
    final settings = controllers.settings;
    final lock = controllers.lock;
    final capabilities = PlatformCapabilities.detect();
    final canToggleBiometrics = capabilities.supportsBiometrics &&
        !lock.isLocked &&
        lock.unlockedDek != null;

    final pinLength = (settings.pinLength == 4 || settings.pinLength == 8)
        ? settings.pinLength
        : 6;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.settingsLabel)),
      body: ListenableBuilder(
        listenable: lock,
        builder: (context, _) => ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              _group(l10n.securityLabel, <Widget>[
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: Text(l10n.changePinLabel),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.changePin),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: Text(l10n.biometricSettingLabel),
                  subtitle: !capabilities.supportsBiometrics
                      ? Text(l10n.biometricsNotSupported)
                      : (canToggleBiometrics
                          ? null
                          : Text(l10n.biometricsNeedsUnlock)),
                  trailing: Switch(
                    value: lock.biometricsEnabled,
                    onChanged: canToggleBiometrics
                        ? (value) async {
                            if (!value && !await requireReauth(context)) {
                              return;
                            }
                            await lock.setBiometricsEnabled(
                              value,
                              reauthenticated: !value,
                            );
                          }
                        : null,
                  ),
                ),
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
                SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    for (final n in <int>[4, 6, 8])
                      ButtonSegment<int>(value: n, label: Text('$n')),
                  ],
                  selected: <int>{pinLength},
                  onSelectionChanged: (s) => _setPinLength(s.first),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.screenshot_outlined),
                  title: Text(l10n.blockScreenshotsSettingLabel),
                  subtitle: !capabilities.supportsScreenshotBlocking
                      ? Text(l10n.screenshotsNotSupported)
                      : (Platform.isIOS ? Text(l10n.screenshotsIosNote) : null),
                  value: settings.blockScreenshots &&
                      capabilities.supportsScreenshotBlocking,
                  onChanged: capabilities.supportsScreenshotBlocking
                      ? _setScreenshots
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.content_paste_off_outlined),
                  title: Text(
                    '${l10n.clipboardTimeoutSettingLabel}: '
                    '${settings.clipboardTimeoutSeconds}s',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.lockNowLabel),
                  onTap: () => lock.lock(),
                ),
              ]),
              _group(l10n.toolsLabel, <Widget>[
                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: Text(l10n.securityHealthLabel),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.securityHealth),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.categoriesLabel),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.categories),
                ),
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(l10n.exportImportTitle),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.exportImport),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(l10n.trashLabel),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.trash),
                ),
              ]),
              _group(l10n.appearanceLabel, <Widget>[
                Text(
                  l10n.themeLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SegmentedButton<AppThemeMode>(
                  segments: <ButtonSegment<AppThemeMode>>[
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: <AppThemeMode>{settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.languageLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SegmentedButton<AppLanguage>(
                  segments: <ButtonSegment<AppLanguage>>[
                    ButtonSegment(
                      value: AppLanguage.system,
                      label: Text(l10n.languageSystem),
                    ),
                    ButtonSegment(
                      value: AppLanguage.spanish,
                      label: Text(l10n.languageSpanish),
                    ),
                    ButtonSegment(
                      value: AppLanguage.english,
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: <AppLanguage>{settings.language},
                  onSelectionChanged: (s) => settings.setLanguage(s.first),
                ),
              ]),
              _group(l10n.aboutLabel, <Widget>[
                Text(l10n.aboutText),
              ]),
              if (capabilities.isWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.webStorageWarning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
