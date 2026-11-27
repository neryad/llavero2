import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/adaptive_segmented.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/platform/screen_security.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/reauth_dialog.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_l10n.dart';
import '../legal/legal_document.dart';

/// Ajustes agrupados: Seguridad, Herramientas, Apariencia y Acerca de.
///
/// Todas las filas comparten la misma columna de icono (contentPadding cero),
/// el mismo estilo de etiqueta (titleMedium) y la misma separación. Los
/// controles anchos van debajo de la etiqueta, alineados con ella.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Icono, etiqueta y valor alineados igual en toda la pantalla.
  static const double _labelIndent = 56;

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

  TextStyle get _labelStyle => Theme.of(context).textTheme.titleMedium!;

  Widget _row({
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: AppSpacing.rowMinHeight,
      leading: Icon(icon),
      title: Text(label, style: _labelStyle),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Fila con un control ancho (segmentado) debajo, alineado con la etiqueta.
  Widget _controlRow({
    required IconData icon,
    required String label,
    required Widget control,
    bool indent = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _row(icon: icon, label: label),
        Padding(
          padding: EdgeInsets.only(
            left: indent ? _labelIndent : 0,
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: control,
        ),
      ],
    );
  }

  Widget _group(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.headerToItem),
          for (final child in children) ...[
            child,
            const SizedBox(height: AppSpacing.cardGap),
          ],
          const SizedBox(height: AppSpacing.groupGap),
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

    final clipboardTimeouts = <int>{
      15,
      30,
      60,
      120,
      settings.clipboardTimeoutSeconds,
    }.toList()
      ..sort();

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
                _row(
                  icon: Icons.password_outlined,
                  label: l10n.changePinLabel,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.changePin),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: AppSpacing.rowMinHeight,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l10n.biometricSettingLabel, style: _labelStyle),
                      subtitle: !capabilities.supportsBiometrics
                          ? Text(l10n.biometricsNotSupported)
                          : (canToggleBiometrics
                              ? null
                              : Text(l10n.biometricsNeedsUnlock)),
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
                    Padding(
                      padding: const EdgeInsets.only(left: _labelIndent),
                      child: Text(
                        l10n.biometricHelper,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                _row(
                  icon: Icons.lock_clock_outlined,
                  label: l10n.autoLockSettingLabel,
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppSpacing.rowMinHeight,
                  secondary: const Icon(Icons.screenshot_outlined),
                  title: Text(
                    l10n.blockScreenshotsSettingLabel,
                    style: _labelStyle,
                  ),
                  subtitle: !capabilities.supportsScreenshotBlocking
                      ? Text(l10n.screenshotsNotSupported)
                      : (Platform.isIOS ? Text(l10n.screenshotsIosNote) : null),
                  value: settings.blockScreenshots &&
                      capabilities.supportsScreenshotBlocking,
                  onChanged: capabilities.supportsScreenshotBlocking
                      ? _setScreenshots
                      : null,
                ),
                _row(
                  icon: Icons.content_paste_off_outlined,
                  label: l10n.clipboardTimeoutSettingLabel,
                  trailing: DropdownButton<int>(
                    value: settings.clipboardTimeoutSeconds,
                    items: <DropdownMenuItem<int>>[
                      for (final seconds in clipboardTimeouts)
                        DropdownMenuItem<int>(
                          value: seconds,
                          child: Text('${seconds}s'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setClipboardTimeoutSeconds(value);
                      }
                    },
                  ),
                ),
                _row(
                  icon: Icons.lock_outline,
                  label: l10n.lockNowLabel,
                  onTap: () => lock.lock(),
                ),
              ]),
              _group(l10n.toolsLabel, <Widget>[
                _row(
                  icon: Icons.health_and_safety_outlined,
                  label: l10n.securityHealthLabel,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.securityHealth),
                ),
                _row(
                  icon: Icons.category_outlined,
                  label: l10n.categoriesLabel,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.categories),
                ),
                _row(
                  icon: Icons.import_export,
                  label: l10n.exportImportTitle,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.exportImport),
                ),
                _row(
                  icon: Icons.delete_sweep_outlined,
                  label: l10n.trashLabel,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.trash),
                ),
              ]),
              _group(l10n.appearanceLabel, <Widget>[
                _controlRow(
                  icon: Icons.palette_outlined,
                  label: l10n.themeLabel,
                  indent: false,
                  control: AdaptiveSegmented<AppThemeMode>(
                    values: AppThemeMode.values,
                    labels: <String>[
                      l10n.themeSystem,
                      l10n.themeLight,
                      l10n.themeDark,
                    ],
                    selected: settings.themeMode,
                    onChanged: settings.setThemeMode,
                  ),
                ),
                _controlRow(
                  icon: Icons.language_outlined,
                  label: l10n.languageLabel,
                  indent: false,
                  control: AdaptiveSegmented<AppLanguage>(
                    values: AppLanguage.values,
                    labels: <String>[
                      l10n.languageSystem,
                      l10n.languageSpanish,
                      l10n.languageEnglish,
                    ],
                    selected: settings.language,
                    onChanged: settings.setLanguage,
                  ),
                ),
              ]),
              _group(l10n.aboutLabel, <Widget>[
                _row(
                  icon: Icons.info_outlined,
                  label: l10n.aboutLabel,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.about),
                ),
                _row(
                  icon: Icons.privacy_tip_outlined,
                  label: l10n.legalPrivacyTitle,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.legal,
                    arguments: LegalDocumentKind.privacy,
                  ),
                ),
                _row(
                  icon: Icons.description_outlined,
                  label: l10n.legalTermsTitle,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.legal,
                    arguments: LegalDocumentKind.terms,
                  ),
                ),
                _row(
                  icon: Icons.code_outlined,
                  label: l10n.openSourceLicenses,
                  onTap: () => showLicensePage(context: context),
                ),
              ]),
              if (capabilities.isWeb)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
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
