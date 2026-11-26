import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/category_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_l10n.dart';

/// Pantalla principal (temporal en la fase 1).
///
/// Por ahora muestra el estado de la fase 1 y dos ajustes muy visibles
/// (tema e idioma) para poder probarlos en el móvil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final settings = AppScope.of(context).settings;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.homeLabel)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.phase1Title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.phase1Message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              _ThemePicker(settings: settings),
              const SizedBox(height: 16),
              _LanguagePicker(settings: settings),
              const SizedBox(height: 24),
              _CategoryPalettePreview(),
            ],
          );
        },
      ),
    );
  }
}

/// Selector de tema (sistema / claro / oscuro).
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.themeLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: <ButtonSegment<AppThemeMode>>[
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.system,
              label: Text(l10n.themeSystem),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.light,
              label: Text(l10n.themeLight),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.dark,
              label: Text(l10n.themeDark),
            ),
          ],
          selected: <AppThemeMode>{settings.themeMode},
          onSelectionChanged: (selection) {
            settings.setThemeMode(selection.first);
          },
        ),
      ],
    );
  }
}

/// Selector de idioma (sistema / español / inglés).
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.languageLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<AppLanguage>(
          segments: <ButtonSegment<AppLanguage>>[
            ButtonSegment<AppLanguage>(
              value: AppLanguage.system,
              label: Text(l10n.languageSystem),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.spanish,
              label: Text(l10n.languageSpanish),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.english,
              label: Text(l10n.languageEnglish),
            ),
          ],
          selected: <AppLanguage>{settings.language},
          onSelectionChanged: (selection) {
            settings.setLanguage(selection.first);
          },
        ),
      ],
    );
  }
}

/// Muestra los colores de las categorías leídos del tema.
class _CategoryPalettePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = Theme.of(context).extension<CategoryColors>();
    if (categories == null) return const SizedBox.shrink();

    const ids = <String>[
      CategoryIds.wifi,
      CategoryIds.email,
      CategoryIds.streaming,
      CategoryIds.banking,
      CategoryIds.pinCode,
      CategoryIds.social,
      CategoryIds.devices,
      CategoryIds.documents,
      CategoryIds.other,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in ids)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categories.colorOf(id),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}
