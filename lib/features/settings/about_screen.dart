import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../l10n/generated/app_l10n.dart';
import '../legal/legal_document.dart';

/// Pantalla «Acerca de»: versión, autor, contacto, redes y documentos legales.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _email = 'neryadg@gmail.com';
  static const List<(String, String, String)> _social = <(String, String, String)>[
    ('X / Twitter', 'NeryadG', 'https://x.com/NeryadG'),
    ('Instagram', 'neryad_dev', 'https://www.instagram.com/neryad_dev'),
    ('GitHub', 'neryad', 'https://github.com/neryad'),
  ];

  Future<void> _copy(BuildContext context, String text) async {
    final l10n = L10n.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedSnackbar)),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value) => ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: AppSpacing.rowMinHeight,
        title: Text(label),
        subtitle: Text(value),
        trailing: IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: L10n.of(context).copyLabel,
          onPressed: () => _copy(context, value),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.aboutLabel)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.listBottom,
        ),
        children: <Widget>[
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.vpn_key_rounded, size: 48, color: color.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Llavero',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            l10n.aboutTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => Text(
                snapshot.hasData
                    ? l10n.aboutVersion(
                        snapshot.data!.version, snapshot.data!.buildNumber)
                    : '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aboutParagraph, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(l10n.aboutSecurityCard),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.exportImport),
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(l10n.aboutBackupAction),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aboutMadeBy, style: Theme.of(context).textTheme.titleMedium),
          Text(l10n.aboutCopyright, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.aboutContact, style: Theme.of(context).textTheme.titleMedium),
          _copyRow(context, _email, _email),
          for (final item in _social) ...[
            _copyRow(context, '${item.$1} · ${item.$2}', item.$3),
          ],
          const Divider(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSpacing.rowMinHeight,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.legalPrivacyTitle),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.legal,
              arguments: LegalDocumentKind.privacy,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSpacing.rowMinHeight,
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.legalTermsTitle),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.legal,
              arguments: LegalDocumentKind.terms,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSpacing.rowMinHeight,
            leading: const Icon(Icons.code_outlined),
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}
